# Changelog

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
