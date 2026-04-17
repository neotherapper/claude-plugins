Feature: Consumer migration — paidagogos, namesmith, draftloom adopt visual-kit

  Background:
    Given visual-kit v1.0.0 is published in the marketplace tagged visual-kit--v1.0.0
    And the consumer plugin declares a dependency {"name": "visual-kit", "version": "~1.0.0"} in plugin.json

  # ── paidagogos migration ────────────────────────────────────────────────

  Scenario: paidagogos no longer ships its own server
    When I inspect plugins/paidagogos after migration
    Then the directory plugins/paidagogos/server/ does not exist
    And plugin.json lists visual-kit as a dependency
    And plugins/paidagogos/skills/paidagogos-micro/SKILL.md references /visual-kit lifecycle commands

  Scenario: paidagogos:micro writes a lesson SurfaceSpec to .paidagogos/content
    When /paidagogos is invoked for "CSS Flexbox"
    And paidagogos:micro completes lesson generation
    Then a lesson.json (or <slug>.json) appears in /work/demo/.paidagogos/content/
    And its content conforms to the lesson SurfaceSpec v1 schema
    And the visual-kit server detects the write and serves the page at /p/paidagogos/lesson

  Scenario: paidagogos quiz interactions flow through visual-kit events
    Given a lesson is rendered at /p/paidagogos/lesson
    When the user selects a quiz answer in the browser
    Then a vk-event is emitted by <vk-quiz>
    And POST /events with a valid CSRF token appends a JSON line to /work/demo/.paidagogos/state/events
    And the event payload includes lesson_topic, question_index, selected_answer, result

  Scenario: paidagogos pre-flight fails cleanly when visual-kit is not running
    Given visual-kit is not running for /work/demo
    When /paidagogos is invoked
    Then paidagogos:micro reads .visual-kit/server/state/server-info and sees it is absent
    And the skill prints: "visual-kit is not running. Run `visual-kit serve --project-dir .` to start it."
    And no lesson SurfaceSpec is written

  # ── namesmith migration ─────────────────────────────────────────────────

  Scenario: namesmith gains a gallery surface for Wave 1 candidates
    Given site-naming has completed a Wave 1 generation with 30 candidates
    When the skill writes /work/demo/.namesmith/content/wave-1.json as a gallery SurfaceSpec
    Then GET /p/namesmith/wave-1 returns 200
    And the rendered page contains a <vk-gallery data-multiselect="true">
    And each <vk-card> displays the name, rationale, status, and price from the SurfaceSpec

  Scenario: User selects candidates; namesmith reads events to build shortlist
    Given the gallery at /p/namesmith/wave-1 is rendered
    When the user clicks 5 <vk-card> elements (multiselect)
    Then 5 JSON lines of type "select" are appended to /work/demo/.namesmith/state/events
    And when the user types "continue" in the terminal, the skill reads those events
    And the skill writes a final names.md that includes only the 5 selected candidates
    And names.md remains the durable output artifact

  Scenario: namesmith continues to work without visual-kit (opt-in)
    Given visual-kit is installed as a dependency
    But the user has not run "visual-kit serve"
    When the namesmith skill runs
    Then the skill detects the absent server
    And continues in terminal-only mode, producing names.md without a gallery
    And the terminal output informs the user that the gallery view is available by starting visual-kit

  # ── draftloom migration ─────────────────────────────────────────────────

  Scenario: draftloom offers two structure variants via a comparison surface
    Given the orchestrator has generated two candidate outlines ("story-led" and "argument-led")
    When the orchestrator writes /work/demo/.draftloom/content/structure.json as a comparison SurfaceSpec
    Then GET /p/draftloom/structure returns 200
    And the rendered page contains a <vk-comparison> with two variant panels
    And each panel renders a nested <vk-outline>

  Scenario: User picks a variant; orchestrator proceeds with the chosen outline
    Given the comparison is rendered at /p/draftloom/structure
    When the user clicks the "argument-led" variant
    Then a vk-event {type: "variant-chosen", label: "argument-led"} is appended to .draftloom/state/events
    And the orchestrator, on its next turn, proceeds to draft using the argument-led outline
    And the writer agent receives the selected outline as its structure

  Scenario: draftloom post-draft feedback uses a feedback surface
    Given a draft has been generated and eval scores are available
    When the orchestrator detects that "voice" and "hook" scores are both below threshold
    And writes /work/demo/.draftloom/content/feedback.json as a feedback SurfaceSpec asking about tone and opening
    Then the user sees a form with two fields at /p/draftloom/feedback
    And on submit, a vk-event of type "feedback" is appended to .draftloom/state/events
    And the orchestrator uses the user's tone answer to scope the next patch iteration

  # ── No plugin-to-plugin coupling ────────────────────────────────────────

  Scenario: paidagogos cannot read namesmith's content
    Given both paidagogos and namesmith are installed, and both have active surfaces
    When a paidagogos skill attempts to GET /p/namesmith/wave-1
    Then the server returns 200 (the URL is open — same localhost origin)
    But the surface has no CSRF token bound to paidagogos, so no event write is possible
    And no filesystem path in paidagogos's code references .namesmith/*

  Scenario: No filesystem path in visual-kit references a specific consumer
    When I grep plugins/visual-kit/src for "paidagogos" or "namesmith" or "draftloom"
    Then there are zero matches
    And the server only references the current set of registered content directories, which are discovered at runtime
