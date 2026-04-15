# Changelog — Namesmith

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.1.0] — 2026-04-15

### Added

- `/namesmith` — single entry point: brand interview → generation → availability → `names.md`
- 6-question brand interview capturing tone, direction, budget mode, and constraints
- 7 naming archetypes: Short & Punchy, Descriptive, Abstract/Brandable, Playful/Clever, Domain Hacks, Compound/Mashup, Thematic TLD Play
- 10 proven naming techniques applied per archetype
- 25–35 candidates generated per wave
- Wave 2 refinement and Wave 3 deep TLD scan (1,441+ IANA TLDs)
- Track B fallback workflow for fully-taken results
- Domain availability check via Cloudflare Registrar API (primary)
- Domain availability check via Porkbun API (fallback)
- whois fallback for both APIs unavailable
- Pricing lookup via Porkbun no-auth endpoint
- Persistence: `names.md` written with shortlist, rationale, and brand profile
