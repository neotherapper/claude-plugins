# Visual-Kit — Shared Visual Rendering Plugin for Claude Code

> Design spec. Status: **draft**, awaiting user review.
> Target: first shippable version (`v1.0.0`), migrating three existing consumers (paidagogos, namesmith, draftloom).
> Date: 2026-04-17 · Author: Georgios Pilitsoglou (with Claude Opus 4.7)

---

## 1. Summary

`visual-kit` is a **library plugin** for Claude Code that ships:

1. A local HTTP server (per-workspace, localhost-bound, hardened).
2. A set of pure web components (`<vk-*>`) for rendering lesson content, galleries, outlines, comparisons, feedback forms, and raw fragments.
3. A typed **SurfaceSpec JSON** contract that consumer skills write to disk; the server renders the spec into HTML that loads the required component bundles on demand.

Other plugins in the repo (**paidagogos**, **namesmith**, **draftloom**, and future consumers) declare `visual-kit` as a dependency in their `plugin.json` (Claude Code v2.1.110+), never reach into its filesystem, and obtain rendering capability through three runtime seams only: the `bin/visual-kit` CLI on PATH, HTTP endpoints served at `http://localhost:<port>/`, and the component bundles at `/vk/*.js`.

The intent is to **pay the extraction cost once** so every current and future consumer gets visual rendering, theme, accessibility, interaction capture, and component evolution for free — while ensuring no plugin depends on another plugin's files.

---

## 2. Problem statement

### 2.1 Today

- **paidagogos** ships a `~150-line` Node HTTP server (`server/server.js`), a launch script, and a monolithic `lesson.html` template.
- **namesmith**, **draftloom**, and **beacon** have no visual server. They write markdown or JSON artifacts that users read in an editor.
- The paidagogos V2 research doc (`docs/plugins/paidagogos/research/rendering-and-pedagogy.md`) already documents a rich component taxonomy (`<edu-*>` portable renderers vs `<learn-*>` pedagogy components) and tier-based lazy loading — but this vision was scoped inside paidagogos.

### 2.2 Pain

- Any plugin that wants a visual surface today must duplicate the server (~150 lines of HTTP + file-watcher + SSE + events) and the CSS/theme shell.
- A shared component library (charts, math, code editors, 3D) is worth far more once: duplication would be 3000+ lines of bundled dependencies, per plugin, each bit-rotting independently.
- Claude Code explicitly **forbids filesystem coupling between plugins** — installed plugins live in isolated cache directories; `../other-plugin/...` paths do not resolve.
- The V2 paidagogos plan assumes its components are paidagogos-local, which blocks reuse by namesmith and draftloom even though the components have no pedagogy-specific state.

### 2.3 What the architecture must solve

- A single renderer owns HTTP, components, theme, accessibility, reload, and event capture.
- Consumer plugins express intent via a **typed JSON contract**; the renderer handles HTML generation, escaping, and security.
- No plugin reaches into another plugin's filesystem; all coupling is through runtime seams (CLI, HTTP, JSON files in well-known workspace paths).
- Security is bounded by design: strict CSP, per-page tokens, path validation, DNS-rebinding defense — not "trust the author."
- Evolution is additive; a newer visual-kit serves older consumers without breaking them.

---

## 3. Goals and non-goals

### 3.1 Goals (V1)

- **G-1** Paidagogos, namesmith, and draftloom all consume visual-kit via `plugin.json` dependencies on day one.
- **G-2** Ship six SurfaceSpec types: `lesson`, `gallery`, `outline`, `comparison`, `feedback`, `free`.
- **G-3** Ship pure `<vk-*>` components covering three groups: layout primitives (section, card, gallery, outline, comparison, feedback, loader, error), domain renderers (code, math, chart, geometry, sim-2d, audio), and pedagogy primitives (quiz, hint, explain, progress, streak).
- **G-4** Per-workspace server lifecycle; multi-session safe; port derived from workspace hash with auto-increment fallback.
- **G-5** Security posture: strict CSP, per-response nonce, per-page CSRF token, Host-header allowlist, path-traversal guards, pinned dependencies with SRI.
- **G-6** `GET /vk/capabilities` endpoint so consumer skills degrade gracefully on schema drift.
- **G-7** CI-enforced pure-component rule: lint rejects components that `fetch()`, read `localStorage`, or reach outside their attributes/slots.

### 3.2 Goals (V1.1)

- Heavy bundles (Three.js, Pyodide, Sandpack, p5.js) served with explicit `<vk-loader>` placeholder while bundle loads.
- Component-bundle SRI attestation pipeline in CI.

### 3.3 Goals (V2)

- `visual-kit:renderer` agent — a thin LLM adapter that translates natural-language intent + structured data into a SurfaceSpec, for consumers that prefer to describe rather than specify.

### 3.4 Goals (V3)

- MCP-UI `UIResource` output mode so visual-kit surfaces can render inline in hosts that support it (Claude Desktop, claude.ai, VS Code Copilot, Goose). Same components, same SurfaceSpec, new transport.

### 3.5 Non-goals

- **NG-1** visual-kit is not a general web-app framework. It supports fragment rendering for short-lived, local, developer-facing surfaces. It is not for public internet deployment, long-lived sessions, or multi-user scenarios.
- **NG-2** visual-kit does not persist user state beyond the events log. Long-term progress, streaks, mastery scores live in consuming plugins.
- **NG-3** visual-kit is not a server for arbitrary npm packages. Bundles are pre-built at release time, pinned to specific upstream versions, and shipped via the plugin.
- **NG-4** visual-kit does not do authentication. Its sole trust boundary is "localhost, same browser, same workspace."
- **NG-5** visual-kit does not attempt to render in the terminal. Consumer skills must detect server availability and fall back explicitly when a browser is unavailable.

---

## 4. Requirements

### 4.1 Functional (FR)

| ID   | Requirement |
|------|-------------|
| FR-1 | A consumer plugin must be able to render a surface by writing a SurfaceSpec JSON file to its own content directory, without coupling to visual-kit's filesystem. |
| FR-2 | The server must serve surfaces for multiple consumers concurrently, with URL-level namespacing. |
| FR-3 | The server must detect changes to content files and push reload signals to connected browsers via SSE. |
| FR-4 | The server must accept interaction events via `POST /events` and append them to the consumer's `state/events` file as JSON lines, with request-scoped authorization. |
| FR-5 | The server must serve component bundles lazily, loading only the bundles a surface actually uses. |
| FR-6 | Components must honor OS dark-mode preference via `prefers-color-scheme`, with no per-consumer configuration. |
| FR-7 | Consumer skills must be able to query `GET /vk/capabilities` and degrade gracefully when a required surface, component, or schema version is unavailable. |
| FR-8 | Every rendered page must ship strict CSP, per-response nonce, and per-page CSRF token. |
| FR-9 | When the server is not running, a consumer skill must receive an explicit error with a clear remediation path, not a silent failure. |
| FR-10 | The server must self-terminate after a documented inactivity timeout; a restart must be idempotent with respect to server-info. |

### 4.2 Architectural (AR)

| ID   | Requirement |
|------|-------------|
| AR-1 | visual-kit must expose only runtime seams to consumers: `bin/visual-kit` CLI on PATH, HTTP endpoints on localhost, and bundled component modules served by those HTTP endpoints. No filesystem paths cross plugin boundaries. |
| AR-2 | Consumer plugins declare `visual-kit` in `plugin.json` `dependencies[]` with a semver range. |
| AR-3 | The component library must be split into a small always-loaded core plus domain bundles loaded on demand based on surface content. |
| AR-4 | State (server-info, events) must be file-based at well-known workspace paths consumer skills can read without consulting visual-kit. |
| AR-5 | SurfaceSpec JSON and `<vk-*>` components must remain pure data-in / events-out, forward-compatible with MCP-UI `UIResource` wrapping in a future major version. |
| AR-6 | Server lifecycle is per-workspace, never global. Port is derived from a workspace-path hash with auto-increment on collision. |
| AR-7 | Components must never read consumer-plugin state directly. All consumer-specific data reaches a component through attributes or slotted markup in the rendered fragment. |
| AR-8 | Rendering must use lit-html SSR or an equivalent whitelist-based HTML builder. String-concatenated HTML is a CI-blocking defect. |

### 4.3 Reusability (RR)

| ID   | Requirement |
|------|-------------|
| RR-1 | Every `<vk-*>` component must be usable by every consumer plugin without code changes in visual-kit. |
| RR-2 | Composite surfaces (`lesson`, `gallery`, `outline`, `comparison`, `feedback`) live inside visual-kit and are available to every consumer. |
| RR-3 | Adding a new component or surface to visual-kit must never break an existing consumer. Fields are additive; unknown fields are ignored; unknown surface types return a typed error fragment. |
| RR-4 | Consumer plugins must be able to escape to raw HTML (via the `free` surface) when the supplied surfaces do not fit, bounded by the CSP and sanitation pipeline. |

### 4.4 Quality (QR)

| ID   | Requirement |
|------|-------------|
| QR-1 | The core bundle must be ≤ 40 KB gzipped at V1 ship. |
| QR-2 | The rendered page must make zero requests to external origins (no CDN, no fonts, no analytics). |
| QR-3 | All interactive components must be keyboard-navigable and meet WCAG AA contrast. |
| QR-4 | The initial render from `POST` of a SurfaceSpec to first paint in the browser must complete in under 500 ms on a typical developer workstation with no pre-warmed browser. |
| QR-5 | Every bundle served must carry a subresource-integrity (SRI) hash in the loading `<script>` tag. |

### 4.5 Security (SR)

| ID   | Requirement |
|------|-------------|
| SR-1 | The server binds to `127.0.0.1` by default. Any other bind address emits a visible warning to stderr on startup. |
| SR-2 | The server enforces a Host-header allowlist (`127.0.0.1:<port>`, `localhost:<port>`, and optionally a configured `--url-host:<port>`) on every request. Requests with other Host headers return `421 Misdirected Request`. |
| SR-3 | Every rendered page ships `Content-Security-Policy: default-src 'none'; script-src 'self' 'nonce-<random>'; style-src 'self' 'nonce-<random>'; img-src 'self' data:; connect-src 'self'; font-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'` with the relaxations documented per-bundle (e.g., `wasm-unsafe-eval` when a Pyodide surface loads). |
| SR-4 | Every rendered page carries a per-page CSRF token embedded in a `<meta name="vk-csrf">` element. `POST /events` requires this token in an `X-Vk-Csrf` header and rejects mismatched or missing tokens with `403`. |
| SR-5 | The target plugin for a `POST /events` is derived server-side from the `Referer` or `Origin` path (`/p/<plugin>/...`); body-supplied `plugin` fields are ignored. A page served under `/p/pluginA/*` cannot write events to `/p/pluginB/state/events`. |
| SR-6 | Path components for `/vk/<bundle>.js` and `/p/<plugin>/<surface-id>` match `^[a-zA-Z0-9_-]+$`. After resolving to an absolute path, the server verifies containment in the declared root via a startsWith check and rejects symlinks via `lstat`. |
| SR-7 | All bundled dependencies (Lit, KaTeX, Chart.js, CodeMirror 6, etc.) are pinned to exact versions in the visual-kit lockfile, loaded only from `/vk/*` (never a CDN at runtime), and referenced with SRI hashes in rendered HTML. |
| SR-8 | `POST /events` enforces `Content-Type: application/json`, a 64 KB body cap, JSON schema validation via ajv, and a 50 MB rotating cap on `state/events`. |
| SR-9 | `GET /vk/*` serves only files rooted in `${CLAUDE_PLUGIN_ROOT}/dist/`. `GET /p/<plugin>/*` serves only files rooted in the consumer's `<workspace>/.<plugin>/content/`. Symlinks are refused. |
| SR-10 | Error bodies are generic (`400`, `403`, `404`, `413`, `421`, `500`). Detailed errors go to a mode-0600 log under `.visual-kit/logs/` in the workspace. |

---

## 5. Architecture

### 5.1 Plugin distribution

`visual-kit` is a first-class Claude Code plugin in the same marketplace as its consumers.

**Declared dependency** — consumer plugins add to their `plugin.json`:

```json
{
  "name": "paidagogos",
  "version": "0.2.0",
  "dependencies": [
    { "name": "visual-kit", "version": "~1.0.0" }
  ]
}
```

Claude Code auto-resolves `visual-kit` against marketplace git tags matching `visual-kit--v1.0.*`, installs it at `~/.claude/plugins/cache/visual-kit-<marketplace>-<version>/`, and adds `bin/visual-kit` to the PATH available to Bash tool calls.

### 5.2 Server lifecycle

**One server per workspace.** A workspace is identified by the absolute path of the directory containing `.claude-plugin/` (or, for monorepos, the Claude Code project root).

**Startup.** Any consumer skill (or the user) invokes:

```bash
visual-kit serve --project-dir "$PROJECT_ROOT" [--host 127.0.0.1] [--url-host localhost]
```

Invocation steps (executed idempotently):

1. Compute the target port from `sha256(project_dir_absolute)` modulo the ephemeral range, offset to `[20000, 60000]`.
2. Attempt to open an advisory file lock at `<project-dir>/.visual-kit/server/state/server.lock` (via `flock` where available, fall back to atomic lock-file create on platforms without `flock`).
3. Read `<project-dir>/.visual-kit/server/state/server-info` if present and PID is alive (`kill -0` probe). If the server is already running, print its JSON info and exit 0. This makes invocations idempotent.
4. If the port is occupied by an unrelated process, auto-increment up to ten times and re-probe.
5. Bind, write `server-info` atomically (`tmp + rename`), release the lock.
6. Register a SIGTERM/SIGINT handler that removes `server-info` and writes a `server-stopped` marker.

**Server-info schema** (`.visual-kit/server/state/server-info`):

```json
{
  "status": "running",
  "pid": 12345,
  "port": 34287,
  "host": "127.0.0.1",
  "url": "http://localhost:34287",
  "started_at": "2026-04-17T09:14:22Z",
  "project_dir": "/Users/.../claude-plugins",
  "visual_kit_version": "1.0.0"
}
```

**Inactivity timeout.** 30 minutes of no HTTP traffic and no content-dir modifications. Timeout resets on every request or content write. On timeout, server removes `server-info` and writes `server-stopped`.

**Stop.** `visual-kit stop` signals the pid from `server-info`. `visual-kit status` prints the info or "not running."

### 5.3 URL namespacing

```
GET  /                             — redirect to /vk/welcome (V1 placeholder)
GET  /vk/capabilities              — JSON: schema versions, surfaces, components
GET  /vk/core.js                   — core component bundle
GET  /vk/<bundle>.js               — lazy bundle (chart.js, math.js, code.js, ...)
GET  /vk/static/<file>             — bundled CSS, fonts, images
GET  /p/<plugin>/<surface-id>      — rendered HTML for a SurfaceSpec
GET  /p/<plugin>/<surface-id>/data — raw SurfaceSpec JSON (for debugging)
GET  /events/stream                — SSE for auto-reload
POST /events                       — consumer-side event capture
```

`<plugin>` and `<surface-id>` match `^[a-zA-Z0-9_-]+$`.

**Resolution.** The server watches `<project-dir>/.<plugin>/content/` for each declared consumer. The file `<surface-id>.json` at that path backs `/p/<plugin>/<surface-id>`. A consumer that has not yet written any file returns a `404` with a friendly "waiting for SurfaceSpec" page.

### 5.4 SurfaceSpec JSON contract

Every SurfaceSpec carries a version and a surface type:

```json
{
  "surface": "lesson" | "gallery" | "outline" | "comparison" | "feedback" | "free",
  "version": 1,
  ...surface-specific fields
}
```

The server validates the envelope, routes to the surface renderer, and emits a lit-html-rendered fragment wrapped in the security shell (CSP, nonce, CSRF meta).

**Additive evolution.** Unknown top-level fields are dropped during validation. Unknown `surface` values return a typed `vk-error` fragment describing the missing surface and linking to `/vk/capabilities`.

**Schema storage.** Per-surface JSON schemas live at `plugins/visual-kit/schemas/surfaces/<name>.v1.json`, shipped with the plugin and served at `/vk/schemas/<name>.v1.json` for consumer validation.

### 5.5 Component bundles

**Layout.**

```
plugins/visual-kit/dist/
├── core.js                  ← Lit runtime, theme, layout primitives (~35 KB gz)
├── chart.js                 ← Chart.js wrapped in <vk-chart>
├── math.js                  ← KaTeX wrapped in <vk-math>
├── code.js                  ← Prism for static, CodeMirror 6 for interactive
├── geometry.js              ← JSXGraph
├── sim-2d.js                ← Matter.js
├── audio.js                 ← Tone.js + Wavesurfer.js
├── quiz.js                  ← <vk-quiz>, <vk-hint>, <vk-explain>
├── progress.js              ← <vk-progress>, <vk-streak>
├── 3d.js                    ← (V1.1) Three.js
├── python.js                ← (V1.1) Pyodide
└── sandbox.js               ← (V1.1) Sandpack
```

**Autoloader.** The server inspects the rendered fragment, finds every `<vk-*>` tag, and emits `<link rel="modulepreload">` and `<script type="module">` references for the required bundles in the page head. Bundles are registered via `customElements.define` on import; components render as soon as their bundle loads. A `<vk-loader>` placeholder element shows progress while a bundle is in flight.

**Versioning.** Bundles are content-hashed in filenames at release (`core.js` → `core-5e71.js` in production), with the `visual-kit--v1.0.0` tag in git identifying the manifest.

### 5.6 Events & CSRF

**Flow.** A `<vk-quiz>` component emits a `vk-event` CustomEvent on answer selection. A small shell script attached in the page template captures these events and posts them:

```http
POST /events HTTP/1.1
Content-Type: application/json
X-Vk-Csrf: <token-from-meta>

{
  "surface": "lesson",
  "type": "quiz_answer",
  "qi": 1,
  "chosen": "flex-direction: column",
  "correct": "flex-direction: row",
  "ts": "2026-04-17T09:22:14Z"
}
```

**Server handling.**

1. Verify `X-Vk-Csrf` matches the token bound to the page's `<plugin, surface-id, nonce>` triple.
2. Resolve `<plugin>` from the Referer path (or Origin). Body-supplied plugin fields are ignored.
3. Validate body against the event schema.
4. Append as a single JSON line to `<project-dir>/.<plugin>/state/events`. Rotate at 50 MB.
5. Return `204 No Content`.

**Consumer read pattern.** The consumer skill opens `.<plugin>/state/events` in append-only mode, seeks to its last-read offset (stored in the skill's local workspace), and parses new lines.

### 5.7 Security model

#### 5.7.1 Threat model

| Actor | Capability | Intent |
|-------|-----------|--------|
| Developer | Trusted — the user of the plugin. | Legitimate use. |
| LLM | Semi-trusted — generates SurfaceSpec content, including strings. | Can be prompt-injected; may produce malicious HTML/attribute values. |
| Consumer plugin author | Semi-trusted — ships code that can write SurfaceSpec JSON. | Can accidentally or maliciously emit crafted JSON. |
| Remote website in the developer's browser | Untrusted. | May attempt DNS rebinding to reach `localhost:<port>`. |

#### 5.7.2 Controls

| Risk | Control |
|------|---------|
| XSS via attribute injection | lit-html SSR escapes attribute and text contexts by default. Complex props pass via sibling `<script type="application/json">`, never as attributes. No string-concat rendering anywhere. (AR-8, SR-3) |
| XSS via `free` surface | Strict CSP (`script-src 'self' 'nonce-X'`) prevents inline script execution regardless of fragment content. `free` content renders into a DOM that cannot execute injected scripts. (SR-3) |
| Cross-plugin event writes | Plugin derived server-side from Referer/Origin; body-supplied plugin ignored; CSRF token bound to `<plugin, surface-id, nonce>`. (SR-4, SR-5) |
| Path traversal | Input regex, realpath containment, symlink rejection. (SR-6, SR-9) |
| DNS rebinding | Host-header allowlist; `Origin` check on `POST /events`. (SR-2) |
| Accidental LAN exposure | Default bind 127.0.0.1; explicit stderr warning if bound to non-loopback. (SR-1) |
| Supply-chain compromise of bundled deps | Pinned lockfile, SRI on all script tags, no runtime CDN. (SR-7) |
| DoS via large events | Body cap, content-type check, schema validation, event-log rotation. (SR-8) |
| Info disclosure via errors | Generic responses; detailed log in mode-0600 file. (SR-10) |

#### 5.7.3 CSP

Default policy on every rendered page:

```
Content-Security-Policy:
  default-src 'none';
  script-src  'self' 'nonce-<random>';
  style-src   'self' 'nonce-<random>';
  img-src     'self' data:;
  connect-src 'self';
  font-src    'self' data:;
  frame-ancestors 'none';
  base-uri 'none';
  form-action 'none';
```

Per-surface relaxations (declared in the surface schema, applied server-side):

| Surface/component | Relaxation | Reason |
|------|-----------|--------|
| `<vk-python>` (V1.1) | `script-src 'wasm-unsafe-eval'` | Pyodide needs wasm compilation |
| `<vk-sandbox>` (V1.1) | `child-src 'self'`, sandboxed iframe | Sandpack runs user JS in an iframe |

#### 5.7.4 Accompanying headers

```
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Vary: Origin
```

### 5.8 Version compatibility

**`GET /vk/capabilities`** returns:

```json
{
  "visual_kit_version": "1.0.0",
  "schema_version": 1,
  "surfaces": {
    "lesson":     { "schema": "/vk/schemas/lesson.v1.json" },
    "gallery":    { "schema": "/vk/schemas/gallery.v1.json" },
    "outline":    { "schema": "/vk/schemas/outline.v1.json" },
    "comparison": { "schema": "/vk/schemas/comparison.v1.json" },
    "feedback":   { "schema": "/vk/schemas/feedback.v1.json" },
    "free":       { "schema": "/vk/schemas/free.v1.json" }
  },
  "components": [
    "vk-section","vk-card","vk-gallery","vk-outline","vk-comparison","vk-feedback",
    "vk-loader","vk-error",
    "vk-code","vk-math","vk-chart","vk-geometry","vk-sim-2d","vk-audio",
    "vk-quiz","vk-hint","vk-explain","vk-progress","vk-streak"
  ],
  "bundles": [
    { "name": "core",     "url": "/vk/core.js",     "sri": "sha384-..." },
    { "name": "chart",    "url": "/vk/chart.js",    "sri": "sha384-..." }
  ]
}
```

Consumers with version pinning that fails validation (schema absent, component absent) emit a clear terminal error and do not proceed.

---

## 6. Surfaces (V1)

Each surface is a JSON shape + a lit-html template + a documented component composition. Schemas live at `plugins/visual-kit/schemas/surfaces/<name>.v1.json`.

### 6.1 `lesson`

Current paidagogos lesson, generalized.

```json
{
  "surface": "lesson",
  "version": 1,
  "topic": "CSS Flexbox",
  "level": "beginner" | "intermediate" | "advanced",
  "estimated_minutes": 12,
  "sections": [
    { "type": "concept",     "text": "..." },
    { "type": "why",         "text": "..." },
    { "type": "code",        "language": "css", "source": "..." },
    { "type": "chart",       "config": { ...Chart.js config... } },
    { "type": "math",        "latex": "..." },
    { "type": "mistakes",    "items": ["..."] },
    { "type": "generate",    "task": "..." },
    { "type": "quiz",        "items": [ ... ] },
    { "type": "resources",   "items": [ ... ] },
    { "type": "next",        "concept": "..." }
  ],
  "caveat": "AI-generated — verify against official docs."
}
```

Components used: `<vk-section>`, `<vk-code>`, `<vk-chart>`, `<vk-math>`, `<vk-quiz>`.

### 6.2 `gallery`

Showcase of items with optional multiselect.

```json
{
  "surface": "gallery",
  "version": 1,
  "title": "Wave 1 candidates",
  "multiselect": true,
  "items": [
    {
      "id": "softlight-io",
      "title": "softlight.io",
      "subtitle": "calm + technical",
      "badges": [{ "label": "available", "tone": "ok" }, { "label": "$12/yr" }],
      "body": "Descriptive sentence or two."
    }
  ]
}
```

Components: `<vk-gallery>`, `<vk-card>`. Click emits `vk-event` → `{ type: "select" | "deselect", id: "softlight-io" }`.

### 6.3 `outline`

Hierarchical structural preview.

```json
{
  "surface": "outline",
  "version": 1,
  "title": "Proposed post structure",
  "nodes": [
    {
      "heading": "Hook",
      "summary": "Opening sentence idea.",
      "children": []
    }
  ]
}
```

Components: `<vk-outline>`, `<vk-section>`.

### 6.4 `comparison`

Side-by-side variants.

```json
{
  "surface": "comparison",
  "version": 1,
  "title": "Two structures",
  "variants": [
    { "label": "Story-led",   "body": { "surface": "outline", ... } },
    { "label": "Argument-led", "body": { "surface": "outline", ... } }
  ]
}
```

Each `body` is a nested SurfaceSpec. The comparison surface renders them side-by-side with a selection control. Click → `vk-event` `{ type: "variant-chosen", label: "Story-led" }`.

### 6.5 `feedback`

Structured input form (short questions).

```json
{
  "surface": "feedback",
  "version": 1,
  "title": "Which direction fits?",
  "fields": [
    { "type": "choice", "id": "tone",   "prompt": "Tone?", "options": [ "warm", "crisp", "technical" ] },
    { "type": "text",   "id": "notes",  "prompt": "Anything else?" }
  ],
  "submit_label": "Send to Claude"
}
```

Submit emits `vk-event` `{ type: "feedback", fields: { tone: "warm", notes: "..." } }`.

### 6.6 `free`

Raw HTML fragment. Escape hatch for layouts no other surface fits.

```json
{
  "surface": "free",
  "version": 1,
  "html": "<vk-section title='Custom'><p>…</p></vk-section>"
}
```

**Security note.** Because the page-level CSP (`default-src 'none'; script-src 'self' 'nonce-X'`) forbids inline script, `free` content cannot execute JS even when malicious. The server additionally strips attributes matching `^on[a-z]+$`, `javascript:` URLs, and `<script>` tags at render time via DOMPurify (server-side, via jsdom). This is defense in depth, not the primary control.

---

## 7. Components (V1)

All `<vk-*>`. All **pure**: data in via attributes/slotted content, events out via `CustomEvent` dispatched with `bubbles: true, composed: true`. No `fetch`, no `localStorage`, no state reads from outside the component tree.

| Tag | Bundle | Purpose |
|-----|--------|---------|
| `<vk-section>` | core | Titled content block; supports slotted children. |
| `<vk-card>` | core | Selectable card. `data-selected`, `data-id`. |
| `<vk-gallery>` | core | Grid layout, optional multiselect orchestration. |
| `<vk-outline>` | core | Tree layout with expand/collapse. |
| `<vk-comparison>` | core | Two-column layout with selection bar. |
| `<vk-feedback>` | core | Form primitive with built-in submit flow. |
| `<vk-loader>` | core | Placeholder shown while a bundle loads. |
| `<vk-error>` | core | Typed error fragment (unknown surface, schema failure). |
| `<vk-code>` | code | Syntax-highlighted block (static) or editable surface (CodeMirror 6). |
| `<vk-math>` | math | Inline/block KaTeX. |
| `<vk-chart>` | chart | Chart.js with supported types. |
| `<vk-geometry>` | geometry | Interactive geometry (JSXGraph). |
| `<vk-sim-2d>` | sim-2d | 2D physics sandbox (Matter.js). |
| `<vk-audio>` | audio | Tone.js synth / Wavesurfer waveform. |
| `<vk-quiz>` | quiz | Multiple-choice, fill-blank, explain. Emits `answer`, `reveal`. |
| `<vk-hint>` | quiz | Progressive hints (nudge → clue → answer). |
| `<vk-explain>` | quiz | Free-text explain-back; emits submission for skill-side evaluation. |
| `<vk-progress>` | progress | Current / total / next indicator. |
| `<vk-streak>` | progress | Streak badge with goal indicator. |

### 7.1 Purity enforcement

A CI step runs a static lint over `plugins/visual-kit/src/components/*.ts`:

- Rejects `fetch(`, `XMLHttpRequest`, `new URL(.*, document.location)`.
- Rejects `localStorage.`, `sessionStorage.`, `IndexedDB.`, `navigator.serviceWorker`.
- Rejects `import(.*)` of anything outside the component's own dependency whitelist.

A passing component is one whose behavior is fully determined by attributes, slotted markup, and emitted events.

---

## 8. Consumer migration plans

### 8.1 paidagogos

**Before.** `plugins/paidagogos/server/` contains `server.js`, `start-server.sh`, `templates/lesson.html`. The skill writes `lesson-*.json` to `.paidagogos/server/content/`.

**After.**

1. Add `"dependencies": [{ "name": "visual-kit", "version": "~1.0.0" }]` to `plugins/paidagogos/.claude-plugin/plugin.json`.
2. Delete `plugins/paidagogos/server/` entirely.
3. Update `plugins/paidagogos/skills/paidagogos-micro/SKILL.md`:
   - Pre-flight reads `.visual-kit/server/state/server-info` (instead of `.paidagogos/server/state/server-info`).
   - If missing, skill prints: "Run `visual-kit serve --project-dir .` or `/paidagogos:serve` to start the visual server, then retry."
   - Skill writes SurfaceSpec `lesson` JSON to `.paidagogos/content/lesson.json`. The topic slug may be reflected in the filename (`flexbox.json`) for multi-lesson workflows.
4. Add a thin `/paidagogos:serve` skill that shells out to `visual-kit serve --project-dir $PROJECT_DIR` for user convenience. This is optional once visual-kit is stable.
5. Update `plugins/paidagogos/docs/plugins/paidagogos/architecture.md` to replace the "visual server is owned by paidagogos" section with "visual server is provided by `visual-kit` dependency."

Quiz interactions flow identically: browser emits `vk-event` on answer → `POST /events` → `.paidagogos/state/events` JSON lines → skill reads next session or later.

### 8.2 namesmith

**Before.** `site-naming` writes `names.md` at the project root.

**After.**

1. Add `visual-kit` as a dependency in `plugins/namesmith/.claude-plugin/plugin.json`.
2. During the name-generation wave flow, after each Wave's availability check completes, the skill writes a `gallery` SurfaceSpec to `.namesmith/content/wave-<n>.json`.
3. User opens `http://localhost:<port>/p/namesmith/wave-<n>`, multiselects candidates.
4. `.namesmith/state/events` records the selections.
5. Skill reads events when the user signals readiness (terminal message "continue"), generates the final `names.md` shortlist from the selected set.

The `names.md` artifact remains — it is the durable output. The gallery is an interactive layer on top of the same data.

### 8.3 draftloom

**Before.** `draftloom:draft` writes a `draft.md` and lots of eval JSON.

**After.**

1. Add `visual-kit` as a dependency in `plugins/draftloom/.claude-plugin/plugin.json`.
2. At the outline stage, the orchestrator writes a `comparison` SurfaceSpec with two variant outlines (e.g., story-led vs argument-led) to `.draftloom/content/structure.json`.
3. User clicks the preferred variant at `http://localhost:<port>/p/draftloom/structure`.
4. Orchestrator reads `.draftloom/state/events`, proceeds with the selected variant.
5. Post-draft, the orchestrator may write a `feedback` SurfaceSpec to collect quick ratings on sections that scored low in evals.

`draft.md` remains the durable output.

### 8.4 Future consumers

**beacon** — could use `outline` to preview discovered site structure before the full `INDEX.md` is written. Not in V1 scope.

**Any plugin** — can consume visual-kit by adding the dependency and writing SurfaceSpec JSON. No changes to visual-kit required for a new consumer unless it needs a new surface.

---

## 9. Testing strategy

### 9.1 Unit tests

- JSON schema validation (ajv-based) for every surface × version.
- Every `<vk-*>` component: attribute → DOM assertion, event emission assertion.
- Pure-component lint (CI gate).

### 9.2 Integration tests

- Server startup: lock acquisition, port selection, server-info rename atomicity.
- End-to-end: write a SurfaceSpec JSON, fetch the rendered page via `fetch('http://127.0.0.1:<port>/p/test/demo')`, assert fragment structure and CSP header.
- CSRF flow: post an event without token (expect 403), with wrong token (expect 403), with valid token (expect 204 and append to events file).
- DNS rebinding: request with Host header `attacker.example` (expect 421).
- Path traversal: request `/vk/%2e%2e%2fetc%2fpasswd` (expect 400).
- Multi-session: start two workspaces concurrently, assert both servers bind different ports and write separate server-info files.

### 9.3 Gherkin acceptance tests

`docs/plugins/visual-kit/specs/` carries `.feature` files aligned with the existing repo pattern:

- `server-lifecycle.feature` — start, stop, status, idempotency, port auto-increment, inactivity.
- `surface-rendering.feature` — each V1 surface + validation failures.
- `events-and-csrf.feature` — event capture, CSRF, cross-plugin isolation.
- `security-hardening.feature` — CSP, Host allowlist, path guards.
- `capabilities-and-versioning.feature` — graceful degradation.
- `migration-*.feature` — one per consumer (paidagogos, namesmith, draftloom).

### 9.4 Performance

- `core.js` bundle size gated in CI (`≤ 40 KB gzipped`).
- First-paint latency measured via Playwright trace on each release.

---

## 10. Deferred work

### 10.1 V1.1 (next minor)

- Heavy bundles: `3d.js` (Three.js), `python.js` (Pyodide with `<vk-loader>` during runtime boot), `sandbox.js` (Sandpack in sandboxed iframe).
- Additional surface: `dashboard` (grid of live-updating panels) — motivated by real beacon/monitor demand.
- CI-verified SRI attestation pipeline with SBOM.

### 10.2 V2

- `visual-kit:renderer` agent — a thin LLM translator. Consumer skills dispatch `Task(agent="visual-kit:renderer", prompt="Show a gallery of the top 5 candidates from names.md")`. The agent emits a SurfaceSpec JSON that goes through the same validated renderer.

### 10.3 V3

- MCP-UI `UIResource` output. visual-kit gains an MCP server that wraps the same surfaces as UIResources. Claude Desktop and claude.ai render them inline. Claude Code CLI continues to use the local HTTP path.
- At this point, the dual-mode forward-compat goal (AR-5) is realized.

---

## 11. Open questions

1. **Shared browser state across surfaces.** When a user is on `/p/paidagogos/lesson` and opens a new tab at `/p/namesmith/wave-1`, they're in the same origin (`localhost:<port>`). Should anything persist between tabs (selections, theme), or is isolation the default? **Recommendation:** isolation by default; V1 has no shared client state.

2. **Workspace identity in Codespaces / Dev Containers.** The per-workspace port derivation uses the absolute path of the project root. In a Codespace, this is typically `/workspaces/<repo>` — stable across sessions. Confirm this holds for JetBrains Gateway and SSH dev-container scenarios.

3. **Component evolution with schema-breaking changes.** If `<vk-quiz>` V2 changes its `items[].type` enum, do we ship a separate bundle (`quiz2.js`) or force a visual-kit major version? **Recommendation:** major version. Surfaces and components share the visual-kit semver line.

4. **Consumer-authored components.** A future consumer (e.g., paidagogos V2.2) may want a domain-specific component (`<learn-mastery-gauge>` reading its own prefs). Where does this ship? **Recommendation:** in the consumer plugin, registered at runtime via a dedicated "extension bundle" endpoint visual-kit exposes (deferred; not in V1). For V1, consumer plugins compose existing `<vk-*>` components only.

5. **Fallback when server is unreachable.** Default: consumer skill prints a clear error and halts. Should we offer a "terminal fallback" rendering some minimal portion of the surface? **Recommendation:** no. Two render paths are two maintenance surfaces (this is already the paidagogos decision — see `DECISIONS.md` of that plugin).

---

## 12. References

### 12.1 Anthropic documentation

- [Plugins reference](https://code.claude.com/docs/en/plugins-reference) — manifest schema, CLAUDE_PLUGIN_ROOT, symlink/traversal policy.
- [Plugin dependencies](https://code.claude.com/docs/en/plugin-dependencies) — `dependencies[]`, semver constraints, tag conventions.
- [MCP Apps / MCP-UI](https://modelcontextprotocol.io/extensions/apps/overview) — UIResource protocol (deferred V3 target).

### 12.2 Repo sources

- `docs/plugins/paidagogos/research/rendering-and-pedagogy.md` — component taxonomy and bundle tiers that inform visual-kit's component list.
- `docs/superpowers/specs/2026-04-15-learn-v2-design.md` — the V2 paidagogos spec that visual-kit supersedes in scope.
- `plugins/paidagogos/server/` — the 150-line server this spec extracts and generalizes.
- `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/brainstorming/scripts/` — precedent for `--host` / `--url-host` separation, SSE auto-reload, and content-fragment pattern.

### 12.3 Bundled dependencies (V1)

| Library | Version pinned | License | Role |
|---------|----------------|---------|------|
| Lit | 3.x | BSD-3 | Core component runtime |
| KaTeX | latest V1 compatible | MIT | Math rendering |
| Chart.js | 4.x | MIT | Charts |
| CodeMirror 6 | 6.x | MIT | Editable code |
| Prism | 1.x | MIT | Static code highlighting |
| JSXGraph | 1.x | LGPL-3 | Interactive geometry |
| Matter.js | 0.x | MIT | 2D physics |
| Tone.js | 14.x | MIT | Audio synthesis |
| Wavesurfer.js | 7.x | BSD-3 | Waveform display |
| DOMPurify | 3.x | Apache-2 OR MPL-2 | Server-side `free` sanitizer |

Exact versions live in `plugins/visual-kit/package.json` (committed lockfile).

---

## 13. Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-04-17 | Claude Opus 4.7 (with Georgios Pilitsoglou) | Initial draft, incorporating architectural review, security audit, and contrarian review. |
