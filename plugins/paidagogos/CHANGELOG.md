# Changelog

## [Unreleased] — V2 Core Renderer System

### Added
- `renderers[]` field in Lesson JSON — declares which renderer modules the lesson needs; drives lazy component loading in `lesson.html`
- `<edu-math>` renderer — KaTeX-rendered mathematics (inline + display mode)
- `<edu-code>` renderer — highlight.js syntax-highlighted code blocks (javascript, typescript, python, css, html, json). Interactive editing via `editable: true` deferred to V2.1 (pending CodeMirror 6 import-map deduplication of `@codemirror/state`).
- `<edu-chart>` renderer — Chart.js charts via JSON config (bar, line, scatter, etc.)
- `<edu-geometry>` renderer — JSXGraph interactive 2D geometry
- `<edu-sim-2d>` renderer — Matter.js 2D physics simulations with built-in mouse interaction
- `renderer-map.md` reference — keyword → renderer classification table used by `paidagogos:micro`
- Lit 3 runtime loaded per-component via ESM imports from `esm.sh`; `lesson.html` issues a `<link rel="modulepreload">` for warm cache
- Web Awesome 3 UI chrome autoloader in `lesson.html`
- `/components/**` static route in the HTTP server with path-traversal protection
- Test fixtures under `server/test-fixtures/` covering each V2 renderer

### Changed
- `lesson.html` now lazy-imports components via `<edu-[name]>` custom elements — a lesson with `renderers: ["code"]` never loads Three.js or KaTeX
- `example` field in Lesson JSON can include `renderer` (key) and `config` (renderer-specific payload); `code`/`prose` remain for plain lessons
- `paidagogos:micro` gained a "Classify renderers" step that consults `renderer-map.md`
- Lesson JSON schema includes `RendererKey` union (V2 set: math, code, chart, geometry, sim-2d)

### Compatibility
- Pre-V2 lessons (no `renderers` field) render identically to V1 — the field defaults to `[]` at runtime and `renderExample` falls through to the original code-block path

## [0.1.0] — 2026-04-15

### Added
- `paidagogos` router skill with scope classifier
- `paidagogos:micro` structured lesson skill
- Visual server (file-watcher, localhost:7337)
- Lesson card: concept, why, example, common mistakes, generate task, quiz
- Knowledge vault integration (file-read only)
- Dark/light mode, code copy buttons, no external CDN calls
- AI-generated content caveat on all lessons
