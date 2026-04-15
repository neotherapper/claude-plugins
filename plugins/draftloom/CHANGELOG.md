# Changelog — Draftloom

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.1.0] — 2026-04-15

### Added

- `/draftloom:setup` — 3-question voice profile onboarding (tone, style, examples)
- `/draftloom:draft` — full post workflow: brief → wireframe → draft → eval loop → distribution
- `/draftloom:eval` — standalone scorer for existing markdown files
- 4 parallel eval agents: SEO, hook, voice, readability
- Orchestrator agent managing the eval loop and patch dispatch
- Writer agent: full draft on iteration 1, targeted patch on iteration 2+
- Distribution agent: X hook, LinkedIn opener, email subject, newsletter blurb
- File-based workspace in `posts/{slug}/` with atomic eval writes
- Session recovery via `session.json` checkpoint
- Optional Turso MCP backend for cross-project analytics
- SessionStart hook prompting setup when no profiles exist
- Multiple named profiles per user
