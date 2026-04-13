Feature: site-recon skill — analyse a new site and produce docs/research/{site}/

  Background:
    Given Beacon v0.1.0 is installed in Claude Code
    And the user's project has a docs/research/ directory

  # ── Zero-MCP baseline ────────────────────────────────────────────────────

  Scenario: Analyse a WordPress site with zero MCPs
    Given no MCP servers are configured
    When I run /beacon:analyze https://example.com
    Then phases 1 through 12 complete using curl fallbacks only
    And docs/research/example-com/ is created
    And docs/research/example-com/INDEX.md exists and is non-empty
    And docs/research/example-com/tech-stack.md identifies WordPress and its version
    And docs/research/example-com/api-surfaces/wp-rest.md documents the /wp-json/ surface
    And docs/research/example-com/scripts/test-example-com.sh is executable
    And INDEX.md contains [TOOL-UNAVAILABLE:Wappalyzer]
    And INDEX.md contains [TOOL-UNAVAILABLE:ChromeDevTools]

  Scenario: Script download succeeds on first run
    Given no .beacon/scripts/ directory exists
    When I run /beacon:analyze https://example.com
    Then .beacon/scripts/core/ is created
    And core probe scripts are downloaded from raw.githubusercontent.com
    And each downloaded script passes SHA256 hash verification
    And scripts are marked executable

  Scenario: Script download fails — inline fallback activates
    Given GitHub is unreachable
    When I run /beacon:analyze https://example.com
    Then the skill generates probe scripts inline using Claude
    And the session brief logs [GENERATED-INLINE:probe-basics.sh]
    And analysis completes with reduced fidelity
    And INDEX.md notes the inline fallback

  # ── Tech pack loading ─────────────────────────────────────────────────────

  Scenario: Tech pack loads from GitHub for a known framework
    Given technologies/nextjs/15.x.md exists in the plugin repo
    When a Next.js 15 site is detected in Phase 3
    Then Phase 4 downloads technologies/nextjs/15.x.md from the version-pinned GitHub URL
    And Phase 5 applies the probe checklist from that file
    And the checklist items are worked through in order

  Scenario: Missing tech pack triggers web search and PR offer
    Given technologies/astro/5.x.md does not exist in the plugin repo
    When an Astro 5 site is detected in Phase 3
    Then Phase 4 falls back to web search for "astro 5 API routes file structure"
    And a temporary in-memory tech pack is created for this session
    And at the end of Phase 12 the user is offered the option to open a PR
    When the user accepts
    Then technologies/astro/5.x.md is drafted using the tech pack schema
    And a branch tech-pack/astro-5 is created on the plugin repo
    And a PR is opened with title "feat(tech-packs): add astro 5.x"

  Scenario: Tech pack version mismatch — nearest major version used with warning
    Given technologies/nextjs/14.x.md exists but technologies/nextjs/15.x.md does not
    When a Next.js 15 site is detected
    Then the skill loads 14.x.md with a warning: [TECH-PACK-VERSION-MISMATCH:nextjs:15.x→14.x]
    And the warning appears in INDEX.md

  # ── OpenAPI auto-detection ────────────────────────────────────────────────

  Scenario: OpenAPI spec auto-downloaded from /api/docs
    Given the target site exposes /api/docs returning valid OpenAPI 3.1 JSON
    When Phase 8 probes the standard OpenAPI paths
    Then /api/docs is detected as returning a valid spec
    And the spec is saved to docs/research/example-com/specs/example-com.openapi.yaml
    And the spec contains x-beacon-source: "auto-downloaded"
    And Phase 12 skips manual OpenAPI scaffolding

  Scenario: No OpenAPI found — spec scaffolded from discovered endpoints
    Given no standard OpenAPI path returns a valid spec
    When Phase 12 runs
    Then a scaffolded OpenAPI spec is written to specs/example-com.openapi.yaml
    And it contains x-beacon-source: "scaffolded"
    And each discovered endpoint from api-surfaces/ appears as a path in the spec

  # ── OSINT phase ───────────────────────────────────────────────────────────

  Scenario: OSINT phase discovers staging subdomain via crt.sh
    Given crt.sh returns staging.example.com for the target domain
    When Phase 9 processes crt.sh results
    Then staging.example.com is added to docs/research/example-com/site-map.md
    And it is flagged as [STAGING-ENV]

  Scenario: Google dork library is emitted for the domain
    When Phase 9 runs
    Then the session brief contains the standard dork query set for the domain
    And any Google results are incorporated into the OSINT findings section of INDEX.md

  # ── Browse plan and active phase ─────────────────────────────────────────

  Scenario: Browse plan generated before browser opens
    Given Chrome DevTools MCP is available
    When Phase 10 runs
    Then a browse plan is written to the session brief before any browser action
    And the plan contains at least one priority-1 URL derived from Phase 7 JS analysis
    And Phase 11 executes actions in the plan order

  Scenario: Active browse phase skipped when no browser tool available
    Given neither cmux nor Chrome DevTools MCP is available
    When Phases 10 and 11 are reached
    Then Phase 10 generates the browse plan but marks it as [BROWSER-UNAVAILABLE]
    And Phase 11 is skipped
    And INDEX.md notes: "Active browse phase skipped — no browser tool available"

  # ── Phase ordering ────────────────────────────────────────────────────────

  Scenario: Phases always execute in the specified order
    When /beacon:analyze runs on any URL
    Then Phase 2 (passive) completes before Phase 3 (fingerprint)
    And Phase 3 completes before Phase 4 (tech pack)
    And Phase 9 (OSINT) completes before Phase 10 (browse plan)
    And Phase 10 (browse plan) completes before Phase 11 (active browse)
    And Phase 11 completes before Phase 12 (document)
