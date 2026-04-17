# Visual-Kit V1 — End-to-End Smoke Test

**Date:** 2026-04-17
**Worktree:** `.worktrees/visual-kit-v1`
**Branch:** `feat/rename-learn-to-paidagogos`

## What was tested

1. visual-kit build pipeline (esbuild → dist/core.js, dist/cli.js, dist/server/index.js, dist/core.js.sri.txt)
2. Server starts, writes server-info, binds 127.0.0.1
3. Paidagogos-shaped lesson SurfaceSpec at `.paidagogos/content/flexbox.json` renders at `/p/paidagogos/flexbox`
4. Strict CSP header present (default-src 'none', nonce, no unsafe-*)
5. Theme + core bundle served from `/vk/theme.css` and `/vk/core.js`
6. Server stops cleanly via `visual-kit stop`

## Build artefacts verified

```
dist/cli.js         41.6kb
dist/server/index.js  34.7kb
dist/core.js        22.6kb
dist/core.js.sri.txt  (sha384-cZr93z...)
dist/theme.css      (copied from src/components/theme.css)
dist/schemas/surfaces/  (copied from schemas/surfaces/)
```

## curl-verified assertions

```
URL: http://localhost:49895

=== HTTP status + content-type ===
HTTP 200 text/html; charset=utf-8

=== CSP header presence (using GET + dump-header) ===
Content-Security-Policy: default-src 'none'; script-src 'self' 'nonce-W4SrYNOzjjkPy7Tdn_XIZg'; style-src 'self' 'nonce-W4SrYNOzjjkPy7Tdn_XIZg'; img-src 'self' data:; connect-src 'self'; font-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'

=== CSS Flexbox grep count ===
1

=== vk-section grep count ===
4

=== theme.css ===
theme.css: HTTP 200 text/css; charset=utf-8

=== core.js ===
core.js: HTTP 200 application/javascript; charset=utf-8
```

## Sections verified in the rendered page

- `vk-section` header (CSS Flexbox, beginner · 10 min)
- concept, why, code, mistakes, generate, next — all rendered as `<vk-section data-variant="...">` elements
- Caveat banner: "AI-generated — verify against official docs."

## Build fix applied during smoke test

The CLI bundle (`dist/cli.js`) inlines server code but sets `import.meta.url` to the CLI file location (`dist/`), not `dist/server/`. This broke three path resolutions at runtime:

1. `package.json` lookup (for version) — **fixed** by embedding `__VK_VERSION__` via esbuild `define` at build time.
2. Schema loading (`schemas/surfaces/*.json`) — **fixed** by copying schemas to `dist/schemas/` during build and injecting `__VK_ASSET_OFFSET__` to locate them relative to the bundle.
3. `theme.css` serving — **fixed** by copying `theme.css` to `dist/theme.css` during build.

A missing `import { join } from 'node:path'` was also added back to `src/server/index.ts` after removing the now-unneeded `dirname`/`fileURLToPath` imports.

## Known gaps (deferred to Plan B)

- code/math/chart/quiz renderers in core bundle are placeholders ("Section type X not yet supported in the core bundle").
- Browser interaction (clicking, quiz answers) requires real browser; verified server-side that POST /events handler enforces CSRF + cross-plugin isolation in csrf.test.ts.
