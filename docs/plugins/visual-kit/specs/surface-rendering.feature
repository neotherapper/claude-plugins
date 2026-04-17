Feature: visual-kit surface rendering — typed SurfaceSpec JSON → deterministic HTML fragment

  Background:
    Given visual-kit v1.0.0 is installed and running at http://localhost:34287 for workspace "/work/demo"
    And no SurfaceSpec files exist in /work/demo/.paidagogos/content/

  # ── SurfaceSpec writing and rendering ───────────────────────────────────

  Scenario: Writing a valid lesson SurfaceSpec renders a lesson page
    When I write /work/demo/.paidagogos/content/lesson.json containing a valid "lesson" SurfaceSpec for "CSS Flexbox"
    Then GET /p/paidagogos/lesson returns 200
    And the response Content-Type is "text/html; charset=utf-8"
    And the response body contains a <vk-section> for each section in the SurfaceSpec
    And the response body contains a <meta name="vk-csrf" content="..."> tag
    And the response body contains a Content-Security-Policy meta with default-src 'none'

  Scenario: Unknown fields in a SurfaceSpec are silently ignored
    When I write a lesson SurfaceSpec that includes an unknown top-level field "nickname"
    Then GET /p/paidagogos/lesson returns 200
    And the rendered fragment does not reference "nickname"

  Scenario: Unknown surface type returns a typed error fragment
    When I write /work/demo/.paidagogos/content/unknown.json with {"surface":"nonexistent","version":1}
    Then GET /p/paidagogos/unknown returns 200
    And the response body contains a <vk-error> fragment
    And the error text names the unknown surface "nonexistent"
    And the error links to /vk/capabilities

  Scenario: Schema-invalid SurfaceSpec is rejected
    When I write a lesson SurfaceSpec missing the required "topic" field
    Then GET /p/paidagogos/lesson returns 200
    And the response body contains a <vk-error> fragment
    And the error text describes the missing required field

  Scenario: Per-surface CSP relaxations only apply to the surface that needs them
    Given /work/demo/.paidagogos/content/python-lesson.json contains a section of type "python"
    And /work/demo/.paidagogos/content/plain-lesson.json contains no python sections
    When GET /p/paidagogos/python-lesson returns 200
    Then the CSP script-src includes 'wasm-unsafe-eval'
    But when GET /p/paidagogos/plain-lesson returns 200
    Then the CSP script-src does not include 'wasm-unsafe-eval'

  # ── Per-surface behaviour ───────────────────────────────────────────────

  Scenario: gallery surface renders cards with multiselect semantics
    When I write a gallery SurfaceSpec with multiselect: true and 3 items
    Then the rendered page includes a <vk-gallery data-multiselect="true"> wrapper
    And exactly 3 <vk-card> elements, each with its id as data-id
    And clicking a card emits a vk-event of type "select" with the clicked id

  Scenario: outline surface renders hierarchical nodes
    When I write an outline SurfaceSpec with 2 top-level nodes each with 2 children
    Then the rendered <vk-outline> contains the correct nesting depth
    And each node's heading and summary are rendered as text (escaped)

  Scenario: comparison surface renders two side-by-side variants
    When I write a comparison SurfaceSpec with 2 variants, each nesting an outline SurfaceSpec
    Then the rendered <vk-comparison> contains both variant bodies
    And the selection bar has one entry per variant
    And clicking a variant selection emits vk-event {type: "variant-chosen", label}

  Scenario: feedback surface renders declared fields in order
    When I write a feedback SurfaceSpec with a "choice" field and a "text" field
    Then the rendered <vk-feedback> contains both fields in the declared order
    And the submit button text matches the declared submit_label
    And pressing submit emits vk-event {type: "feedback", fields: {...}}

  Scenario: free surface renders raw HTML sanitized
    When I write a free SurfaceSpec whose html contains "<vk-section>ok</vk-section><script>alert(1)</script>"
    Then the rendered page contains the <vk-section>ok</vk-section>
    And the rendered page does NOT contain any <script> tag
    And the response CSP prevents inline script execution regardless

  # ── SSE auto-reload ─────────────────────────────────────────────────────

  Scenario: Overwriting a SurfaceSpec triggers browser reload via SSE
    Given a browser is connected to GET /events/stream
    When /work/demo/.paidagogos/content/lesson.json is replaced atomically
    Then the server emits one "refresh" SSE event within 500 ms

  Scenario: Writing a SurfaceSpec for a different surface does not notify unrelated connections
    Given two browsers are connected, one watching /p/paidagogos/lesson, one watching /p/namesmith/wave-1
    When /work/demo/.namesmith/content/wave-1.json changes
    Then the namesmith watcher receives a refresh event
    And the paidagogos watcher does not

  # ── Capabilities endpoint ───────────────────────────────────────────────

  Scenario: GET /vk/capabilities reports the installed surfaces and components
    When I GET /vk/capabilities
    Then the JSON response lists surfaces: lesson, gallery, outline, comparison, feedback, free
    And the JSON response lists components: vk-section, vk-card, vk-code, vk-math, vk-chart, vk-geometry, vk-sim-2d, vk-audio, vk-quiz, vk-hint, vk-explain, vk-progress, vk-streak
    And each listed surface has a schema URL under /vk/schemas/
    And each listed bundle has an SRI hash

  Scenario: Consumer queries capabilities before submitting a SurfaceSpec
    Given a consumer skill requires the "comparison" surface
    When the skill GETs /vk/capabilities
    Then if "comparison" is absent, the skill prints a clear error and halts
    And if "comparison" is present, the skill writes its SurfaceSpec
