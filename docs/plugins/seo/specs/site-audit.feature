Feature: Site-Audit skill — SEO audit producing docs/sites/{slug}/seo/

  Background:
    Given the SEO plugin v0.1.0 is installed
    And Python 3.10+ is available
    And the target site is reachable

  # ── Zero-config baseline ───────────────────────────────────────────────

  Scenario: Audit a site with zero MCPs and zero API keys
    Given no MCP servers are configured
    And no SEO API keys are set
    When I run /seo:audit https://example.com
    Then phases 1 through 8 complete using httpx/urllib only
    And docs/sites/example-com/seo/ is created
    And INDEX.md exists and contains an overall score between 0 and 100
    And seo-report.md contains findings for all five categories
    And [CWV-UNAVAILABLE] is logged (graceful degradation)
    And no script error blocks the audit

  Scenario: Audit produces a deterministic top-5 list
    Given a site with known issues (missing title, missing JSON-LD, >1 H1, skipped heading levels)
    When I run /seo:audit https://example.com
    Then INDEX.md contains a Top 5 Issues section
    And the issues are sorted by severity rank (error < warning < info)
    And ties are broken by category-impact score (higher first)
    And the section contains at most 5 entries plus padding text if fewer

  # ── Per-category rules ──────────────────────────────────────────────────

  Scenario: Missing title tag is flagged as an error
    Given a page with no <title> tag
    When I run /seo:audit https://example.com
    Then the on-page score loses 3 points
    And an error finding with rule "title-missing" is recorded in seo-report.md

  Scenario: Title length is flagged outside 50-60 char band
    Given a page with a title of 25 characters
    When I run /seo:audit https://example.com
    Then a warning finding with rule "title-short" is recorded
    And the on-page score reaches the 1-point tier (presence only) not the 3-point tier (length)

  Scenario: Duplicate H1 tags are flagged as an error
    Given a page with 3 <h1> tags
    When I run /seo:audit https://example.com
    Then an error finding with rule "h1-multiple" (count=3) is recorded
    And the content score loses 2 points (1 → 1-point tier)

  Scenario: Heading-level skip is flagged as a warning
    Given a page that goes <h1> → <h3> without an <h2>
    When I run /seo:audit https://example.com
    Then a warning finding with rule "heading-skip" is recorded
    And the details list the H1→H3 transition with the offending text

  Scenario: Missing JSON-LD is flagged as a warning
    Given a page with no <script type="application/ld+json"> tag
    When I run /seo:audit https://example.com
    Then the schema category scores 0/20
    And a warning finding is recorded

  Scenario: Deprecated rich-result schema type is flagged as a warning
    Given a page with a HowTo JSON-LD block
    When I run /seo:audit https://example.com
    Then a warning finding with rule "google-rich-result-deprecated" is recorded
    And the message clarifies that schema.org vocabulary is still valid

  # ── Beacon reuse ──────────────────────────────────────────────────────

  Scenario: Beacon prior recon data is reused
    Given docs/sites/example-com/research/tech-stack.md exists from a prior beacon run
    When I run /seo:audit https://example.com
    Then [RECON-REUSE] is logged
    And the audit reads tech-stack.md without re-detecting framework
    And the technical audit spends fewer than N network calls on tech detection

  Scenario: No prior beacon recon — audit degrades gracefully
    Given docs/sites/example-com/research/ does not exist
    When I run /seo:audit https://example.com
    Then [NO-RECON] is logged
    And the audit completes with reduced fidelity on tech detection
    And INDEX.md notes that beacon was not previously run

  # ── Reframe integration ───────────────────────────────────────────────

  Scenario: Reframe current-critique is populated after the audit
    Given reframe has produced docs/sites/example-com/redesign/current-critique.md
    When I run /seo:audit https://example.com
    Then [REFRAME-REUSE] is logged
    And the Content-side SEO/a11y signals section is preserved (not overwritten)

  # ── Tool failure modes ────────────────────────────────────────────────

  Scenario: Tools fail but the audit completes
    Given all 4 Python scripts (meta_audit, heading_audit, structured_data_validate, composite_scorer) are deleted
    When I run /seo:audit https://example.com
    Then the audit completes by reporting tool absence
    And INDEX.md shows "0 / no-script" placeholder scores
    And seo-report.md contains an [SCRIPT-MISSING:META],[SCRIPT-MISSING:HEADING],[SCRIPT-MISSING:SCHEMA]
    And the user is told to reinstall the plugin

  Scenario: HTTP fetch fails with timeout
    Given the target site responds slower than 15 seconds
    When I run /seo:audit https://example.com
    Then [FETCH-ERROR:timeout] is logged
    And the audit aborts after phase 2 with a clear error message
    And no partial output files are written

  # ── Score output format ──────────────────────────────────────────────

  Scenario: Score output uses the canonical 5-category breakdown
    When I run /seo:audit https://example.com
    Then INDEX.md shows the score as:
      """
      SEO Health Score: XX/100 (Rating)
      ├── Technical:   XX/25
      ├── On-Page:     XX/25
      ├── Schema:      XX/20
      ├── Content:     XX/15
      └── Performance: XX/15
      """

  Scenario: Rating band maps to actionable verb
    Then a score of 95 → Excellent → "minor optimizations only"
    And a score of 80 → Good → "address warnings"
    And a score of 60 → Needs Work → "prioritise critical issues"
    And a score of 30 → Critical → "major overhaul required"
