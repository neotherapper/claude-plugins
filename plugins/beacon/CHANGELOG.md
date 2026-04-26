# Changelog — Beacon

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.6.1] — 2026-04-26

### Added

- Tech pack: `technologies/zend-framework/1.x.md` — Zend Framework 1.x (EOL legacy)
  - 10-section pack covering fingerprinting, MVC route surface, config file exposure,
    Zend_Auth patterns, XML-RPC introspection, and ZF1-specific gotchas
  - Phase 3 SKILL.md updated with ZF1 HTML/error-page fingerprinting signals
  - Session-start hook updated to advertise Zend Framework 1 in tech pack list

---

## [0.6.0] — 2026-04-15

### Added

- `site-intel` Step 3a: tech pack cross-referencing — when a question involves framework-specific query patterns, endpoint conventions, or "how do I" phrasing, the relevant `technologies/{framework}/{major}.x.md` is loaded alongside the research file
- Trigger heuristics: explicit list of question types that load the tech pack vs. factual questions that use research files only
- Source labelling guidance: confirmed research findings vs. conventional tech pack knowledge are explicitly distinguished in answers
- Version mismatch handling: if exact version pack is unavailable, uses nearest major and notes it in the response
- Missing pack fallback: if no tech pack exists for a framework, proceeds with research files only without surfacing the gap to the user
- `tests/validate-site-intel.sh` — 12 checks on site-intel skill structure and tech pack logic

---

## [0.1.0] — 2026-04-15

### Added

- `/beacon:analyze {url}` — 12-phase systematic API surface analysis
- `/beacon:load` — query existing research docs without re-running analysis
- Tech fingerprinting: Wappalyzer-style heuristics + HTTP header inspection
- OSINT phase: Google dorks, certificate transparency, Wayback Machine, GitHub code search
- Script probing: source maps, webpack chunks, JS bundle extraction
- Browser recon phase via browser automation
- Framework-specific tech-pack guides (Next.js, WordPress, and more)
- OpenAPI spec generation from discovered endpoints
- Structured output to `docs/research/{site}/` with INDEX, tech-stack, site-map, API surfaces
- `site-analyst` agent for JS analysis and OSINT correlation
- SessionStart hook surfacing recent research sessions
