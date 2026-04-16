# Visual-Kit — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Visual-kit is a shared Claude Code plugin that other plugins depend on to render interactive local browser surfaces. It owns the HTTP server, the `<vk-*>` web component library, and the SurfaceSpec JSON contract. Consumer plugins (paidagogos, namesmith, draftloom, and future ones) declare visual-kit in their `plugin.json` dependencies, write SurfaceSpec JSON to their workspace content directories, and read interaction events back from their state directories.

**Current version:** 1.0.0 (not yet implemented — spec phase).

**Commands/CLI:** `visual-kit serve` · `visual-kit stop` · `visual-kit status` (via `bin/visual-kit` on PATH when the plugin is installed).

---

## File map

```
plugins/visual-kit/
├── README.md                              ← user-facing overview
├── CHANGELOG.md                           ← version history
│
├── .claude-plugin/
│   └── plugin.json                        ← manifest: name, version, bin/, skills[]
│
├── bin/
│   └── visual-kit                         ← CLI entry point (Node shim)
│
├── src/
│   ├── server/
│   │   ├── index.ts                       ← HTTP + SSE + lifecycle
│   │   ├── resolver.ts                    ← URL → content-file resolution, validation
│   │   ├── render.ts                      ← lit-html SSR, surface dispatch
│   │   ├── security.ts                    ← CSP builder, CSRF tokens, Host allowlist
│   │   └── events.ts                      ← POST /events handler
│   │
│   ├── components/                        ← All <vk-*> definitions (pure)
│   │   ├── core/                          ← section, card, gallery, outline, comparison, feedback, loader
│   │   ├── chart/
│   │   ├── code/
│   │   ├── math/
│   │   ├── geometry/
│   │   ├── sim-2d/
│   │   ├── audio/
│   │   ├── quiz/                          ← quiz, hint, explain
│   │   └── progress/                      ← progress, streak
│   │
│   └── surfaces/                          ← One file per surface type (lesson.ts, gallery.ts, ...)
│
├── schemas/
│   └── surfaces/                          ← lesson.v1.json, gallery.v1.json, ...
│
├── dist/                                  ← built bundles served at /vk/*.js (checked in for release)
│   ├── core.js
│   ├── chart.js
│   └── ...
│
├── skills/
│   └── visual-kit/
│       └── SKILL.md                       ← /visual-kit — user-facing lifecycle help
│
└── scripts/
    ├── build.mjs                          ← bundle builder (esbuild)
    ├── lint-pure-components.mjs           ← CI gate for RR-1 / AR-7
    └── test-security-headers.mjs          ← CI gate for SR-* requirements
```

---

## How consumers communicate with visual-kit

All coupling is through runtime seams. No plugin reads another plugin's filesystem.

| Step | Owner | What happens |
|------|-------|-------------|
| 1. Dependency resolution | Claude Code | Consumer's `plugin.json` lists `visual-kit` in `dependencies[]`. Installing the consumer auto-installs visual-kit. |
| 2. Server lifecycle | User or consumer skill | `visual-kit serve --project-dir <workspace>` is idempotent. Writes `.visual-kit/server/state/server-info`. |
| 3. SurfaceSpec write | Consumer skill | Writes `<workspace>/.<plugin>/content/<surface-id>.json` validated against a V1 schema. |
| 4. Render | visual-kit server | File-watcher detects write, validates, renders lit-html fragment with strict CSP, serves at `/p/<plugin>/<surface-id>`. |
| 5. Reload | Browser | SSE push on content-dir change. |
| 6. Events | Browser → server → consumer | `POST /events` with CSRF token. Server appends to `.<plugin>/state/events` JSON lines. Consumer skill reads later. |

---

## Key rules

- **No filesystem coupling between plugins.** `../other-plugin/...` paths do not resolve in the installed cache. All cross-plugin interaction is through the three seams (bin, HTTP, SurfaceSpec + events files in known workspace paths).
- **Components are pure.** No `fetch`, no `localStorage`, no reads of anything outside attributes and slots. CI enforces this.
- **No string-concatenated HTML.** Use lit-html SSR or the whitelist builder. String templating is a CI-blocking defect.
- **Server binds 127.0.0.1 by default.** Any other bind logs a warning. DNS rebinding is defended at the Host-header layer independent of the bind choice.
- **SurfaceSpec evolves additively.** Unknown fields ignored, unknown surfaces return a typed error fragment. Schema-breaking changes require a new visual-kit major version.
- **`free` is the escape hatch, not the default.** Designing a new layout should usually prefer composing existing `<vk-*>` components; `free` exists for one-off needs that CSP + DOMPurify make safe.
- **Every rendered page gets strict CSP with a per-response nonce.**

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-04-17-visual-kit-design.md` |
| Gherkin acceptance specs | `docs/plugins/visual-kit/specs/*.feature` |
| Features & roadmap | `docs/plugins/visual-kit/features.md` (to be written) |
| Architectural decisions | `docs/plugins/visual-kit/DECISIONS.md` (to be written) |
| User-facing README | `plugins/visual-kit/README.md` (to be written) |
| Security model | See §5.7 and §9 of the design spec |
