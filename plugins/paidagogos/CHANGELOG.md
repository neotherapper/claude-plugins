# Changelog

## 0.3.0 — 2026-08-16

### Added
- `paidagogos:path` skill — loads a curriculum, renders it as an interactive tree via visual-kit, and routes individual concepts to `paidagogos:micro` for teaching.
- **AI Engineering curriculum** (`references/curricula/ai-engineering.curriculum.json`) — 38 concepts across five tracks (A Model & context, B Harness & integration, C Grounding & evaluation, D Verified state & governance, E Delivery & enablement). Track letters and the Axis A / Axis B framing are shared with the nikai learning path.
  - Two study sequences carried as data: `foundations-first` (default, weighted to the CCAR-F exam blueprint) and `dependency-first` (nikai's C → B → D → A → E ordering).
- **External course catalogue** (`references/curricula/ai-engineering.catalogue.json`) — certifications and courses grouped by institution and marked with the certification each prepares for.

### Changed
- The router no longer answers "coming in v0.3.0" for learning-path intents; "I want to become X", "roadmap for X", "show me the curriculum" and "what should I learn next" now route to `paidagogos:path`.
- Declares a dependency on `visual-kit ~1.3.0`, which introduces the `tree` surface this release renders on.

### Curriculum format
Curricula are now authored **directly as `tree` SurfaceSpecs** validated against `vk://schemas/tree.v1.json`, rather than as markdown lesson chains. The previous format (`seo-developer-mastery.md`) is a strict linear sequence and cannot express a five-track graph with cross-track prerequisites or typed resources. It still works and is unchanged; new curricula should use the JSON form.

Conventions layered on top of the schema — concept ids prefixed by track letter (`c-entailment-checking`), `branch`/`leaf` for tracks vs teachable concepts, and `detail.meta` for axis and exam weight — are documented in the `paidagogos:path` skill.

### Sourcing
Every certification fact in the catalogue was read from the vendor's own page or exam guide on 2026-08-16, and carries the date it was checked. Two findings worth recording:
- The Foundations exam code is **CCAR-F**, not "CCA-F".
- Microsoft's Azure AI Engineer Associate (AI-102) is **retired**; it is listed only so it can be ruled out, since search results still present it as current.

One entry is explicitly marked as single-sourced: the CCAR-P domain weights and item count were relayed from the nikai session's own PDF extraction rather than verified a second time here. The fee was verified directly.

Every URL in both files was resolved before shipping, and each carries the date it was checked. Seven documentation links were rewritten to their canonical hosts after checking — `docs.claude.com/...` redirects to `platform.claude.com` for API docs and `code.claude.com` for Claude Code docs. Certification entries also carry a `lifecycle` status, so a retired credential is marked structurally rather than only in prose.

## 0.2.0 — 2026-04-17

- Migrated to visual-kit for all rendering. Paidagogos no longer ships its own HTTP server.
- Lesson skill now writes the `lesson` SurfaceSpec v1 (visual-kit contract), conforming to `vk://schemas/lesson.v1.json`.
- Pre-flight checks `.visual-kit/server/state/server-info` instead of the old paidagogos path.
- Workspace state moved: lessons under `.paidagogos/content/<slug>.json`; quiz events under `.paidagogos/state/events`.
- Heavy renderers (math, chart, code editor, quiz interaction) deferred to Plan B; concept/why/code (static)/mistakes/generate/resources/next render via core bundle.

## [0.1.0] — 2026-04-15

### Added
- `paidagogos` router skill with scope classifier
- `paidagogos:micro` structured lesson skill
- Visual server (file-watcher, localhost:7337)
- Lesson card: concept, why, example, common mistakes, generate task, quiz
- Knowledge vault integration (file-read only)
- Dark/light mode, code copy buttons, no external CDN calls
- AI-generated content caveat on all lessons
