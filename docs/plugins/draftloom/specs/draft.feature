Feature: draft skill — write a blog post through brief, wireframe, eval loop, and distribution

  Background:
    Given Draftloom v0.1.0 is installed in Claude Code
    And .draftloom/profiles/george-personal.json exists

  # ── Profile selection ─────────────────────────────────────────────────────

  Scenario: No profiles exist — user directed to setup
    Given no .draftloom/profiles/ directory exists
    When I run /draftloom:draft
    Then the skill responds: "No profiles found. Run /draftloom:setup to create your first writing profile."
    And does not proceed further

  Scenario: Single profile auto-selected
    Given exactly one profile exists
    When I run /draftloom:draft
    Then the skill confirms the profile name and proceeds without asking

  Scenario: Multiple profiles shown with recency order
    Given profiles george-personal.json and vanguard-corp.json exist
    When I run /draftloom:draft
    Then the skill shows a numbered list with draft count and last-used date
    And I can select by typing the number or a search string

  # ── Brief interview ───────────────────────────────────────────────────────

  Scenario: Brief captures 4 mandatory questions one at a time
    When I run /draftloom:draft with george-personal profile
    Then the skill asks the topic/angle question first
    And waits for my answer before asking the next question
    And asks for the core insight the reader should leave with
    And asks for any examples, data, or stories to include
    And asks for target length (short ~500w / medium ~1000w / long ~2000w+)

  Scenario: Optional SEO fields offered after mandatory brief
    When I complete the 4 mandatory brief questions
    Then the skill offers: "Add SEO and distribution context? (y/n)"
    When I answer yes
    Then the skill asks for primary keyword, competitor URLs, and publish date
    When I answer no
    Then the skill proceeds to wireframe without SEO fields

  Scenario: Brief is saved to posts/{slug}/brief.md
    When the brief interview completes
    Then posts/{slug}/brief.md exists
    And contains sections: Topic, Insight, Audience, Tone, Examples, Length, Key Messages, CTA, Constraints

  # ── Wireframe proposal ────────────────────────────────────────────────────

  Scenario: Wireframe proposed with numbered sections and word counts
    When the brief is complete
    Then the skill proposes a numbered section outline in the terminal
    And each section shows: number, name, approximate word count, and purpose description
    And the total word count matches the profile's typical_length preference

  Scenario: User can tweak the wireframe with parse-able commands
    When the wireframe is shown
    And I type "change 3 to 500w"
    Then section 3 word count is updated to 500w
    And the total is recalculated and shown

  Scenario: User can add a section between existing ones
    When I type "add section between 1 and 2: backstory 150w"
    Then a new section is inserted at position 2
    And all subsequent sections renumber
    And the updated wireframe is shown with new total

  Scenario: User can remove a section
    When I type "remove 4"
    Then section 4 is removed from the wireframe
    And sections renumber accordingly

  Scenario: Wireframe confirmation written to session.json
    When I confirm the wireframe
    Then session.json contains wireframe_approved: true
    And posts/{slug}/meta.json is created with title, slug, and profile_id

  # ── Draft generation ──────────────────────────────────────────────────────

  Scenario: Writer agent drafts from brief on iteration 1
    When the wireframe is confirmed
    Then the writer agent reads brief.md only (no eval files exist yet)
    And writes a full draft to posts/{slug}/draft.md
    And the draft follows the wireframe structure

  Scenario: Draft folder created with correct workspace files
    When the draft is written
    Then posts/{slug}/ contains: draft.md, brief.md, meta.json, session.json, state.json, scoring-config.json

  # ── Eval loop ────────────────────────────────────────────────────────────

  Scenario: All 4 eval agents run in parallel after draft
    When draft.md is written
    Then the skill shows: "Iteration 1 of 3 — running 4 evals..."
    And seo-eval, hook-eval, voice-eval, readability-eval agents run concurrently
    And each writes its own *-eval.json file atomically

  Scenario: Scores shown after each iteration
    When all 4 eval agents complete iteration 1
    Then the skill shows scores for all 4 dimensions on one line
    And flags failing dimensions with ⚠ and passing ones with ✓

  Scenario: Writer patches only failing sections on iteration 2+
    Given iteration 1 scores: seo=72, hook=85, voice=68, readability=80
    When the writer agent runs on iteration 2
    Then it reads sections_affected from seo-eval.json and voice-eval.json
    And patches only those sections in draft.md
    And does not modify sections that scored ≥ 75

  Scenario: All dimensions pass — distribution triggered
    Given all 4 eval scores are ≥ 75 after iteration 2
    Then the skill shows: "All dimensions passing. Generating distribution copy..."
    And the distribution agent runs once
    And distribution.json is written with x_hook, linkedin_opener, email_subject, newsletter_blurb

  Scenario: Score below 50 triggers structured escalation
    Given any dimension scores below 50 on any iteration
    Then the skill pauses the loop
    And asks 4 structured questions to gather user input (topic clarity, audience, intent, off-topic content)
    And resumes with user's answers as additional writer context
    And escalation occurs at most once per run

  Scenario: Escalation declined — draft saved as paused
    Given the skill escalates due to score < 50
    When I decline to answer the structured questions
    Then draft_status in meta.json is set to "paused"
    And the skill exits cleanly with the workspace path

  Scenario: Max iterations reached with failing scores
    Given 3 iterations have completed and some dimensions are still below 75
    Then the skill offers three choices:
      | choice          | action                                    |
      | publish anyway  | run distribution agent with current draft |
      | extend          | ask how many more iterations to run       |
      | discard         | set draft_status to "abandoned" and exit  |

  # ── Halt / finalize early ─────────────────────────────────────────────────

  Scenario: User exits loop early with "finalize"
    Given the eval loop is running on iteration 2
    When I type "finalize" or "publish now" or "skip iterations"
    Then the skill stops the loop immediately
    And runs the distribution agent with the current draft
    And writes distribution.json

  # ── Final output ──────────────────────────────────────────────────────────

  Scenario: Final output shows workspace path and files
    When the draft is complete
    Then the skill shows the workspace path: posts/{slug}/
    And lists: draft.md, distribution.json, scores.json
    And scores.json contains the final iteration scores for all 4 dimensions

  # ── Session recovery ──────────────────────────────────────────────────────

  Scenario: Incomplete session detected on re-run
    Given posts/my-draft/session.json exists with checkpoint "eval_loop_start"
    When I run /draftloom:draft my-draft
    Then the skill shows: "Found incomplete draft: 'my-draft' (checkpoint: eval_loop_start). Resume? (y/n)"
    When I answer yes
    Then the skill resumes from the last checkpoint

  Scenario: User starts fresh instead of resuming
    Given an incomplete session exists for my-draft
    When I run /draftloom:draft my-draft and answer "n" to resume
    Then the skill clears the workspace and restarts the brief interview

  # ── Hybrid backend ────────────────────────────────────────────────────────

  Scenario: File-based workspace used when no Turso config present
    Given .draftloom/config.json does not have turso_enabled
    When I run /draftloom:draft
    Then all workspace state is written to posts/{slug}/ files only

  Scenario: Turso failure does not block iteration
    Given turso_enabled is true in config but Turso is unreachable
    When an eval iteration runs
    Then the iteration completes using file-based state
    And a warning is logged but the loop continues
