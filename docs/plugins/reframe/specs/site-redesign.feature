Feature: site-redesign skill — analyse an existing site and produce docs/sites/{site}/redesign/

  Background:
    Given reframe v0.1.0 is installed in Claude Code
    And the user's project has a docs/sites/ directory

  # ── SPA redesign run ─────────────────────────────────────────────────────

  Scenario: Analyse a React SPA clinic site — render escalates to markdown crawler
    Given Chrome DevTools MCP is available
    And Jina Reader is available
    When I run /reframe:analyze https://trustyourphysio.com/
    Then Phase 3 detects near-empty server HTML and emits [RENDER-ESCALATED]
    And content is re-fetched via Jina Reader (markdown crawler)
    And Phase 7 selects the local-service category pack and emits [PACK-LOADED:local-service]
    And the pivot question is asked: "redesign for the same purpose, or a new one?"
    And all six output files are written under docs/sites/trustyourphysio-com/redesign/
    And brief.md contains the verbatim web-capture-override sentence
    And no {{TOKEN}} placeholders remain in any output file

  Scenario: Phases always execute in the specified order
    When /reframe:analyze runs on any URL
    Then Phase 2 (structure discovery) completes before Phase 3 (render gate)
    And Phase 3 completes before Phase 4 (content crawl)
    And Phase 5 (content audit) completes before Phase 6 (IA map)
    And Phase 7 (intent inference) completes before Phase 8 (critique)
    And Phase 8 completes before Phase 9 (synthesize)

  # ── Greenfield / placeholder detection ──────────────────────────────────

  Scenario: Placeholder site detected — pipeline halts before inference
    Given the target URL returns a coming-soon page with fewer than 2 headings and fewer than 150 words of non-nav prose
    When I run /reframe:analyze https://placeholder-site.example/
    Then Phase 3 emits [GREENFIELD-MODE]
    And the pipeline halts after Phase 3
    And INDEX.md is written under docs/sites/ with the greenfield finding
    And no brief.md is produced
    And Claude does not invent a purpose or audience for the site

  Scenario: SPA with no real content after render — also enters greenfield mode
    Given the target URL is a React SPA
    And after render escalation the page still has fewer than 2 headings and fewer than 150 non-nav words
    When I run /reframe:analyze https://empty-spa.example/
    Then [RENDER-ESCALATED] fires first
    Then [GREENFIELD-MODE] fires after render
    And the pipeline halts with only INDEX.md written under docs/sites/

  # ── Category fallback to generic ────────────────────────────────────────

  Scenario: Ambiguous site with low category confidence falls back to generic pack
    Given the target site does not clearly match any specific category pack
    And the top-scoring category confidence is low
    When Phase 7 runs intent inference and category detection
    Then [PACK-LOADED:generic] is emitted
    And the assumption is noted explicitly in the brief's assumptions header
    And the brief is still produced using the generic pack's design-system seed and best-practice guidance

  Scenario: Multi-category site uses dominant pack — secondaries noted inline
    Given the target site scores across both ecommerce and saas-marketing categories
    When Phase 7 detects the dominant category as ecommerce
    Then [PACK-LOADED:ecommerce] is emitted
    And the brief notes "primarily ecommerce; secondary: saas-marketing" inline
    And the ecommerce pack's design-system seed and critique criteria are used throughout
    And the packs are not merged

  # ── Bare URL with no redesign intent defers to beacon ───────────────────

  Scenario: Bare URL with no redesign intent does not trigger site-redesign
    Given beacon is installed alongside reframe
    When I submit a bare URL with no redesign intent: "https://example.com"
    Then the site-redesign skill is NOT invoked
    And the request is handled by beacon's site-recon skill

  Scenario: API-intent request does not trigger site-redesign
    Given beacon is installed alongside reframe
    When I ask "what endpoints does example.com have?"
    Then the site-redesign skill is NOT invoked
    And the request is handled by beacon's site-recon skill

  # ── WAF and partial coverage ─────────────────────────────────────────────

  Scenario: WAF-blocked site — fallback chain exhausted, partial brief produced
    Given the target site returns 403 from WebFetch, Firecrawl, and Jina
    When I run /reframe:analyze https://walled-site.example/
    Then [WAF-BLOCKED] is emitted after all three fallbacks fail
    And the pipeline does not hard-stop
    And a partial brief is produced with a coverage note naming what was unreachable
    And INDEX.md surfaces [WAF-BLOCKED] in the coverage manifest

  Scenario: Chrome DevTools MCP unavailable — text-only output with noted gap
    Given Chrome DevTools MCP is not configured
    And Jina Reader, Firecrawl, and Crawl4AI are unavailable for screenshots
    When I run /reframe:analyze https://example.com/
    Then [TOOL-UNAVAILABLE:chrome-mcp] is logged in the session brief
    And current-critique.md contains [VISUAL-GAP: visual-hierarchy critique not possible without screenshots]
    And all six output files are still written
