# visual-kit `free-interactive` surface — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in surface kind `free-interactive` to visual-kit that serves AI-authored HTML+JS on the local server without sanitisation or CSP, matching superpowers' trust model. Existing strict surfaces are untouched.

**Architecture:** New surface kind with its own JSON schema. The HTTP handler detects `spec.surface === 'free-interactive'` after schema validation and short-circuits: no `buildShell`, no CSP header, no CSRF, no sanitiser. A tiny reload `<script>` is injected before `</body>` so SSE auto-reload still works. Host-allowlist, loopback binding, path traversal protection, and the always-on security headers still apply.

**Tech Stack:** TypeScript (Node ≥ 20), Vitest, Ajv 2020-12, Lit (unchanged — new surface does not use Lit).

**Spec:** `docs/superpowers/specs/2026-04-19-visual-kit-free-interactive-surface.md`

**Working directory for every command:** `plugins/visual-kit/`. All `pnpm` invocations run from there. File paths in this plan are relative to the repo root.

---

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `plugins/visual-kit/schemas/surfaces/free-interactive.v1.json` | JSON Schema for the new surface kind |
| `plugins/visual-kit/src/surfaces/free-interactive.ts` | `renderFreeInteractive(spec)` and `injectReloadScript(html)` — pure functions, no Lit, no DOM |
| `plugins/visual-kit/tests/unit/free-interactive.test.ts` | Unit tests for the pure functions + schema validation |
| `plugins/visual-kit/tests/integration/free-interactive-serve.test.ts` | End-to-end test: spawn the server, hit a `free-interactive` surface, assert no CSP + script preserved. Includes regression guard for strict surfaces. |

### Modified files

| Path | Change |
|---|---|
| `plugins/visual-kit/src/shared/types.ts` | Extend `SurfaceKind` union |
| `plugins/visual-kit/src/render/validate.ts` | Add `'free-interactive'` to `KINDS` so the validator loads the new schema |
| `plugins/visual-kit/src/server/index.ts` | After `validateSpec`, short-circuit for `free-interactive` — bypass `buildShell` |
| `plugins/visual-kit/src/server/capabilities.ts` | Advertise the surface with a `permissive: true` flag |
| `plugins/visual-kit/package.json` | Version bump `1.0.0` → `1.1.0` |
| `plugins/visual-kit/CHANGELOG.md` | Add v1.1.0 entry with explicit security disclosure |

The surface is **NOT registered** in `src/surfaces/index.ts` — routing lives in the server handler because the renderer returns a string, not a Lit `TemplateResult`. This is explicit and grep-findable.

---

## Pre-flight

- [ ] **Step 0.1: Confirm you're in the repo**

Run:
```bash
pwd && git rev-parse --abbrev-ref HEAD
```

Expected output ends with `/claude-plugins` and prints a branch name. You should NOT be on `main`. If you are on `main`, stop and create a feature branch:

```bash
git switch -c feat/visual-kit-v1.1-free-interactive
```

- [ ] **Step 0.2: Confirm visual-kit installs and tests pass on a clean baseline**

Run:
```bash
cd plugins/visual-kit && pnpm install && pnpm test 2>&1 | tail -20
```

Expected output: "Test Files  N passed" with no failures. If this fails, stop and fix the baseline before proceeding.

- [ ] **Step 0.3: Note the current test count**

Run:
```bash
cd plugins/visual-kit && pnpm test 2>&1 | grep -E "Tests.*passed" | tail -1
```

Write the number down. At the end of the plan we verify we've only ADDED tests, none broke.

---

## Task 1: Extend `SurfaceKind` union

**Files:**
- Modify: `plugins/visual-kit/src/shared/types.ts:1-2`
- Test: `plugins/visual-kit/tests/unit/types.test.ts` (new, minimal)

Goal: add `'free-interactive'` to the union so downstream code that pattern-matches on `SurfaceKind` covers the new kind.

- [ ] **Step 1.1: Write the failing test**

Create `plugins/visual-kit/tests/unit/types.test.ts`:

```typescript
import { describe, it, expectTypeOf } from 'vitest';
import type { SurfaceKind } from '../../src/shared/types.js';

describe('SurfaceKind', () => {
  it('includes free-interactive', () => {
    expectTypeOf<'free-interactive'>().toMatchTypeOf<SurfaceKind>();
  });

  it('still includes the existing kinds', () => {
    expectTypeOf<'lesson'>().toMatchTypeOf<SurfaceKind>();
    expectTypeOf<'free'>().toMatchTypeOf<SurfaceKind>();
    expectTypeOf<'outline'>().toMatchTypeOf<SurfaceKind>();
  });
});
```

- [ ] **Step 1.2: Run the test to verify it fails**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/types.test.ts 2>&1 | tail -20
```

Expected: FAIL. The `expectTypeOf<'free-interactive'>()` assertion will emit a type error because `'free-interactive'` is not assignable to `SurfaceKind`.

- [ ] **Step 1.3: Extend the union**

Replace the contents of `plugins/visual-kit/src/shared/types.ts`:

```typescript
export type SurfaceKind =
  | 'lesson' | 'gallery' | 'outline' | 'comparison' | 'feedback' | 'free'
  | 'free-interactive';

export interface SurfaceSpecBase {
  surface: SurfaceKind;
  version: number;
}

export interface ServerInfo {
  status: 'running';
  pid: number;
  port: number;
  host: string;
  url: string;
  started_at: string; // ISO 8601
  project_dir: string;
  visual_kit_version: string;
}

export interface VkEvent {
  type: string;
  ts: string;
  [key: string]: unknown;
}
```

- [ ] **Step 1.4: Run the test to verify it passes**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/types.test.ts 2>&1 | tail -10
```

Expected: PASS, all three assertions green.

- [ ] **Step 1.5: Commit**

```bash
git add plugins/visual-kit/src/shared/types.ts plugins/visual-kit/tests/unit/types.test.ts
git commit -m "$(cat <<'EOF'
feat(visual-kit): add free-interactive to SurfaceKind union

First step toward the v1.1 opt-in permissive surface. No behaviour
change yet — just extends the type.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: JSON schema for `free-interactive`

**Files:**
- Create: `plugins/visual-kit/schemas/surfaces/free-interactive.v1.json`
- Test: tests come in Task 3 (the schema only becomes testable once the validator registers it).

- [ ] **Step 2.1: Create the schema file**

Write `plugins/visual-kit/schemas/surfaces/free-interactive.v1.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/free-interactive.v1.json",
  "title": "FreeInteractiveSurfaceV1",
  "description": "Permissive surface: arbitrary AI-authored HTML+JS served as-is. No sanitisation, no CSP. Localhost-only trust model.",
  "type": "object",
  "required": ["surface", "version", "html"],
  "additionalProperties": false,
  "properties": {
    "surface": { "const": "free-interactive" },
    "version": { "const": 1 },
    "html":  { "type": "string", "maxLength": 500000 },
    "title": { "type": "string", "maxLength": 200 }
  }
}
```

- [ ] **Step 2.2: Verify the JSON parses**

Run:
```bash
cd plugins/visual-kit && node -e "JSON.parse(require('fs').readFileSync('schemas/surfaces/free-interactive.v1.json','utf8'));console.log('ok')"
```

Expected output: `ok`

- [ ] **Step 2.3: Commit**

```bash
git add plugins/visual-kit/schemas/surfaces/free-interactive.v1.json
git commit -m "$(cat <<'EOF'
feat(visual-kit): add free-interactive.v1 JSON schema

Defines the opt-in permissive surface contract. Enforced in the next
task when the validator registers this kind.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Register schema + validator tests

**Files:**
- Modify: `plugins/visual-kit/src/render/validate.ts:31`
- Create: `plugins/visual-kit/tests/unit/free-interactive-schema.test.ts`

- [ ] **Step 3.1: Write the failing test**

Create `plugins/visual-kit/tests/unit/free-interactive-schema.test.ts`:

```typescript
import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';

describe('free-interactive schema validation', () => {
  beforeAll(async () => {
    await loadSchemas();
  });

  it('accepts a minimal valid spec', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body>hi</body></html>',
    };
    const res = validateSpec(spec);
    expect(res).toEqual({ ok: true, kind: 'free-interactive' });
  });

  it('accepts a spec with optional title', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      title: 'Parabola',
      html: '<div>inline</div>',
    };
    expect(validateSpec(spec).ok).toBe(true);
  });

  it('rejects missing html', () => {
    const spec = { surface: 'free-interactive', version: 1 };
    const res = validateSpec(spec);
    expect(res.ok).toBe(false);
  });

  it('rejects wrong surface value', () => {
    const spec = { surface: 'free-interactive-bogus', version: 1, html: 'x' };
    expect(validateSpec(spec).ok).toBe(false);
  });

  it('rejects wrong version', () => {
    const spec = { surface: 'free-interactive', version: 2, html: 'x' };
    expect(validateSpec(spec).ok).toBe(false);
  });

  it('rejects html over the 500 KB ceiling', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: 'x'.repeat(500_001),
    };
    const res = validateSpec(spec);
    expect(res.ok).toBe(false);
  });

  it('rejects extra properties', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: 'ok',
      rogue: 'nope',
    };
    expect(validateSpec(spec).ok).toBe(false);
  });
});
```

- [ ] **Step 3.2: Run the test to verify it fails**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/free-interactive-schema.test.ts 2>&1 | tail -25
```

Expected: FAIL. `validateSpec` returns `{ ok: false, errors: ['unknown surface: free-interactive'] }` because the validator doesn't know about the new kind.

- [ ] **Step 3.3: Register the new kind in the validator**

Replace line 31 in `plugins/visual-kit/src/render/validate.ts`:

```typescript
const KINDS: SurfaceKind[] = ['lesson', 'gallery', 'outline', 'comparison', 'feedback', 'free', 'free-interactive'];
```

- [ ] **Step 3.4: Run the test to verify it passes**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/free-interactive-schema.test.ts 2>&1 | tail -10
```

Expected: PASS. All seven assertions green.

- [ ] **Step 3.5: Run the full test suite as a regression guard**

Run:
```bash
cd plugins/visual-kit && pnpm test 2>&1 | tail -15
```

Expected: every previous test still passes. Count of total tests has increased by 7 (the new ones).

- [ ] **Step 3.6: Commit**

```bash
git add plugins/visual-kit/src/render/validate.ts plugins/visual-kit/tests/unit/free-interactive-schema.test.ts
git commit -m "$(cat <<'EOF'
feat(visual-kit): register free-interactive validator

Schema now enforces the contract: html required (≤500 KB), no extra
properties, version must be 1. All existing surface validators are
unaffected.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Pure renderer module

**Files:**
- Create: `plugins/visual-kit/src/surfaces/free-interactive.ts`
- Create: `plugins/visual-kit/tests/unit/free-interactive.test.ts`

These are pure functions — no DOM, no Lit, no network, no disk. Unit-testable in isolation.

- [ ] **Step 4.1: Write the failing test**

Create `plugins/visual-kit/tests/unit/free-interactive.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { renderFreeInteractive, injectReloadScript } from '../../src/surfaces/free-interactive.js';

describe('injectReloadScript', () => {
  it('inserts the reload script immediately before </body>', () => {
    const input = '<html><body><p>hi</p></body></html>';
    const out = injectReloadScript(input);
    const idx = out.indexOf("new EventSource('/events/stream')");
    const bodyEnd = out.indexOf('</body>');
    expect(idx).toBeGreaterThan(-1);
    expect(bodyEnd).toBeGreaterThan(idx);
    expect(out.indexOf('<p>hi</p>')).toBeLessThan(idx);
  });

  it('appends the reload script at the end if </body> is absent', () => {
    const input = '<div>fragment</div>';
    const out = injectReloadScript(input);
    expect(out.startsWith('<div>fragment</div>')).toBe(true);
    expect(out).toContain("new EventSource('/events/stream')");
    expect(out).toContain('location.reload()');
  });

  it('injects at the LAST </body> when multiple exist', () => {
    // A pathological case: AI nests an iframe srcdoc containing </body>.
    // We must inject before the outer </body>, not the inner one.
    const input =
      '<html><body><iframe srcdoc="<body>inner</body>"></iframe></body></html>';
    const out = injectReloadScript(input);
    const scriptIdx = out.indexOf("new EventSource('/events/stream')");
    const lastBodyEnd = out.lastIndexOf('</body>');
    expect(scriptIdx).toBeGreaterThan(-1);
    expect(lastBodyEnd).toBeGreaterThan(scriptIdx);
  });

  it('is case-insensitive about </BODY>', () => {
    const input = '<html><BODY>hi</BODY></html>';
    const out = injectReloadScript(input);
    expect(out).toContain("new EventSource('/events/stream')");
    const scriptIdx = out.indexOf("new EventSource('/events/stream')");
    const bodyEnd = out.toLowerCase().indexOf('</body>');
    expect(bodyEnd).toBeGreaterThan(scriptIdx);
  });
});

describe('renderFreeInteractive', () => {
  it('returns the html with the reload script injected', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body>x</body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('<body>x');
    expect(out).toContain("new EventSource('/events/stream')");
  });

  it('preserves inline <script> verbatim (no sanitisation)', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body><script>window.__marker = 42;</script></body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('<script>window.__marker = 42;</script>');
  });

  it('preserves inline event handlers verbatim', () => {
    const spec = {
      surface: 'free-interactive' as const,
      version: 1 as const,
      html: '<html><body><button onclick="alert(1)">x</button></body></html>',
    };
    const out = renderFreeInteractive(spec);
    expect(out).toContain('onclick="alert(1)"');
  });
});
```

- [ ] **Step 4.2: Run the test to verify it fails**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/free-interactive.test.ts 2>&1 | tail -15
```

Expected: FAIL with import resolution error — the module `src/surfaces/free-interactive.ts` doesn't exist yet.

- [ ] **Step 4.3: Implement the module**

Create `plugins/visual-kit/src/surfaces/free-interactive.ts`:

```typescript
/**
 * free-interactive surface — serves AI-authored HTML+JS as-is.
 *
 * Trust model: localhost-only, AI-trusted, no sanitisation, no CSP.
 * See spec: docs/superpowers/specs/2026-04-19-visual-kit-free-interactive-surface.md
 */

export interface FreeInteractiveSpec {
  surface: 'free-interactive';
  version: 1;
  html: string;
  title?: string;
}

const RELOAD_SCRIPT =
  '<script>(function(){var es=new EventSource(\'/events/stream\');' +
  'es.onmessage=function(e){if(e.data===\'refresh\')location.reload();};})();' +
  '</script>';

/**
 * Inserts the SSE auto-reload script immediately before the last </body>
 * tag in `html`. If no </body> exists (fragment input), appends at the end.
 * Case-insensitive match. The LAST occurrence is used so nested srcdoc
 * payloads don't confuse the injection point.
 */
export function injectReloadScript(html: string): string {
  const re = /<\/body\s*>/gi;
  let lastMatch: RegExpExecArray | null = null;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) lastMatch = m;
  if (!lastMatch) return html + RELOAD_SCRIPT;
  const idx = lastMatch.index;
  return html.slice(0, idx) + RELOAD_SCRIPT + html.slice(idx);
}

/**
 * Renders a free-interactive SurfaceSpec into the final HTML body that the
 * server writes to the response. This is a pure string transform — it does
 * not validate, does not sanitise, does not build a shell.
 */
export function renderFreeInteractive(spec: FreeInteractiveSpec): string {
  return injectReloadScript(spec.html);
}
```

- [ ] **Step 4.4: Run the test to verify it passes**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/unit/free-interactive.test.ts 2>&1 | tail -15
```

Expected: PASS. All 7 assertions green.

- [ ] **Step 4.5: Commit**

```bash
git add plugins/visual-kit/src/surfaces/free-interactive.ts plugins/visual-kit/tests/unit/free-interactive.test.ts
git commit -m "$(cat <<'EOF'
feat(visual-kit): add free-interactive renderer

Pure functions renderFreeInteractive and injectReloadScript. No DOM,
no Lit, no sanitisation. The SSE reload script is spliced in before
the last </body> so nested srcdoc payloads don't shift the injection
point.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Wire the server short-circuit

**Files:**
- Modify: `plugins/visual-kit/src/server/index.ts` — insert a branch after validation, before `buildShell`
- Create: `plugins/visual-kit/tests/integration/free-interactive-serve.test.ts`

- [ ] **Step 5.1: Write the failing test**

Create `plugins/visual-kit/tests/integration/free-interactive-serve.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';

describe('free-interactive surface (integration)', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => { ws = await tmpWorkspace(); });
  afterEach(async () => { await stopServer(); await ws.cleanup(); });

  async function startAndReadInfo() {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
  }

  async function writeSpec(plugin: string, id: string, spec: object) {
    const dir = join(ws.dir, `.${plugin}`, 'content');
    await mkdir(dir, { recursive: true });
    await writeFile(join(dir, `${id}.json`), JSON.stringify(spec), 'utf8');
  }

  it('serves free-interactive HTML without a CSP header', async () => {
    await writeSpec('demo', 'parabola', {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body><script>window.__marker=42</script></body></html>',
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/parabola`);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/html/);
    expect(res.headers.get('content-security-policy')).toBeNull();
    // Security headers that always apply are still present:
    expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    expect(res.headers.get('referrer-policy')).toBe('no-referrer');

    const body = await res.text();
    expect(body).toContain('<script>window.__marker=42</script>');
    // Reload script injected:
    expect(body).toContain("new EventSource('/events/stream')");
  });

  it('does NOT wrap free-interactive in the vk-surface shell', async () => {
    await writeSpec('demo', 'raw', {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body><p>raw</p></body></html>',
    });
    const info = await startAndReadInfo();

    const body = await (await fetch(`${info.url}/p/demo/raw`)).text();
    expect(body).not.toContain('<main class="vk-surface">');
    expect(body).not.toContain('meta name="vk-csrf"');
    expect(body).not.toContain('/vk/core.js');
  });

  it('regression guard: lesson surface still uses strict shell + CSP', async () => {
    await writeSpec('demo', 'les', {
      surface: 'lesson',
      version: 1,
      topic: 'regression',
      level: 'beginner',
      sections: [{ kind: 'why', body: 'x' }],
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/les`);
    expect(res.status).toBe(200);
    const csp = res.headers.get('content-security-policy');
    expect(csp).toBeTruthy();
    expect(csp).toContain("script-src 'self'");
    expect(csp).toContain("nonce-");
    const body = await res.text();
    expect(body).toContain('<main class="vk-surface">');
  });

  it('returns the vk-error page for an invalid free-interactive spec', async () => {
    await writeSpec('demo', 'bad', {
      surface: 'free-interactive',
      version: 1,
      // html field is missing — schema should reject.
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/bad`);
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body).toContain('vk-error');
    expect(body).toContain('Schema');
  });
});
```

Note on the regression test: the exact shape of a valid `lesson` spec may differ from the stub above. If vitest rejects the lesson spec on schema grounds, read the minimum required fields from `schemas/surfaces/lesson.v1.json` and fix the literal in the test. The test's assertion is about HEADERS, not about lesson content — any schema-valid lesson body is fine.

- [ ] **Step 5.2: Run the test to verify it fails**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/integration/free-interactive-serve.test.ts 2>&1 | tail -25
```

Expected: FAILs. The first test fails because the server currently routes every surface through `buildShell`, which emits a CSP header and wraps the body in `<main class="vk-surface">`. You'll see the CSP header assertion fail and the body assertion fail.

- [ ] **Step 5.3: Add the short-circuit branch in the server handler**

In `plugins/visual-kit/src/server/index.ts`:

(a) Add the import at the top of the file, next to the existing `renderSurface` import:

```typescript
import { renderFreeInteractive } from '../surfaces/free-interactive.js';
```

(b) Locate the block that currently reads (around line 187-205):

```typescript
    const result = validateSpec(spec);
    const nonce = makeNonce();
    const csrf = makeCsrfToken(ctx.secret, { plugin, surfaceId, nonce });
    const coreBundle = await resolveCoreBundle(version);
    if (!result.ok) {
      // Even on schema failure, render an error page (200) with vk-error fragment.
      return renderErrorPage(res, `Schema: ${result.errors.join('; ')}`, { plugin, surfaceId }, nonce, csrf, [coreBundle]);
    }
    const fragment = renderFragment(renderSurface(spec as never));
    const { html, headers } = buildShell({
      title: `${plugin}/${surfaceId}`,
      nonce,
      csrfToken: csrf,
      bundles: [coreBundle],
      fragment,
    });
    res.writeHead(200, headers);
    res.end(html);
    return;
```

Replace it with:

```typescript
    const result = validateSpec(spec);
    const nonce = makeNonce();
    const csrf = makeCsrfToken(ctx.secret, { plugin, surfaceId, nonce });
    const coreBundle = await resolveCoreBundle(version);
    if (!result.ok) {
      // Even on schema failure, render an error page (200) with vk-error fragment.
      return renderErrorPage(res, `Schema: ${result.errors.join('; ')}`, { plugin, surfaceId }, nonce, csrf, [coreBundle]);
    }
    if (result.kind === 'free-interactive') {
      // Opt-in permissive surface: serve AI-authored HTML as-is. No CSP, no
      // CSRF binding, no shell. Host-allowlist + securityHeaders() still apply.
      // See: docs/superpowers/specs/2026-04-19-visual-kit-free-interactive-surface.md
      const body = renderFreeInteractive(spec as never);
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        ...securityHeaders(),
      });
      res.end(body);
      return;
    }
    const fragment = renderFragment(renderSurface(spec as never));
    const { html, headers } = buildShell({
      title: `${plugin}/${surfaceId}`,
      nonce,
      csrfToken: csrf,
      bundles: [coreBundle],
      fragment,
    });
    res.writeHead(200, headers);
    res.end(html);
    return;
```

- [ ] **Step 5.4: Run the test to verify it passes**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/integration/free-interactive-serve.test.ts 2>&1 | tail -20
```

Expected: all 4 tests PASS.

If the regression guard lesson test fails with a schema error, open `plugins/visual-kit/schemas/surfaces/lesson.v1.json`, read the required fields, and adjust the test's lesson spec literal. The test still passes its asserts once the server responds 200.

- [ ] **Step 5.5: Run the full test suite**

Run:
```bash
cd plugins/visual-kit && pnpm test 2>&1 | tail -15
```

Expected: everything green. Test count grew by 4 from Task 4.

- [ ] **Step 5.6: Commit**

```bash
git add plugins/visual-kit/src/server/index.ts plugins/visual-kit/tests/integration/free-interactive-serve.test.ts
git commit -m "$(cat <<'EOF'
feat(visual-kit): server short-circuit for free-interactive

When a request resolves to a free-interactive spec, the handler now
serves the stored HTML verbatim (plus a tiny SSE reload script) and
skips buildShell. No CSP header is emitted on this response; all
other always-on security headers are preserved. Strict surfaces are
unchanged — regression test asserts lesson still returns CSP.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Advertise in `/vk/capabilities`

**Files:**
- Modify: `plugins/visual-kit/src/server/capabilities.ts`
- Test: `plugins/visual-kit/tests/integration/serve.test.ts` already asserts capabilities — augment it.

- [ ] **Step 6.1: Write the failing test**

In `plugins/visual-kit/tests/integration/serve.test.ts`, add a new `it` inside the existing `describe('startServer (integration)', ...)` block, immediately after the first `it` that checks capabilities:

```typescript
  it('advertises free-interactive as a permissive surface', async () => {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    const { readFile } = await import('node:fs/promises');
    const info = JSON.parse(await readFile(`${ws.dir}/.visual-kit/server/state/server-info`, 'utf8'));
    const caps = await (await fetch(`${info.url}/vk/capabilities`)).json();

    expect(caps.surfaces['free-interactive']).toBeDefined();
    expect(caps.surfaces['free-interactive'].schema).toBe('/vk/schemas/free-interactive.v1.json');
    expect(caps.surfaces['free-interactive'].permissive).toBe(true);

    // Existing surfaces should NOT have the permissive flag set:
    expect(caps.surfaces['lesson'].permissive).toBeUndefined();
    expect(caps.surfaces['free'].permissive).toBeUndefined();
  });
```

Also extend the existing first test's `arrayContaining` assertion to include the new kind. Find:

```typescript
    expect(Object.keys(caps.surfaces)).toEqual(
      expect.arrayContaining(['lesson','gallery','outline','comparison','feedback','free']),
    );
```

Change to:

```typescript
    expect(Object.keys(caps.surfaces)).toEqual(
      expect.arrayContaining(['lesson','gallery','outline','comparison','feedback','free','free-interactive']),
    );
```

- [ ] **Step 6.2: Run the test to verify it fails**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/integration/serve.test.ts 2>&1 | tail -20
```

Expected: the first test now passes (free-interactive is in the listSurfaces() output from Task 3) but the new "permissive flag" assertion fails because capabilities.ts doesn't emit that flag.

- [ ] **Step 6.3: Update capabilities builder**

Replace the contents of `plugins/visual-kit/src/server/capabilities.ts`:

```typescript
import { listSurfaces } from '../render/validate.js';
import type { SurfaceKind } from '../shared/types.js';

// Injected at build time by scripts/build.mjs via esbuild define.
// Falls back to a dev sentinel when running from source via ts-node / vitest.
declare const __VK_CORE_SRI__: string;
const CORE_SRI: string =
  typeof __VK_CORE_SRI__ !== 'undefined' ? __VK_CORE_SRI__ : 'sha384-dev';

const COMPONENTS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
];

const PERMISSIVE: ReadonlySet<SurfaceKind> = new Set(['free-interactive']);

export async function buildCapabilities(version: string): Promise<object> {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => {
        const entry: Record<string, unknown> = { schema: `/vk/schemas/${k}.v1.json` };
        if (PERMISSIVE.has(k)) entry.permissive = true;
        return [k, entry];
      }),
    ),
    components: COMPONENTS,
    bundles: [
      { name: 'core', url: '/vk/core.js', sri: CORE_SRI },
    ],
  };
}
```

- [ ] **Step 6.4: Run the test to verify it passes**

Run:
```bash
cd plugins/visual-kit && pnpm vitest run tests/integration/serve.test.ts 2>&1 | tail -15
```

Expected: all tests PASS, including the new permissive-flag assertion.

- [ ] **Step 6.5: Commit**

```bash
git add plugins/visual-kit/src/server/capabilities.ts plugins/visual-kit/tests/integration/serve.test.ts
git commit -m "$(cat <<'EOF'
feat(visual-kit): advertise free-interactive as permissive in capabilities

Clients can now read caps.surfaces['free-interactive'].permissive === true
to detect the relaxed trust model before emitting specs. No other
surface gains the flag.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Version bump + CHANGELOG

**Files:**
- Modify: `plugins/visual-kit/package.json`
- Modify: `plugins/visual-kit/CHANGELOG.md`

- [ ] **Step 7.1: Bump version in `package.json`**

Open `plugins/visual-kit/package.json` and change:

```json
"version": "1.0.0",
```

to:

```json
"version": "1.1.0",
```

Leave every other field unchanged.

- [ ] **Step 7.2: Read the current CHANGELOG format**

Run:
```bash
head -40 plugins/visual-kit/CHANGELOG.md
```

Note the existing heading style so the new entry matches. (Expect a top-level `# Changelog` with `## [1.0.0]` style entries.)

- [ ] **Step 7.3: Add a v1.1.0 entry**

Insert this block at the top of `plugins/visual-kit/CHANGELOG.md`, immediately after the `# Changelog` heading and before the `## [1.0.0]` entry:

```markdown
## [1.1.0] — 2026-04-19

### Added
- New opt-in surface kind `free-interactive` for AI-authored HTML+JS served without sanitisation or CSP. Intended for interactive content (live graphs, sliders, custom SVG). Schema: `/vk/schemas/free-interactive.v1.json`. Capabilities entry carries `"permissive": true` so clients can detect the relaxed trust model.
- Capabilities endpoint now emits a `permissive` flag for permissive surfaces.

### Security posture of the new surface
`free-interactive` serves AI-authored HTML+JS **without** DOMPurify sanitisation and **without** a Content-Security-Policy header. This matches the trust model of the superpowers brainstorming companion: localhost-only, AI is trusted, operator visually reviews output before interacting.

Residual risks this surface does NOT defend against:
- Prompt-injected AI output can exfiltrate via `fetch()` to the open internet.
- A malicious page can probe other unauthenticated localhost services.
- UI phishing within the served page.

Defences that still apply to every response, including this surface:
- Host-allowlist (`isHostAllowed`) blocks DNS-rebinding attempts.
- Loopback binding keeps external hosts off the server.
- Path-traversal protection (`resolveContained`) confines content reads to `.{plugin}/content/`.
- Always-on security headers: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Resource-Policy: same-origin`.

If you need defence against the residual risks, use the existing structured surfaces (`lesson`, `outline`, `free`, etc.). They are unchanged in this release.

### Unchanged
- All existing surfaces (`lesson`, `gallery`, `outline`, `comparison`, `feedback`, `free`) keep their strict CSP and, where applicable, their DOMPurify sanitisation.
```

- [ ] **Step 7.4: Verify the package.json still parses**

Run:
```bash
node -e "JSON.parse(require('fs').readFileSync('plugins/visual-kit/package.json','utf8'));console.log('ok')"
```

Expected: `ok`.

- [ ] **Step 7.5: Run the full test suite one more time**

Run:
```bash
cd plugins/visual-kit && pnpm test 2>&1 | tail -15
```

Expected: all green.

- [ ] **Step 7.6: Commit**

```bash
git add plugins/visual-kit/package.json plugins/visual-kit/CHANGELOG.md
git commit -m "$(cat <<'EOF'
chore(visual-kit): release v1.1.0 — free-interactive surface

CHANGELOG documents the trust-model disclosure explicitly so
consumers understand what security properties this new surface does
and does not carry.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Final verification gate

**Goal:** prove the whole change is coherent and ready to merge.

- [ ] **Step 8.1: Build the bundle**

Run:
```bash
cd plugins/visual-kit && pnpm run build 2>&1 | tail -10
```

Expected: build succeeds with no errors. Dist output includes the new schema file.

- [ ] **Step 8.2: Confirm the new schema is in dist**

Run:
```bash
ls plugins/visual-kit/dist/schemas/surfaces/ 2>&1 | grep -i free
```

Expected output contains both `free.v1.json` and `free-interactive.v1.json`. If `free-interactive.v1.json` is missing, open `plugins/visual-kit/scripts/build.mjs` and ensure the schema copy step uses a glob (it already does — this step is just a safety check).

- [ ] **Step 8.3: Run the `verify` script (includes lint + build + test + security gates)**

Run:
```bash
cd plugins/visual-kit && pnpm run verify 2>&1 | tail -20
```

Expected: all gates pass. Note any warnings.

- [ ] **Step 8.4: Manual smoke test against a real project**

Run (outside the repo, from any project dir):

```bash
mkdir -p /tmp/vk-smoke && cd /tmp/vk-smoke
mkdir -p .demo/content
cat > .demo/content/pb.json <<'EOF'
{
  "surface": "free-interactive",
  "version": 1,
  "title": "parabola smoke test",
  "html": "<!DOCTYPE html><html><head><style>body{font-family:system-ui;padding:2rem}</style></head><body><h1>Parabola</h1><canvas id=c width=400 height=300 style='border:1px solid #ccc'></canvas><div>a: <input id=a type=range min=-2 max=2 step=0.1 value=1></div><script>const c=document.getElementById('c'),ctx=c.getContext('2d'),a=document.getElementById('a');function draw(){const A=parseFloat(a.value);ctx.clearRect(0,0,400,300);ctx.beginPath();for(let x=-10;x<=10;x+=0.1){const y=A*x*x;const px=200+x*20,py=150-y*5;if(x===-10)ctx.moveTo(px,py);else ctx.lineTo(px,py)}ctx.stroke()}a.addEventListener('input',draw);draw();</script></body></html>"
}
EOF

# From the repo, start the server pointed at the smoke dir:
cd -
node plugins/visual-kit/bin/visual-kit serve --project-dir /tmp/vk-smoke &
SERVER_PID=$!
sleep 2
cat /tmp/vk-smoke/.visual-kit/server/state/server-info
# Open the URL listed there + /p/demo/pb in a browser — the slider should move the parabola live.
# When done:
kill $SERVER_PID
rm -rf /tmp/vk-smoke
```

Expected: browser renders an interactive canvas parabola. Dragging the `a` slider redraws the curve in real time. Opening DevTools → Console shows no CSP violations. Network tab shows NO `Content-Security-Policy` header on the `/p/demo/pb` response.

- [ ] **Step 8.5: Test count sanity check**

Compare the current test count with the pre-flight baseline. Expected new tests: Task 1 (3), Task 3 (7), Task 4 (7), Task 5 (4), Task 6 (1). **Total new tests: 22.** Total test count should equal the pre-flight number + 22.

Run:
```bash
cd plugins/visual-kit && pnpm test 2>&1 | grep -E "Tests.*passed"
```

Cross-reference with the number recorded in Step 0.3.

- [ ] **Step 8.6: Final commit (if anything from the smoke test required fixes)**

If Step 8.4 surfaced any issues, fix them and commit with a `fix(visual-kit)` prefix. If the smoke test passed cleanly, no commit is needed.

---

## Acceptance summary (maps back to spec)

| Spec requirement | Implemented by |
|---|---|
| `free-interactive.v1.json` schema exists and registers | Task 2, Task 3 |
| `free-interactive` in `SurfaceKind` union | Task 1 |
| Server short-circuits for this surface | Task 5 |
| No CSP header on `free-interactive` responses | Task 5 integration test |
| Strict CSP preserved on existing surfaces | Task 5 regression test |
| Reload script injected before `</body>` | Task 4 unit tests |
| `/vk/capabilities` lists surface with `permissive: true` | Task 6 |
| CHANGELOG documents trust model | Task 7 |
| `package.json` v1.1.0 | Task 7 |
| All existing tests pass | Task 3, 5, 7, 8 regression runs |
| Host-allowlist, loopback, path-traversal still apply | Unmodified — Task 5 test asserts security headers are present |

---

## Out of scope (explicit — do NOT do these in this plan)

- Updating paidagogos skills to emit `free-interactive` specs — separate spec, separate plan.
- Adding `vk-slider` / `vk-parametric-plot` / other interactive Lit components — separate plan.
- Fragment auto-wrap à la superpowers' frame template — separate plan.
- Iframe sandbox for `free-interactive` — separate plan if ever wanted.
- Refactoring the existing `free` surface — leave it exactly as it is.
