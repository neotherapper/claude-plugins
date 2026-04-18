# Changelog

## 1.1.0 — 2026-04-18

Plan B1 — rendering gaps. Adds three lazily-loaded component bundles and upgrades `<vk-code>` with server-side syntax highlighting. No breaking schema changes.

### New
- `<vk-math>` — KaTeX LaTeX rendering with `trust: false`, `strict: 'warn'`, `maxSize: 10`, `maxExpand: 1000` security flags. Fonts embedded as data URLs so the bundle stays self-contained under the existing strict CSP. Ships as `math.js`.
- `<vk-chart>` — Chart.js 4.x rendering driven by sibling `<script type="application/json">` config. Two-layer defense against callback-field injection (schema `not` clauses + runtime `chartConfigContainsCallbackFields` guard). Malformed JSON and callback-bearing configs render visible `<vk-error>` — no silent failures. Ships as `chart.js`.
- `<vk-quiz>` — per-item rendering for `multiple_choice`, `fill_blank`, `explain`. Emits `vk-event` with 1 KB `chosen` cap. Malformed config renders `<vk-error>`. Ships as `quiz.js`.
- Fragment-scanning autoloader (`src/render/autoload.ts`). Lessons preload only the bundles whose tags they contain. Each bundle is preloaded at most once even if multiple sections reference it.
- `unsafeJSON` helper (`src/render/escape.ts`) — OWASP-form escape for `<script type="application/json">` payloads. Neutralizes `</script`, `<!--`, `-->`, `&`, U+2028, U+2029.

### Changed
- `<vk-code>` — server-side Prism syntax highlighting (9 languages: javascript, typescript, python, css, html, json, bash, markdown, sql). Single CSS-variables theme imported via esbuild text loader. 100 KB input cap as a ReDoS guard.
- `lesson.v1.json` — tightened additively: `math.display?: boolean`; `chart.config` now `{ type, data, options? }` with a top-level callback-field `not` clause; `quiz.items[]` uses `oneOf` per item type.
- `POST /events` — validates `quiz_answer` events (index 0–99, item_type enum, chosen ≤ 1024 chars, boolean correct, ISO 8601 ts).
- CI gates — extended `lint-pure-components` with grep-bans on `unsafeHTML` / `unsafeJSON` outside allowlist and `new Function` / `eval` everywhere. Per-bundle size budgets added. `pnpm audit --audit-level=high` now part of `verify`.

### Security
- Pinned exact versions for `prismjs`, `katex`, `chart.js` (no `^` / `~`) per supply-chain rule.
- KaTeX `trust: false` prevents `\href{javascript:…}{…}` and other URL-scheme attacks.
- Chart.js callback keys rejected at schema and component layers.
- All three new components are pure (no `fetch`, no `localStorage`) — CI-enforced.
- `<vk-math>` propagates the shell's script nonce onto its injected KaTeX `<style>` element so strict `style-src` CSP accepts it.

### Tests
- 36 new unit tests (escape, highlight, autoload, code, math, chart, chart-callbacks, quiz, schema-lesson).
- 7 new integration tests (code, math, chart, quiz sections; autoloader dedup; malformed chart; quiz-event end-to-end).
- 7 new Playwright browser regression tests (shadow-DOM CSS cascade, KaTeX fonts, canvas pixels, Prism theme colors, SRI preload, quiz keyboard, CSP blocks inline).

## 1.0.0 — 2026-04-17

First release. Shared visual renderer for Claude Code plugins.

- CLI: `visual-kit serve | stop | status` (per-workspace, deterministic port via workspace-path hash)
- HTTP server: localhost-only, strict CSP with per-response nonce, per-page CSRF token, Host-header allowlist, path-traversal guards (regex + realpath + symlink rejection), HMAC-SHA256 CSRF tokens with timing-safe comparison, EADDRINUSE handling, advisory lock for multi-session safety
- Six V1 surfaces: lesson, gallery, outline, comparison, feedback, free (server-side DOMPurify sanitized; CSP neutralizes inline scripts regardless)
- Core bundle (~7.7 KB gzipped): vk-section, vk-card, vk-gallery, vk-outline, vk-comparison, vk-feedback, vk-loader, vk-error, vk-code
- `GET /vk/capabilities` for graceful version degradation
- SSE auto-reload on content-dir changes
- POST /events with cross-plugin isolation (target plugin derived server-side from Referer; body-supplied plugin field ignored)
- Bundled SRI hashes on all `<script>` and `<link>` tags
- CI gates: pure-component lint (no fetch/localStorage in components), security-headers test, bundle-size budget (40 KB gz max for core)
- 49 tests across unit + integration

Paidagogos 0.2.0 migrated to depend on this — its in-house HTTP server has been deleted.
