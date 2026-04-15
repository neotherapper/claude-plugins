# Changelog — Beacon

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

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
