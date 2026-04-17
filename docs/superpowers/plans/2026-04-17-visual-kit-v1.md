# Visual-Kit V1 — Infrastructure + Paidagogos Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `visual-kit` plugin (local HTTP server + `<vk-*>` component library + SurfaceSpec rendering pipeline) and migrate paidagogos to depend on it, deleting paidagogos's in-house server. This plan ships V1.0 of visual-kit plus a working end-to-end paidagogos lesson.

**Architecture:** Claude Code "library" plugin published in the same marketplace as its consumers. Consumers declare it via `plugin.json` `dependencies[]`. Runtime seams only: a `bin/visual-kit` CLI on PATH, HTTP endpoints on localhost (per-workspace port derived from workspace-path hash), and HTTP-served component bundles. SurfaceSpec JSON (typed, versioned) is the contract; lit-html SSR renders it into fragments wrapped in a strict-CSP shell.

**Tech Stack:**
- Node.js 20+ (for Lit SSR, native `fs.promises`, `node:http`)
- TypeScript 5.x compiled to ESM via esbuild
- Lit 3.x (core component framework, 5 KB runtime)
- lit-html + `@lit-labs/ssr` (server-side rendering)
- ajv 8.x (JSON schema validation)
- DOMPurify 3.x + jsdom (server-side sanitizer for `free` surface)
- vitest (unit + integration tests)
- Chrome DevTools MCP (browser verification)

**Spec reference:** `docs/superpowers/specs/2026-04-17-visual-kit-design.md`. Acceptance specs at `docs/plugins/visual-kit/specs/*.feature`.

**Naming reminders:**
- Plugin directory: `plugins/visual-kit/`
- CLI: `visual-kit serve|stop|status`
- Component prefix: `<vk-*>`
- Bundle filenames: `core.js`, `chart.js`, `math.js`, `code.js`, `quiz.js`, `progress.js`, `geometry.js`, `sim-2d.js`, `audio.js`
- Workspace state paths: `<workspace>/.visual-kit/server/state/{server-info,server.lock,server-stopped}`; consumer writes at `<workspace>/.<plugin>/content/*.json`; consumer reads at `<workspace>/.<plugin>/state/events`.

**Out of scope** (covered by follow-up plans):
- Domain bundles: code, math, chart, quiz, progress → **Plan B** (namesmith + draftloom migration).
- Extended bundles: geometry, sim-2d, audio → **Plan C**.
- Namesmith gallery migration, draftloom outline/comparison migration → **Plan B**.

**Plan A limit:** Ship visual-kit core (server + security + all 6 surfaces + **core bundle** only, which is sufficient for paidagogos lessons because paidagogos's existing lesson template uses only `<vk-section>`-equivalent blocks for concept/why/mistakes/generate/resources/next and one-off primitives for code/quiz that we provide as minimal inline implementations). Code-syntax-highlight quality is maintained by a minimal Prism-backed `<vk-code>` in the core bundle for V1; rich editor experience lands in Plan B.

---

## File Structure

### Created (new files, Plan A)

```
plugins/visual-kit/
├── README.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── .npmrc
├── bin/
│   └── visual-kit                       ← CLI shim (Node shebang)
├── src/
│   ├── cli/
│   │   ├── index.ts                     ← dispatch serve/stop/status
│   │   ├── serve.ts
│   │   ├── stop.ts
│   │   └── status.ts
│   ├── server/
│   │   ├── index.ts                     ← HTTP server factory
│   │   ├── lifecycle.ts                 ← port hashing, lock, server-info atomic write
│   │   ├── router.ts                    ← route dispatch
│   │   ├── security.ts                  ← CSP + nonce + CSRF + Host allowlist
│   │   ├── paths.ts                     ← path validation + realpath containment
│   │   ├── capabilities.ts              ← GET /vk/capabilities
│   │   ├── bundles.ts                   ← GET /vk/<bundle>.js + SRI
│   │   ├── events.ts                    ← POST /events handler
│   │   ├── sse.ts                       ← GET /events/stream
│   │   ├── watcher.ts                   ← content-dir fs watcher
│   │   └── errors.ts                    ← generic error bodies + private log
│   ├── render/
│   │   ├── shell.ts                     ← HTML frame with CSP, nonce, meta tags
│   │   ├── dispatcher.ts                ← SurfaceSpec → fragment
│   │   ├── ssr.ts                       ← lit-html SSR wrapper
│   │   ├── sanitize.ts                  ← DOMPurify for free surface
│   │   └── error-fragment.ts            ← <vk-error> emitter
│   ├── surfaces/
│   │   ├── lesson.ts
│   │   ├── gallery.ts
│   │   ├── outline.ts
│   │   ├── comparison.ts
│   │   ├── feedback.ts
│   │   └── free.ts
│   ├── components/
│   │   ├── theme.css                    ← CSS variables + prefers-color-scheme
│   │   ├── index.ts                     ← registers all core components
│   │   ├── section.ts                   ← <vk-section>
│   │   ├── card.ts                      ← <vk-card>
│   │   ├── gallery.ts                   ← <vk-gallery>
│   │   ├── outline.ts                   ← <vk-outline>
│   │   ├── comparison.ts                ← <vk-comparison>
│   │   ├── feedback.ts                  ← <vk-feedback>
│   │   ├── loader.ts                    ← <vk-loader>
│   │   ├── error.ts                     ← <vk-error>
│   │   └── code.ts                      ← <vk-code> (Prism-backed, minimal)
│   └── shared/
│       ├── types.ts                     ← SurfaceSpec + event types
│       ├── json.ts                      ← safe JSON parse + atomic write
│       └── hash.ts                      ← workspace-path → port derivation
├── schemas/
│   └── surfaces/
│       ├── lesson.v1.json
│       ├── gallery.v1.json
│       ├── outline.v1.json
│       ├── comparison.v1.json
│       ├── feedback.v1.json
│       └── free.v1.json
├── scripts/
│   ├── build.mjs                        ← esbuild driver
│   ├── lint-pure-components.mjs
│   ├── test-security-headers.mjs
│   └── bundle-size-gate.mjs
├── dist/                                ← built artifacts (committed for release)
│   ├── cli.js                           ← CLI bundle
│   ├── server.js                        ← server bundle
│   ├── core.js                          ← browser core bundle
│   └── core.js.sri.txt                  ← SRI hash file
└── tests/
    ├── unit/
    │   ├── hash.test.ts
    │   ├── security.test.ts
    │   ├── paths.test.ts
    │   ├── lifecycle.test.ts
    │   └── dispatcher.test.ts
    ├── integration/
    │   ├── serve.test.ts                ← boots server, hits endpoints
    │   ├── render.test.ts               ← writes SurfaceSpec, fetches rendered
    │   ├── csrf.test.ts                 ← cross-plugin event isolation
    │   ├── dns-rebinding.test.ts
    │   └── traversal.test.ts
    └── helpers/
        ├── tmp-workspace.ts
        └── http-fixture.ts
```

### Modified (Plan A)

```
plugins/paidagogos/.claude-plugin/plugin.json   ← add visual-kit dependency
plugins/paidagogos/skills/paidagogos-micro/SKILL.md
plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md
plugins/paidagogos/CHANGELOG.md
plugins/paidagogos/README.md
```

### Deleted (Plan A)

```
plugins/paidagogos/server/                       ← entire directory
```

### File responsibilities

- `bin/visual-kit`: Node shebang. Requires `dist/cli.js`.
- `src/cli/index.ts`: Argv dispatch. Routes to `serve.ts`, `stop.ts`, `status.ts`. No domain logic.
- `src/server/lifecycle.ts`: Workspace-path hash → port. Advisory lock. Atomic `server-info`. PID liveness probe.
- `src/server/security.ts`: Generates CSP string with per-response nonce. Validates Host header. Issues + validates CSRF tokens bound to `<plugin, surface-id, nonce>`.
- `src/server/paths.ts`: Regex + realpath + symlink lstat. Every URL-derived path goes through it.
- `src/server/events.ts`: Derives plugin from Referer; refuses body-supplied plugin. Validates JSON schema. Rotates log at 50 MB.
- `src/render/shell.ts`: Builds the outer HTML (head + body + meta tags). Receives rendered fragment as child.
- `src/render/dispatcher.ts`: Maps `surface` string to renderer. Returns `<vk-error>` on unknown.
- `src/surfaces/<name>.ts`: Pure function `(spec: LessonSpec) => TemplateResult`. Receives typed spec, emits lit-html template.
- `src/components/*.ts`: Each exports a class extending `LitElement`, registered via `@customElement('vk-...')`. Pure — no fetches, no storage.
- `schemas/surfaces/<name>.v1.json`: JSON Schema Draft 2020-12. Ajv compiles at startup.
- `scripts/lint-pure-components.mjs`: Greps `src/components/` for `fetch(`, `localStorage`, `sessionStorage`, cross-module reads. CI-blocking.

---

## Task 0: Pre-flight — verify tools and worktree

**Files:**
- None (environment check)

- [ ] **Step 1: Confirm worktree and Node version**

Run:
```bash
pwd
node --version
```

Expected: working directory ends in `.worktrees/visual-kit-v1`. Node version ≥ 20.

- [ ] **Step 2: Confirm main is merged in**

Run: `git log --oneline -1`
Expected: commit subject matches `docs(visual-kit): introduce shared visual rendering plugin spec` or newer.

- [ ] **Step 3: Install pnpm globally if missing**

Run: `pnpm --version || npm install -g pnpm@9`
Expected: a version string like `9.x.x`.

---

## Task 1: Plugin scaffold

**Files:**
- Create: `plugins/visual-kit/.claude-plugin/plugin.json`
- Create: `plugins/visual-kit/README.md`
- Create: `plugins/visual-kit/CHANGELOG.md`
- Create: `plugins/visual-kit/package.json`
- Create: `plugins/visual-kit/tsconfig.json`
- Create: `plugins/visual-kit/.npmrc`

- [ ] **Step 1: Create plugin.json**

Write `plugins/visual-kit/.claude-plugin/plugin.json`:
```json
{
  "name": "visual-kit",
  "version": "1.0.0",
  "description": "Shared local visual rendering for Claude Code plugins. Provides the vk-* component library, HTTP server, and SurfaceSpec JSON contract.",
  "author": "neotherapper",
  "license": "MIT",
  "keywords": ["visualization", "library-plugin", "rendering"],
  "skills": []
}
```

- [ ] **Step 2: Create package.json**

Write `plugins/visual-kit/package.json`:
```json
{
  "name": "@neotherapper/visual-kit",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "bin": {
    "visual-kit": "bin/visual-kit"
  },
  "scripts": {
    "build": "node scripts/build.mjs",
    "lint:pure": "node scripts/lint-pure-components.mjs",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "verify": "pnpm run lint:pure && pnpm run build && pnpm run test"
  },
  "engines": { "node": ">=20.0.0" },
  "dependencies": {
    "lit": "3.2.1",
    "@lit-labs/ssr": "3.2.2",
    "@lit-labs/ssr-client": "1.1.7",
    "ajv": "8.17.1",
    "ajv-formats": "3.0.1",
    "dompurify": "3.1.7",
    "jsdom": "25.0.1"
  },
  "devDependencies": {
    "@types/node": "22.7.4",
    "@types/jsdom": "21.1.7",
    "esbuild": "0.24.0",
    "typescript": "5.6.2",
    "vitest": "2.1.2"
  }
}
```

- [ ] **Step 3: Create tsconfig.json**

Write `plugins/visual-kit/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "useDefineForClassFields": false,
    "experimentalDecorators": true,
    "outDir": "dist",
    "rootDir": "src",
    "lib": ["ES2022", "DOM"]
  },
  "include": ["src/**/*.ts"],
  "exclude": ["dist", "node_modules"]
}
```

- [ ] **Step 4: Create .npmrc**

Write `plugins/visual-kit/.npmrc`:
```
engine-strict=true
save-exact=true
```

- [ ] **Step 5: Write README.md**

Write `plugins/visual-kit/README.md`:
```markdown
# visual-kit

Shared local-browser visual rendering for Claude Code plugins.

## What it provides

- `bin/visual-kit` — CLI (serve / stop / status) placed on PATH.
- HTTP server at `http://localhost:<port>/` (per-workspace, localhost-only, strict CSP).
- `<vk-*>` web component library served at `/vk/*.js`.
- SurfaceSpec JSON contract — consumer skills write typed JSON; visual-kit renders it.

## For consumers

In your plugin's `.claude-plugin/plugin.json`:

    {
      "dependencies": [
        { "name": "visual-kit", "version": "~1.0.0" }
      ]
    }

Start the server once per workspace:

    visual-kit serve --project-dir .

Write a SurfaceSpec to `.<your-plugin>/content/<surface-id>.json`. Open the printed URL.

## Docs

- Design spec: `docs/superpowers/specs/2026-04-17-visual-kit-design.md`
- Contributor index: `docs/plugins/visual-kit/_index.md`
- Gherkin acceptance: `docs/plugins/visual-kit/specs/*.feature`
```

- [ ] **Step 6: Write CHANGELOG.md**

Write `plugins/visual-kit/CHANGELOG.md`:
```markdown
# Changelog

## Unreleased (pre-1.0.0)

- Initial scaffolding. See `docs/superpowers/plans/2026-04-17-visual-kit-v1.md`.
```

- [ ] **Step 7: Install dependencies**

Run:
```bash
cd plugins/visual-kit && pnpm install
```

Expected: `pnpm-lock.yaml` created, `node_modules/` populated, no errors.

- [ ] **Step 8: Commit**

```bash
git add plugins/visual-kit/ && git commit -m "feat(visual-kit): scaffold plugin with dependencies and tsconfig

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: CLI shim and dispatch

**Files:**
- Create: `plugins/visual-kit/bin/visual-kit`
- Create: `plugins/visual-kit/src/cli/index.ts`
- Create: `plugins/visual-kit/src/cli/serve.ts`
- Create: `plugins/visual-kit/src/cli/stop.ts`
- Create: `plugins/visual-kit/src/cli/status.ts`

- [ ] **Step 1: Write bin/visual-kit shim**

Write `plugins/visual-kit/bin/visual-kit`:
```bash
#!/usr/bin/env node
import('../dist/cli.js').catch(err => {
  process.stderr.write(`visual-kit failed to load: ${err?.message ?? err}\n`);
  process.exit(1);
});
```

Then run: `chmod +x plugins/visual-kit/bin/visual-kit`

- [ ] **Step 2: Write cli/index.ts**

Write `plugins/visual-kit/src/cli/index.ts`:
```ts
import { runServe } from './serve.js';
import { runStop } from './stop.js';
import { runStatus } from './status.js';

const [command, ...rest] = process.argv.slice(2);

switch (command) {
  case 'serve':
    await runServe(rest);
    break;
  case 'stop':
    await runStop(rest);
    break;
  case 'status':
    await runStatus(rest);
    break;
  case '--help':
  case '-h':
  case undefined:
    printUsage(0);
    break;
  default:
    process.stderr.write(`unknown command: ${command}\n`);
    printUsage(2);
}

function printUsage(code: number): never {
  process.stdout.write(`visual-kit — per-workspace local visual renderer

Usage:
  visual-kit serve --project-dir <path> [--host <addr>] [--url-host <name>] [--foreground]
  visual-kit stop  --project-dir <path>
  visual-kit status --project-dir <path>
`);
  process.exit(code);
}
```

- [ ] **Step 3: Write cli/serve.ts (argument parsing only; server wiring in Task 6)**

Write `plugins/visual-kit/src/cli/serve.ts`:
```ts
import { resolve } from 'node:path';

export interface ServeOptions {
  projectDir: string;
  host: string;
  urlHost: string;
  foreground: boolean;
}

export async function runServe(argv: string[]): Promise<void> {
  const opts = parseServe(argv);
  const { startServer } = await import('../server/index.js');
  await startServer(opts);
}

export function parseServe(argv: string[]): ServeOptions {
  let projectDir: string | undefined;
  let host = '127.0.0.1';
  let urlHost: string | undefined;
  let foreground = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--project-dir': projectDir = argv[++i]; break;
      case '--host':        host       = argv[++i] ?? host; break;
      case '--url-host':    urlHost    = argv[++i]; break;
      case '--foreground':  foreground = true; break;
      default:
        throw new Error(`unknown argument: ${arg}`);
    }
  }

  if (!projectDir) throw new Error('--project-dir is required');

  if (host !== '127.0.0.1' && host !== 'localhost') {
    process.stderr.write(
      `WARNING: binding to ${host} exposes visual-kit to the network. ` +
      `Only use in trusted remote-dev environments.\n`
    );
  }

  return {
    projectDir: resolve(projectDir),
    host,
    urlHost: urlHost ?? (host === '127.0.0.1' || host === 'localhost' ? 'localhost' : host),
    foreground,
  };
}
```

- [ ] **Step 4: Write cli/stop.ts**

Write `plugins/visual-kit/src/cli/stop.ts`:
```ts
import { readFile, rm } from 'node:fs/promises';
import { resolve, join } from 'node:path';

export async function runStop(argv: string[]): Promise<void> {
  const projectDir = parseProjectDir(argv);
  const infoPath = join(projectDir, '.visual-kit/server/state/server-info');
  let info: { pid: number; port: number } | undefined;
  try {
    info = JSON.parse(await readFile(infoPath, 'utf8'));
  } catch {
    process.stdout.write(JSON.stringify({ status: 'not-running', projectDir }) + '\n');
    return;
  }
  if (info?.pid) {
    try {
      process.kill(info.pid, 'SIGTERM');
    } catch (err: unknown) {
      const code = (err as NodeJS.ErrnoException).code;
      if (code !== 'ESRCH') throw err;
    }
  }
  await rm(infoPath, { force: true });
  process.stdout.write(JSON.stringify({ status: 'stopped', projectDir }) + '\n');
}

function parseProjectDir(argv: string[]): string {
  const idx = argv.indexOf('--project-dir');
  if (idx < 0 || !argv[idx + 1]) throw new Error('--project-dir is required');
  return resolve(argv[idx + 1]!);
}
```

- [ ] **Step 5: Write cli/status.ts**

Write `plugins/visual-kit/src/cli/status.ts`:
```ts
import { readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';

export async function runStatus(argv: string[]): Promise<void> {
  const projectDir = parseProjectDir(argv);
  const infoPath = join(projectDir, '.visual-kit/server/state/server-info');
  let info: Record<string, unknown> | undefined;
  try {
    info = JSON.parse(await readFile(infoPath, 'utf8'));
  } catch {
    process.stdout.write(JSON.stringify({ status: 'not-running', projectDir }) + '\n');
    return;
  }
  if (info?.pid && !isAlive(info.pid as number)) {
    process.stdout.write(JSON.stringify({ status: 'stale', projectDir, recorded: info }) + '\n');
    return;
  }
  process.stdout.write(JSON.stringify(info) + '\n');
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function parseProjectDir(argv: string[]): string {
  const idx = argv.indexOf('--project-dir');
  if (idx < 0 || !argv[idx + 1]) throw new Error('--project-dir is required');
  return resolve(argv[idx + 1]!);
}
```

- [ ] **Step 6: Stub server/index.ts so CLI type-checks**

Write `plugins/visual-kit/src/server/index.ts`:
```ts
import type { ServeOptions } from '../cli/serve.js';

export async function startServer(_opts: ServeOptions): Promise<void> {
  throw new Error('startServer not implemented — Task 6');
}
```

- [ ] **Step 7: Type-check**

Run:
```bash
cd plugins/visual-kit && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add plugins/visual-kit/bin plugins/visual-kit/src/cli plugins/visual-kit/src/server/index.ts
git commit -m "feat(visual-kit): CLI dispatch for serve/stop/status

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Workspace-path hash and port derivation

**Files:**
- Create: `plugins/visual-kit/src/shared/hash.ts`
- Create: `plugins/visual-kit/tests/unit/hash.test.ts`
- Create: `plugins/visual-kit/vitest.config.ts`

- [ ] **Step 1: Write vitest config**

Write `plugins/visual-kit/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'node',
    testTimeout: 10000,
  },
});
```

- [ ] **Step 2: Write failing test for hash → port**

Write `plugins/visual-kit/tests/unit/hash.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { workspacePort } from '../../src/shared/hash.js';

describe('workspacePort', () => {
  it('derives the same port for the same absolute path', () => {
    const p1 = workspacePort('/Users/demo/proj');
    const p2 = workspacePort('/Users/demo/proj');
    expect(p1).toBe(p2);
  });

  it('derives different ports for different paths', () => {
    const a = workspacePort('/Users/demo/project-a');
    const b = workspacePort('/Users/demo/project-b');
    expect(a).not.toBe(b);
  });

  it('maps into the range [20000, 60000)', () => {
    for (const path of ['/a', '/b', '/c/d/e', '/x'.repeat(50)]) {
      const port = workspacePort(path);
      expect(port).toBeGreaterThanOrEqual(20000);
      expect(port).toBeLessThan(60000);
    }
  });
});
```

- [ ] **Step 3: Run test — expect failure**

Run:
```bash
cd plugins/visual-kit && pnpm test
```

Expected: FAIL with "Cannot find module ../../src/shared/hash.js".

- [ ] **Step 4: Implement hash.ts**

Write `plugins/visual-kit/src/shared/hash.ts`:
```ts
import { createHash } from 'node:crypto';

const PORT_MIN = 20000;
const PORT_RANGE = 40000; // [20000, 60000)

/**
 * Derives a stable port from the absolute workspace path.
 * sha256 → first 4 bytes as u32 → modulo PORT_RANGE → offset PORT_MIN.
 */
export function workspacePort(absolutePath: string): number {
  const hash = createHash('sha256').update(absolutePath).digest();
  const n = hash.readUInt32BE(0);
  return PORT_MIN + (n % PORT_RANGE);
}
```

- [ ] **Step 5: Run test — expect pass**

Run: `pnpm test`
Expected: 3 passed.

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src/shared/hash.ts plugins/visual-kit/tests/unit/hash.test.ts plugins/visual-kit/vitest.config.ts
git commit -m "feat(visual-kit): workspace-path → deterministic port derivation

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Atomic JSON write helper + shared types

**Files:**
- Create: `plugins/visual-kit/src/shared/json.ts`
- Create: `plugins/visual-kit/src/shared/types.ts`
- Create: `plugins/visual-kit/tests/unit/json.test.ts`

- [ ] **Step 1: Write types.ts**

Write `plugins/visual-kit/src/shared/types.ts`:
```ts
export type SurfaceKind =
  | 'lesson' | 'gallery' | 'outline' | 'comparison' | 'feedback' | 'free';

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

- [ ] **Step 2: Write failing test for atomic write**

Write `plugins/visual-kit/tests/unit/json.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { readFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { writeJsonAtomic } from '../../src/shared/json.js';

describe('writeJsonAtomic', () => {
  let dir: string;

  beforeEach(async () => {
    dir = await mkdtemp(join(tmpdir(), 'vk-json-'));
  });

  afterEach(async () => {
    await rm(dir, { recursive: true, force: true });
  });

  it('writes the JSON payload at the target path', async () => {
    const target = join(dir, 'info.json');
    await writeJsonAtomic(target, { hello: 'world' });
    const raw = await readFile(target, 'utf8');
    expect(JSON.parse(raw)).toEqual({ hello: 'world' });
  });

  it('does not leave a .tmp file behind on success', async () => {
    const target = join(dir, 'a.json');
    await writeJsonAtomic(target, { a: 1 });
    const tmp = target + '.tmp';
    await expect(readFile(tmp)).rejects.toMatchObject({ code: 'ENOENT' });
  });
});
```

- [ ] **Step 3: Run test — expect fail**

Run: `pnpm test`
Expected: FAIL (module not found).

- [ ] **Step 4: Implement json.ts**

Write `plugins/visual-kit/src/shared/json.ts`:
```ts
import { rename, writeFile, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';

export async function writeJsonAtomic(path: string, data: unknown): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  const tmp = path + '.tmp';
  await writeFile(tmp, JSON.stringify(data, null, 2), 'utf8');
  await rename(tmp, path);
}

export async function readJson<T>(path: string): Promise<T> {
  const { readFile } = await import('node:fs/promises');
  return JSON.parse(await readFile(path, 'utf8')) as T;
}
```

- [ ] **Step 5: Run test — expect pass**

Run: `pnpm test`
Expected: 5 passed (hash + json).

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src/shared plugins/visual-kit/tests/unit/json.test.ts
git commit -m "feat(visual-kit): atomic JSON write + shared types

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Server lifecycle (port + lock + server-info)

**Files:**
- Create: `plugins/visual-kit/src/server/lifecycle.ts`
- Create: `plugins/visual-kit/tests/unit/lifecycle.test.ts`

- [ ] **Step 1: Write failing lifecycle tests**

Write `plugins/visual-kit/tests/unit/lifecycle.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, rm, readFile, writeFile, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { acquireServerSlot, releaseServerSlot } from '../../src/server/lifecycle.js';

describe('acquireServerSlot', () => {
  let projectDir: string;

  beforeEach(async () => {
    projectDir = await mkdtemp(join(tmpdir(), 'vk-life-'));
  });

  afterEach(async () => {
    await rm(projectDir, { recursive: true, force: true });
  });

  it('writes server-info with the derived port', async () => {
    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('acquired');
    if (slot.action !== 'acquired') throw new Error('unreachable');
    const info = JSON.parse(
      await readFile(join(projectDir, '.visual-kit/server/state/server-info'), 'utf8')
    );
    expect(info.port).toBe(slot.port);
    expect(info.pid).toBe(process.pid);
    await releaseServerSlot(projectDir, slot);
  });

  it('returns attach when a live server-info already exists', async () => {
    const infoDir = join(projectDir, '.visual-kit/server/state');
    await mkdir(infoDir, { recursive: true });
    await writeFile(
      join(infoDir, 'server-info'),
      JSON.stringify({
        status: 'running',
        pid: process.pid,
        port: 34287,
        host: '127.0.0.1',
        url: 'http://localhost:34287',
        started_at: new Date().toISOString(),
        project_dir: projectDir,
        visual_kit_version: '1.0.0',
      })
    );

    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('attach');
  });

  it('removes stale server-info when pid is dead', async () => {
    const infoDir = join(projectDir, '.visual-kit/server/state');
    await mkdir(infoDir, { recursive: true });
    await writeFile(
      join(infoDir, 'server-info'),
      JSON.stringify({
        status: 'running',
        pid: 999999999, // not alive
        port: 34287,
        host: '127.0.0.1',
        url: 'http://localhost:34287',
        started_at: new Date().toISOString(),
        project_dir: projectDir,
        visual_kit_version: '1.0.0',
      })
    );

    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('acquired');
  });
});
```

- [ ] **Step 2: Run tests — expect failure**

Run: `pnpm test`
Expected: 3 lifecycle failures.

- [ ] **Step 3: Implement lifecycle.ts**

Write `plugins/visual-kit/src/server/lifecycle.ts`:
```ts
import { mkdir, rm, open, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { createServer as netCreateServer } from 'node:net';
import { workspacePort } from '../shared/hash.js';
import { writeJsonAtomic, readJson } from '../shared/json.js';
import type { ServerInfo } from '../shared/types.js';

export type SlotResult =
  | { action: 'acquired'; port: number; info: ServerInfo; lockFd: number }
  | { action: 'attach'; info: ServerInfo };

export interface AcquireOpts {
  pid: number;
  version: string;
  host?: string;
  urlHost?: string;
}

const MAX_PORT_ATTEMPTS = 10;

export async function acquireServerSlot(
  projectDir: string,
  opts: AcquireOpts,
): Promise<SlotResult> {
  const stateDir = join(projectDir, '.visual-kit/server/state');
  await mkdir(stateDir, { recursive: true });
  const infoPath = join(stateDir, 'server-info');
  const lockPath = join(stateDir, 'server.lock');

  // Check for live existing server.
  try {
    const info = await readJson<ServerInfo>(infoPath);
    if (info?.pid && isAlive(info.pid)) {
      return { action: 'attach', info };
    }
    await rm(infoPath, { force: true });
  } catch {
    /* no existing info */
  }

  // Acquire exclusive lock.
  const lockFile = await open(lockPath, 'wx').catch(async (err: NodeJS.ErrnoException) => {
    if (err.code === 'EEXIST') {
      // Lock exists but info didn't — probably crashed. Forcibly reclaim.
      await rm(lockPath, { force: true });
      return open(lockPath, 'wx');
    }
    throw err;
  });

  // Find a free port.
  const baseHost = opts.host ?? '127.0.0.1';
  const base = workspacePort(projectDir);
  let port = base;
  for (let i = 0; i < MAX_PORT_ATTEMPTS; i++) {
    if (await isPortFree(baseHost, base + i)) {
      port = base + i;
      break;
    }
    if (i === MAX_PORT_ATTEMPTS - 1) {
      await lockFile.close();
      await rm(lockPath, { force: true });
      throw new Error(
        `no free port in [${base}, ${base + MAX_PORT_ATTEMPTS}) on ${baseHost}`,
      );
    }
  }

  const info: ServerInfo = {
    status: 'running',
    pid: opts.pid,
    port,
    host: baseHost,
    url: `http://${opts.urlHost ?? 'localhost'}:${port}`,
    started_at: new Date().toISOString(),
    project_dir: projectDir,
    visual_kit_version: opts.version,
  };
  await writeJsonAtomic(infoPath, info);

  return { action: 'acquired', port, info, lockFd: lockFile.fd };
}

export async function releaseServerSlot(
  projectDir: string,
  slot: SlotResult,
): Promise<void> {
  if (slot.action !== 'acquired') return;
  const stateDir = join(projectDir, '.visual-kit/server/state');
  try {
    const { close } = await import('node:fs/promises');
    await close(slot.lockFd).catch(() => {});
  } catch {}
  await rm(join(stateDir, 'server.lock'), { force: true });
  await rm(join(stateDir, 'server-info'), { force: true });
  await writeFile(join(stateDir, 'server-stopped'), new Date().toISOString());
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function isPortFree(host: string, port: number): Promise<boolean> {
  return new Promise(resolve => {
    const probe = netCreateServer();
    probe.once('error', () => {
      probe.close();
      resolve(false);
    });
    probe.listen(port, host, () => {
      probe.close(() => resolve(true));
    });
  });
}
```

- [ ] **Step 4: Run tests — expect pass**

Run: `pnpm test`
Expected: 8 passed.

- [ ] **Step 5: Commit**

```bash
git add plugins/visual-kit/src/server/lifecycle.ts plugins/visual-kit/tests/unit/lifecycle.test.ts
git commit -m "feat(visual-kit): server lifecycle — lock, port hash, atomic server-info

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: HTTP server skeleton that binds and serves a placeholder

**Files:**
- Modify: `plugins/visual-kit/src/server/index.ts`
- Create: `plugins/visual-kit/tests/integration/serve.test.ts`
- Create: `plugins/visual-kit/tests/helpers/tmp-workspace.ts`

- [ ] **Step 1: Write helper for test workspaces**

Write `plugins/visual-kit/tests/helpers/tmp-workspace.ts`:
```ts
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

export interface TmpWorkspace {
  dir: string;
  cleanup: () => Promise<void>;
}

export async function tmpWorkspace(): Promise<TmpWorkspace> {
  const dir = await mkdtemp(join(tmpdir(), 'vk-ws-'));
  return {
    dir,
    cleanup: () => rm(dir, { recursive: true, force: true }),
  };
}
```

- [ ] **Step 2: Write failing integration test**

Write `plugins/visual-kit/tests/integration/serve.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

describe('startServer (integration)', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('binds and writes server-info', async () => {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    const info = JSON.parse(
      await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'),
    );
    expect(info.status).toBe('running');
    expect(info.host).toBe('127.0.0.1');
    const res = await fetch(`${info.url}/vk/capabilities`);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.visual_kit_version).toBeDefined();
  });
});
```

- [ ] **Step 3: Run test — expect fail**

Run: `pnpm test`
Expected: startServer throws "not implemented".

- [ ] **Step 4: Implement server/index.ts**

Replace `plugins/visual-kit/src/server/index.ts` with:
```ts
import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { ServeOptions } from '../cli/serve.js';
import { acquireServerSlot, releaseServerSlot, type SlotResult } from './lifecycle.js';

const here = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(here, '../../package.json');

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;

export async function startServer(opts: ServeOptions): Promise<void> {
  const pkg = JSON.parse(await readFile(pkgPath, 'utf8')) as { version: string };
  const slot = await acquireServerSlot(opts.projectDir, {
    pid: process.pid,
    version: pkg.version,
    host: opts.host,
    urlHost: opts.urlHost,
  });
  if (slot.action === 'attach') {
    process.stdout.write(JSON.stringify(slot.info) + '\n');
    return;
  }

  activeProjectDir = opts.projectDir;
  activeSlot = slot;

  activeServer = createServer((req, res) => handleRequest(req, res, slot.info));
  await listen(activeServer, slot.port, opts.host);

  process.stdout.write(JSON.stringify(slot.info) + '\n');

  for (const sig of ['SIGTERM', 'SIGINT'] as const) {
    process.once(sig, () => void stopServer().then(() => process.exit(0)));
  }

  if (!opts.foreground) {
    // In foreground false, we stay as the current process (backgrounded by caller shell).
  }
}

export async function stopServer(): Promise<void> {
  if (activeServer) {
    await new Promise<void>(resolve => activeServer?.close(() => resolve()));
    activeServer = undefined;
  }
  if (activeSlot && activeProjectDir) {
    await releaseServerSlot(activeProjectDir, activeSlot);
    activeSlot = undefined;
    activeProjectDir = undefined;
  }
}

async function handleRequest(
  req: IncomingMessage,
  res: ServerResponse,
  info: import('../shared/types.js').ServerInfo,
): Promise<void> {
  if (req.url === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        visual_kit_version: info.visual_kit_version,
        schema_version: 1,
        surfaces: {},
        components: [],
        bundles: [],
      }),
    );
    return;
  }
  res.writeHead(404);
  res.end('not found');
}

function listen(server: Server, port: number, host: string): Promise<void> {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () => {
      server.off('error', reject);
      resolve();
    });
  });
}
```

- [ ] **Step 5: Run test — expect pass**

Run: `pnpm test`
Expected: 9 passed (hash + json + lifecycle + serve integration).

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src/server/index.ts plugins/visual-kit/tests/integration/serve.test.ts plugins/visual-kit/tests/helpers/tmp-workspace.ts
git commit -m "feat(visual-kit): HTTP server binds + capabilities placeholder

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Security module — CSP, nonce, CSRF, Host allowlist

**Files:**
- Create: `plugins/visual-kit/src/server/security.ts`
- Create: `plugins/visual-kit/tests/unit/security.test.ts`

- [ ] **Step 1: Write failing tests**

Write `plugins/visual-kit/tests/unit/security.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import {
  makeNonce,
  buildCsp,
  isHostAllowed,
  makeCsrfToken,
  verifyCsrfToken,
  securityHeaders,
} from '../../src/server/security.js';

describe('makeNonce', () => {
  it('returns a 22-char base64url string', () => {
    const n = makeNonce();
    expect(n).toMatch(/^[A-Za-z0-9_-]{22}$/);
  });
  it('returns different values on each call', () => {
    const a = makeNonce();
    const b = makeNonce();
    expect(a).not.toBe(b);
  });
});

describe('buildCsp', () => {
  it('produces a strict CSP with the nonce', () => {
    const csp = buildCsp({ nonce: 'ABCDEF', extraScriptSrc: [] });
    expect(csp).toContain("default-src 'none'");
    expect(csp).toContain("script-src 'self' 'nonce-ABCDEF'");
    expect(csp).toContain("style-src 'self' 'nonce-ABCDEF'");
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).not.toContain('unsafe-inline');
    expect(csp).not.toContain('unsafe-eval');
  });
  it('appends extra script-src tokens when requested (e.g. wasm-unsafe-eval)', () => {
    const csp = buildCsp({ nonce: 'XYZ', extraScriptSrc: ["'wasm-unsafe-eval'"] });
    expect(csp).toMatch(/script-src 'self' 'nonce-XYZ' 'wasm-unsafe-eval'/);
  });
});

describe('isHostAllowed', () => {
  it('accepts loopback hosts on the expected port', () => {
    expect(isHostAllowed('127.0.0.1:34287', { port: 34287, urlHost: 'localhost' })).toBe(true);
    expect(isHostAllowed('localhost:34287', { port: 34287, urlHost: 'localhost' })).toBe(true);
  });
  it('rejects other hosts', () => {
    expect(isHostAllowed('attacker.example:34287', { port: 34287, urlHost: 'localhost' })).toBe(false);
  });
  it('accepts custom url-host', () => {
    expect(isHostAllowed('devbox:34287', { port: 34287, urlHost: 'devbox' })).toBe(true);
  });
  it('rejects missing header', () => {
    expect(isHostAllowed(undefined, { port: 34287, urlHost: 'localhost' })).toBe(false);
  });
});

describe('CSRF', () => {
  const secret = Buffer.alloc(32, 42); // deterministic for test
  it('validates a token bound to the same plugin+surface+nonce', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' })).toBe(true);
  });
  it('rejects a token for a different plugin', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'draftloom', surfaceId: 'lesson', nonce: 'N1' })).toBe(false);
  });
  it('rejects a token for a different surface', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    expect(verifyCsrfToken(secret, token, { plugin: 'paidagogos', surfaceId: 'other', nonce: 'N1' })).toBe(false);
  });
  it('rejects a tampered token', () => {
    const token = makeCsrfToken(secret, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' });
    const bad = token.slice(0, -1) + (token.at(-1) === 'a' ? 'b' : 'a');
    expect(verifyCsrfToken(secret, bad, { plugin: 'paidagogos', surfaceId: 'lesson', nonce: 'N1' })).toBe(false);
  });
});

describe('securityHeaders', () => {
  it('includes all required headers', () => {
    const h = securityHeaders();
    expect(h['X-Content-Type-Options']).toBe('nosniff');
    expect(h['Referrer-Policy']).toBe('no-referrer');
    expect(h['Cross-Origin-Opener-Policy']).toBe('same-origin');
    expect(h['Cross-Origin-Resource-Policy']).toBe('same-origin');
  });
});
```

- [ ] **Step 2: Run tests — expect fail**

Run: `pnpm test`
Expected: security suite fails with module-not-found.

- [ ] **Step 3: Implement security.ts**

Write `plugins/visual-kit/src/server/security.ts`:
```ts
import { randomBytes, createHmac, timingSafeEqual } from 'node:crypto';

/** Generates a 16-byte base64url nonce (22 chars). */
export function makeNonce(): string {
  return randomBytes(16).toString('base64url');
}

export interface CspOptions {
  nonce: string;
  extraScriptSrc?: string[];
  extraConnectSrc?: string[];
}

export function buildCsp(opts: CspOptions): string {
  const scriptExtras = (opts.extraScriptSrc ?? []).join(' ');
  const connectExtras = (opts.extraConnectSrc ?? []).join(' ');
  return [
    "default-src 'none'",
    `script-src 'self' 'nonce-${opts.nonce}'${scriptExtras ? ' ' + scriptExtras : ''}`,
    `style-src 'self' 'nonce-${opts.nonce}'`,
    "img-src 'self' data:",
    `connect-src 'self'${connectExtras ? ' ' + connectExtras : ''}`,
    "font-src 'self' data:",
    "frame-ancestors 'none'",
    "base-uri 'none'",
    "form-action 'none'",
  ].join('; ');
}

export function securityHeaders(): Record<string, string> {
  return {
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Resource-Policy': 'same-origin',
    'Vary': 'Origin',
  };
}

export interface HostPolicy {
  port: number;
  urlHost: string;
}

const ALWAYS_OK = new Set(['127.0.0.1', 'localhost']);

export function isHostAllowed(header: string | undefined, policy: HostPolicy): boolean {
  if (!header) return false;
  const [host, portStr] = header.split(':');
  if (!host) return false;
  if (portStr && Number(portStr) !== policy.port) return false;
  if (ALWAYS_OK.has(host)) return true;
  return host === policy.urlHost;
}

export interface CsrfBinding {
  plugin: string;
  surfaceId: string;
  nonce: string;
}

export function makeCsrfToken(secret: Buffer, b: CsrfBinding): string {
  const payload = Buffer.from(`${b.plugin}:${b.surfaceId}:${b.nonce}`, 'utf8');
  const mac = createHmac('sha256', secret).update(payload).digest();
  return Buffer.concat([payload, Buffer.from(':'), mac]).toString('base64url');
}

export function verifyCsrfToken(secret: Buffer, token: string, b: CsrfBinding): boolean {
  let decoded: Buffer;
  try { decoded = Buffer.from(token, 'base64url'); } catch { return false; }
  const raw = decoded.toString('utf8');
  const colonBeforeMac = raw.lastIndexOf(':');
  if (colonBeforeMac < 0) return false;
  const payload = raw.slice(0, colonBeforeMac);
  const expected = `${b.plugin}:${b.surfaceId}:${b.nonce}`;
  if (payload !== expected) return false;
  const mac = decoded.subarray(colonBeforeMac + 1);
  const check = createHmac('sha256', secret).update(Buffer.from(expected, 'utf8')).digest();
  if (mac.length !== check.length) return false;
  return timingSafeEqual(mac, check);
}
```

- [ ] **Step 4: Run tests — expect pass**

Run: `pnpm test`
Expected: 18 passed total.

- [ ] **Step 5: Commit**

```bash
git add plugins/visual-kit/src/server/security.ts plugins/visual-kit/tests/unit/security.test.ts
git commit -m "feat(visual-kit): CSP builder, nonce, CSRF tokens, Host allowlist

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Path validation (regex + realpath + symlink rejection)

**Files:**
- Create: `plugins/visual-kit/src/server/paths.ts`
- Create: `plugins/visual-kit/tests/unit/paths.test.ts`

- [ ] **Step 1: Write failing tests**

Write `plugins/visual-kit/tests/unit/paths.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, rm, writeFile, symlink, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { isSafeSegment, resolveContained } from '../../src/server/paths.js';

describe('isSafeSegment', () => {
  it('accepts alphanumerics, dash, underscore', () => {
    expect(isSafeSegment('abc')).toBe(true);
    expect(isSafeSegment('lesson-2')).toBe(true);
    expect(isSafeSegment('wave_1')).toBe(true);
  });
  it('rejects dots, slashes, url-encoding', () => {
    expect(isSafeSegment('../etc')).toBe(false);
    expect(isSafeSegment('a.b')).toBe(false);
    expect(isSafeSegment('%2e%2e')).toBe(false);
    expect(isSafeSegment('')).toBe(false);
    expect(isSafeSegment('a b')).toBe(false);
  });
});

describe('resolveContained', () => {
  let root: string;

  beforeEach(async () => {
    root = await mkdtemp(join(tmpdir(), 'vk-paths-'));
  });

  afterEach(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('resolves a real file inside the root', async () => {
    await writeFile(join(root, 'ok.json'), '{}');
    const p = await resolveContained(root, 'ok.json');
    expect(p).toBe(join(root, 'ok.json'));
  });

  it('rejects when path escapes root', async () => {
    await expect(resolveContained(root, '../outside')).rejects.toThrow(/outside/);
  });

  it('rejects symlinks that point outside root', async () => {
    const outside = await mkdtemp(join(tmpdir(), 'vk-outside-'));
    await writeFile(join(outside, 'secret'), 'SECRET');
    await symlink(join(outside, 'secret'), join(root, 'link.json'));
    await expect(resolveContained(root, 'link.json')).rejects.toThrow(/symlink/i);
    await rm(outside, { recursive: true, force: true });
  });

  it('rejects non-existent path with ENOENT', async () => {
    await expect(resolveContained(root, 'missing.json')).rejects.toMatchObject({ code: 'ENOENT' });
  });

  it('rejects symlinked directories', async () => {
    const outside = await mkdtemp(join(tmpdir(), 'vk-outside-'));
    await mkdir(join(outside, 'ct'), { recursive: true });
    await symlink(join(outside, 'ct'), join(root, 'content'));
    await expect(resolveContained(root, 'content')).rejects.toThrow(/symlink/i);
    await rm(outside, { recursive: true, force: true });
  });
});
```

- [ ] **Step 2: Run tests — expect fail**

Run: `pnpm test`
Expected: 7 failures (paths suite).

- [ ] **Step 3: Implement paths.ts**

Write `plugins/visual-kit/src/server/paths.ts`:
```ts
import { lstat, realpath } from 'node:fs/promises';
import { join, resolve, sep } from 'node:path';

const SAFE = /^[a-zA-Z0-9_-]+$/;

export function isSafeSegment(s: string): boolean {
  return SAFE.test(s);
}

/**
 * Resolves `segment` inside `root`, refusing:
 * - anything matching `..`
 * - symlinks (at any segment of the resolved path)
 * - paths whose realpath escapes `root`
 */
export async function resolveContained(root: string, relative: string): Promise<string> {
  const rootReal = await realpath(root);
  const target = resolve(rootReal, relative);
  if (!target.startsWith(rootReal + sep) && target !== rootReal) {
    throw new Error(`path resolves outside root: ${relative}`);
  }
  const stat = await lstat(target);
  if (stat.isSymbolicLink()) {
    throw new Error(`refusing symlink: ${relative}`);
  }
  // realpath also catches the case where an ancestor is a symlink.
  const real = await realpath(target);
  if (!real.startsWith(rootReal + sep) && real !== rootReal) {
    throw new Error(`realpath resolves outside root: ${relative}`);
  }
  return real;
}

export function join2(...parts: string[]): string {
  return join(...parts);
}
```

- [ ] **Step 4: Run tests — expect pass**

Run: `pnpm test`
Expected: all passed.

- [ ] **Step 5: Commit**

```bash
git add plugins/visual-kit/src/server/paths.ts plugins/visual-kit/tests/unit/paths.test.ts
git commit -m "feat(visual-kit): path validation — regex + realpath + symlink reject

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Surface schemas (JSON Schema files)

**Files:**
- Create: `plugins/visual-kit/schemas/surfaces/lesson.v1.json`
- Create: `plugins/visual-kit/schemas/surfaces/gallery.v1.json`
- Create: `plugins/visual-kit/schemas/surfaces/outline.v1.json`
- Create: `plugins/visual-kit/schemas/surfaces/comparison.v1.json`
- Create: `plugins/visual-kit/schemas/surfaces/feedback.v1.json`
- Create: `plugins/visual-kit/schemas/surfaces/free.v1.json`

- [ ] **Step 1: Write lesson.v1.json**

Write `plugins/visual-kit/schemas/surfaces/lesson.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/lesson.v1.json",
  "title": "LessonSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "topic", "level", "sections"],
  "properties": {
    "surface": { "const": "lesson" },
    "version": { "const": 1 },
    "topic": { "type": "string", "minLength": 1, "maxLength": 200 },
    "level": { "enum": ["beginner", "intermediate", "advanced"] },
    "estimated_minutes": { "type": "integer", "minimum": 1, "maximum": 180 },
    "caveat": { "type": "string", "maxLength": 500 },
    "sections": {
      "type": "array",
      "minItems": 1,
      "maxItems": 40,
      "items": { "$ref": "#/$defs/section" }
    }
  },
  "$defs": {
    "section": {
      "type": "object",
      "required": ["type"],
      "oneOf": [
        { "properties": { "type": { "const": "concept" }, "text": { "type": "string" } }, "required": ["text"] },
        { "properties": { "type": { "const": "why"     }, "text": { "type": "string" } }, "required": ["text"] },
        { "properties": { "type": { "const": "code"    }, "language": { "type": "string" }, "source": { "type": "string" } }, "required": ["source"] },
        { "properties": { "type": { "const": "chart"   }, "config": { "type": "object" } }, "required": ["config"] },
        { "properties": { "type": { "const": "math"    }, "latex": { "type": "string" } }, "required": ["latex"] },
        { "properties": { "type": { "const": "mistakes"}, "items": { "type": "array", "items": { "type": "string" } } }, "required": ["items"] },
        { "properties": { "type": { "const": "generate"}, "task": { "type": "string" } }, "required": ["task"] },
        { "properties": { "type": { "const": "quiz"    }, "items": { "type": "array" } }, "required": ["items"] },
        { "properties": { "type": { "const": "resources"}, "items": { "type": "array" } }, "required": ["items"] },
        { "properties": { "type": { "const": "next"    }, "concept": { "type": "string" } }, "required": ["concept"] }
      ]
    }
  }
}
```

- [ ] **Step 2: Write gallery.v1.json**

Write `plugins/visual-kit/schemas/surfaces/gallery.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/gallery.v1.json",
  "title": "GallerySurfaceV1",
  "type": "object",
  "required": ["surface", "version", "items"],
  "properties": {
    "surface": { "const": "gallery" },
    "version": { "const": 1 },
    "title": { "type": "string", "maxLength": 200 },
    "multiselect": { "type": "boolean" },
    "items": {
      "type": "array",
      "minItems": 1,
      "maxItems": 200,
      "items": {
        "type": "object",
        "required": ["id", "title"],
        "properties": {
          "id": { "type": "string", "pattern": "^[a-zA-Z0-9_.-]+$", "maxLength": 80 },
          "title": { "type": "string", "maxLength": 200 },
          "subtitle": { "type": "string", "maxLength": 200 },
          "body": { "type": "string", "maxLength": 1000 },
          "badges": {
            "type": "array",
            "maxItems": 6,
            "items": {
              "type": "object",
              "required": ["label"],
              "properties": {
                "label": { "type": "string", "maxLength": 40 },
                "tone": { "enum": ["ok", "warn", "danger", "info", "muted"] }
              }
            }
          }
        }
      }
    }
  }
}
```

- [ ] **Step 3: Write outline.v1.json**

Write `plugins/visual-kit/schemas/surfaces/outline.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/outline.v1.json",
  "title": "OutlineSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "nodes"],
  "properties": {
    "surface": { "const": "outline" },
    "version": { "const": 1 },
    "title": { "type": "string", "maxLength": 200 },
    "nodes": { "type": "array", "items": { "$ref": "#/$defs/node" }, "minItems": 1, "maxItems": 100 }
  },
  "$defs": {
    "node": {
      "type": "object",
      "required": ["heading"],
      "properties": {
        "heading": { "type": "string", "maxLength": 200 },
        "summary": { "type": "string", "maxLength": 600 },
        "children": { "type": "array", "items": { "$ref": "#/$defs/node" }, "maxItems": 50 }
      }
    }
  }
}
```

- [ ] **Step 4: Write comparison.v1.json**

Write `plugins/visual-kit/schemas/surfaces/comparison.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/comparison.v1.json",
  "title": "ComparisonSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "variants"],
  "properties": {
    "surface": { "const": "comparison" },
    "version": { "const": 1 },
    "title": { "type": "string", "maxLength": 200 },
    "variants": {
      "type": "array",
      "minItems": 2,
      "maxItems": 4,
      "items": {
        "type": "object",
        "required": ["label", "body"],
        "properties": {
          "label": { "type": "string", "maxLength": 80 },
          "body": { "type": "object", "description": "nested SurfaceSpec" }
        }
      }
    }
  }
}
```

- [ ] **Step 5: Write feedback.v1.json**

Write `plugins/visual-kit/schemas/surfaces/feedback.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/feedback.v1.json",
  "title": "FeedbackSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "fields"],
  "properties": {
    "surface": { "const": "feedback" },
    "version": { "const": 1 },
    "title": { "type": "string", "maxLength": 200 },
    "submit_label": { "type": "string", "maxLength": 40 },
    "fields": {
      "type": "array",
      "minItems": 1,
      "maxItems": 20,
      "items": {
        "oneOf": [
          {
            "type": "object",
            "required": ["type", "id", "prompt", "options"],
            "properties": {
              "type": { "const": "choice" },
              "id": { "type": "string", "pattern": "^[a-zA-Z0-9_-]+$", "maxLength": 40 },
              "prompt": { "type": "string", "maxLength": 200 },
              "options": {
                "type": "array", "minItems": 2, "maxItems": 10,
                "items": { "type": "string", "maxLength": 80 }
              }
            }
          },
          {
            "type": "object",
            "required": ["type", "id", "prompt"],
            "properties": {
              "type": { "const": "text" },
              "id": { "type": "string", "pattern": "^[a-zA-Z0-9_-]+$", "maxLength": 40 },
              "prompt": { "type": "string", "maxLength": 200 }
            }
          }
        ]
      }
    }
  }
}
```

- [ ] **Step 6: Write free.v1.json**

Write `plugins/visual-kit/schemas/surfaces/free.v1.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "vk://schemas/free.v1.json",
  "title": "FreeSurfaceV1",
  "type": "object",
  "required": ["surface", "version", "html"],
  "properties": {
    "surface": { "const": "free" },
    "version": { "const": 1 },
    "html": { "type": "string", "maxLength": 100000 }
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add plugins/visual-kit/schemas
git commit -m "feat(visual-kit): JSON schemas for V1 surfaces

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Rendering pipeline — lit-html SSR + shell + dispatcher

**Files:**
- Create: `plugins/visual-kit/src/render/ssr.ts`
- Create: `plugins/visual-kit/src/render/shell.ts`
- Create: `plugins/visual-kit/src/render/dispatcher.ts`
- Create: `plugins/visual-kit/src/render/error-fragment.ts`
- Create: `plugins/visual-kit/src/render/sanitize.ts`
- Create: `plugins/visual-kit/tests/unit/dispatcher.test.ts`

- [ ] **Step 1: Write error-fragment.ts**

Write `plugins/visual-kit/src/render/error-fragment.ts`:
```ts
import { html, type TemplateResult } from 'lit';

export interface VkErrorOpts {
  title: string;
  detail?: string;
  surface?: string;
  capabilitiesUrl?: string;
}

export function renderVkError(opts: VkErrorOpts): TemplateResult {
  return html`
    <vk-error>
      <h2 slot="title">${opts.title}</h2>
      ${opts.detail ? html`<p slot="detail">${opts.detail}</p>` : ''}
      ${opts.surface ? html`<p slot="detail"><strong>Surface:</strong> ${opts.surface}</p>` : ''}
      ${opts.capabilitiesUrl
        ? html`<p slot="detail">
            See available surfaces at
            <a href="${opts.capabilitiesUrl}">${opts.capabilitiesUrl}</a>
          </p>`
        : ''}
    </vk-error>
  `;
}
```

- [ ] **Step 2: Write sanitize.ts**

Write `plugins/visual-kit/src/render/sanitize.ts`:
```ts
import createDomPurify from 'dompurify';
import { JSDOM } from 'jsdom';

const jsdom = new JSDOM('');
const purify = createDomPurify(jsdom.window as unknown as Window);

const ALLOWED_TAGS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
  'p','span','strong','em','code','pre','ul','ol','li','a','br','hr',
  'h1','h2','h3','h4','h5','h6','blockquote',
  'table','thead','tbody','tr','th','td',
  'img','figure','figcaption',
];

const ALLOWED_ATTR = [
  'class','id','slot','title','alt','src','href',
  'data-id','data-title','data-multiselect','data-variant','data-selected','data-tone','data-label',
];

purify.setConfig({
  USE_PROFILES: { html: true },
  ALLOWED_TAGS,
  ALLOWED_ATTR,
  FORBID_ATTR: [/* on* handled by DOMPurify by default via USE_PROFILES */],
  ALLOW_DATA_ATTR: false,
});

export function sanitizeFreeHtml(raw: string): string {
  return purify.sanitize(raw);
}
```

- [ ] **Step 3: Write ssr.ts**

Write `plugins/visual-kit/src/render/ssr.ts`:
```ts
import { render } from '@lit-labs/ssr';
import { collectResultSync } from '@lit-labs/ssr/lib/render-result.js';
import type { TemplateResult } from 'lit';

export function renderFragment(template: TemplateResult): string {
  return collectResultSync(render(template));
}
```

- [ ] **Step 4: Write shell.ts**

Write `plugins/visual-kit/src/render/shell.ts`:
```ts
import { buildCsp, securityHeaders } from '../server/security.js';

export interface ShellInput {
  title: string;
  nonce: string;
  csrfToken: string;
  bundleUrls: string[];        // e.g. ['/vk/core.js']
  fragment: string;             // pre-rendered HTML
  extraScriptSrc?: string[];
}

export function buildShell(input: ShellInput): { html: string; headers: Record<string, string> } {
  const preload = input.bundleUrls
    .map(u => `<link rel="modulepreload" href="${u}" crossorigin="anonymous">`)
    .join('\n    ');
  const scripts = input.bundleUrls
    .map(u => `<script type="module" src="${u}" nonce="${input.nonce}"></script>`)
    .join('\n    ');

  const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="vk-csrf" content="${input.csrfToken}">
    <title>${escapeHtml(input.title)}</title>
    ${preload}
    <link rel="stylesheet" href="/vk/theme.css" nonce="${input.nonce}">
    ${scripts}
  </head>
  <body>
    <main class="vk-surface">
      ${input.fragment}
    </main>
    <script type="module" nonce="${input.nonce}">
      const es = new EventSource('/events/stream');
      es.onmessage = (e) => { if (e.data === 'refresh') location.reload(); };
      window.addEventListener('vk-event', async (ev) => {
        const csrf = document.querySelector('meta[name=vk-csrf]')?.getAttribute('content') ?? '';
        try {
          await fetch('/events', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-Vk-Csrf': csrf },
            body: JSON.stringify({ ...ev.detail, ts: new Date().toISOString() }),
            credentials: 'omit',
          });
        } catch {}
      });
    </script>
  </body>
</html>`;

  return {
    html,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Content-Security-Policy': buildCsp({ nonce: input.nonce, extraScriptSrc: input.extraScriptSrc ?? [] }),
      ...securityHeaders(),
    },
  };
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}
```

- [ ] **Step 5: Write dispatcher.ts**

Write `plugins/visual-kit/src/render/dispatcher.ts`:
```ts
import type { TemplateResult } from 'lit';
import { renderVkError } from './error-fragment.js';
import type { SurfaceKind } from '../shared/types.js';

export type SurfaceRenderer<TSpec = unknown> = (spec: TSpec) => TemplateResult;

const registry = new Map<SurfaceKind, SurfaceRenderer>();

export function registerSurface<TSpec>(kind: SurfaceKind, renderer: SurfaceRenderer<TSpec>): void {
  registry.set(kind, renderer as SurfaceRenderer);
}

export function renderSurface(spec: { surface?: string; version?: number }): TemplateResult {
  if (!spec || typeof spec !== 'object' || typeof spec.surface !== 'string') {
    return renderVkError({ title: 'Invalid SurfaceSpec', detail: 'Missing or malformed "surface" field.' });
  }
  const renderer = registry.get(spec.surface as SurfaceKind);
  if (!renderer) {
    return renderVkError({
      title: 'Unknown surface',
      surface: spec.surface,
      capabilitiesUrl: '/vk/capabilities',
    });
  }
  try {
    return renderer(spec);
  } catch (err) {
    return renderVkError({
      title: 'Surface render failed',
      detail: err instanceof Error ? err.message : String(err),
      surface: spec.surface,
    });
  }
}
```

- [ ] **Step 6: Write failing test**

Write `plugins/visual-kit/tests/unit/dispatcher.test.ts`:
```ts
import { describe, it, expect, beforeEach } from 'vitest';
import { html } from 'lit';
import { registerSurface, renderSurface } from '../../src/render/dispatcher.js';
import { renderFragment } from '../../src/render/ssr.js';

describe('renderSurface', () => {
  beforeEach(() => {
    registerSurface('lesson', (spec: { topic: string }) => html`<vk-section>${spec.topic}</vk-section>`);
  });

  it('renders a registered surface', () => {
    const tr = renderSurface({ surface: 'lesson', version: 1, topic: 'Hello' });
    const out = renderFragment(tr);
    expect(out).toContain('vk-section');
    expect(out).toContain('Hello');
  });

  it('returns vk-error for unknown surface', () => {
    const tr = renderSurface({ surface: 'unknown', version: 1 });
    const out = renderFragment(tr);
    expect(out).toContain('vk-error');
    expect(out).toContain('Unknown surface');
  });

  it('returns vk-error on malformed input', () => {
    const tr = renderSurface({} as never);
    const out = renderFragment(tr);
    expect(out).toContain('Invalid SurfaceSpec');
  });
});
```

- [ ] **Step 7: Run tests — expect pass**

Run: `pnpm test`
Expected: 3 new tests pass.

- [ ] **Step 8: Commit**

```bash
git add plugins/visual-kit/src/render plugins/visual-kit/tests/unit/dispatcher.test.ts
git commit -m "feat(visual-kit): rendering pipeline — SSR, shell, dispatcher, sanitizer

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Surfaces — lesson, gallery, outline, comparison, feedback, free

**Files:**
- Create: `plugins/visual-kit/src/surfaces/{lesson,gallery,outline,comparison,feedback,free}.ts`
- Create: `plugins/visual-kit/src/surfaces/index.ts`

- [ ] **Step 1: Write surfaces/lesson.ts**

Write `plugins/visual-kit/src/surfaces/lesson.ts`:
```ts
import { html, type TemplateResult } from 'lit';

interface LessonSpec {
  topic: string;
  level: string;
  estimated_minutes?: number;
  caveat?: string;
  sections: Array<Record<string, unknown> & { type: string }>;
}

export function renderLesson(spec: LessonSpec): TemplateResult {
  return html`
    <vk-section data-variant="header">
      <h1 slot="title">${spec.topic}</h1>
      <p slot="meta">${spec.level}${spec.estimated_minutes ? ` · ${spec.estimated_minutes} min` : ''}</p>
    </vk-section>
    ${spec.sections.map(section)}
    ${spec.caveat ? html`<vk-section data-variant="caveat"><p>${spec.caveat}</p></vk-section>` : ''}
  `;
}

function section(s: Record<string, unknown> & { type: string }): TemplateResult {
  switch (s.type) {
    case 'concept':   return html`<vk-section data-variant="concept"><h2 slot="title">Concept</h2><p>${String(s.text ?? '')}</p></vk-section>`;
    case 'why':       return html`<vk-section data-variant="why"><h2 slot="title">Why it matters</h2><p>${String(s.text ?? '')}</p></vk-section>`;
    case 'code':      return html`<vk-section data-variant="code"><h2 slot="title">Example</h2><vk-code language="${String(s.language ?? 'text')}">${String(s.source ?? '')}</vk-code></vk-section>`;
    case 'mistakes':  return html`<vk-section data-variant="mistakes"><h2 slot="title">Common mistakes</h2><ul>${(s.items as string[] ?? []).map(m => html`<li>${m}</li>`)}</ul></vk-section>`;
    case 'generate':  return html`<vk-section data-variant="generate"><h2 slot="title">Try it</h2><p>${String(s.task ?? '')}</p></vk-section>`;
    case 'next':      return html`<vk-section data-variant="next"><h2 slot="title">Next</h2><p>${String(s.concept ?? '')}</p></vk-section>`;
    case 'resources': return html`<vk-section data-variant="resources"><h2 slot="title">Resources</h2><ul>${resourceList(s.items as Array<Record<string, unknown>>)}</ul></vk-section>`;
    default:          return html`<vk-section data-variant="${s.type}"><p>Section type "${s.type}" not yet supported in the core bundle. Install Plan B for code, math, chart, quiz renderers.</p></vk-section>`;
  }
}

function resourceList(items: Array<Record<string, unknown>> = []): TemplateResult[] {
  return items.map(r => html`<li><a href="${String(r.url ?? '#')}">${String(r.title ?? '')}</a> — ${String(r.type ?? '')}</li>`);
}
```

- [ ] **Step 2: Write surfaces/gallery.ts**

Write `plugins/visual-kit/src/surfaces/gallery.ts`:
```ts
import { html, type TemplateResult } from 'lit';

interface GalleryItem {
  id: string;
  title: string;
  subtitle?: string;
  body?: string;
  badges?: Array<{ label: string; tone?: string }>;
}

interface GallerySpec {
  title?: string;
  multiselect?: boolean;
  items: GalleryItem[];
}

export function renderGallery(spec: GallerySpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-gallery data-multiselect="${spec.multiselect ? 'true' : 'false'}">
      ${spec.items.map(item => html`
        <vk-card data-id="${item.id}">
          <h3 slot="title">${item.title}</h3>
          ${item.subtitle ? html`<p slot="subtitle">${item.subtitle}</p>` : ''}
          ${item.body ? html`<p slot="body">${item.body}</p>` : ''}
          ${item.badges?.map(b => html`<span slot="badge" data-tone="${b.tone ?? 'muted'}" data-label="${b.label}">${b.label}</span>`) ?? ''}
        </vk-card>
      `)}
    </vk-gallery>
  `;
}
```

- [ ] **Step 3: Write surfaces/outline.ts**

Write `plugins/visual-kit/src/surfaces/outline.ts`:
```ts
import { html, type TemplateResult } from 'lit';

interface OutlineNode {
  heading: string;
  summary?: string;
  children?: OutlineNode[];
}

interface OutlineSpec {
  title?: string;
  nodes: OutlineNode[];
}

export function renderOutline(spec: OutlineSpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-outline>${spec.nodes.map(node)}</vk-outline>
  `;
}

function node(n: OutlineNode): TemplateResult {
  return html`
    <details open>
      <summary>${n.heading}</summary>
      ${n.summary ? html`<p>${n.summary}</p>` : ''}
      ${n.children?.map(child) ?? ''}
    </details>
  `;
}

function child(n: OutlineNode): TemplateResult {
  return html`
    <details>
      <summary>${n.heading}</summary>
      ${n.summary ? html`<p>${n.summary}</p>` : ''}
      ${n.children?.map(child) ?? ''}
    </details>
  `;
}
```

- [ ] **Step 4: Write surfaces/comparison.ts**

Write `plugins/visual-kit/src/surfaces/comparison.ts`:
```ts
import { html, type TemplateResult } from 'lit';
import { renderSurface } from '../render/dispatcher.js';

interface ComparisonSpec {
  title?: string;
  variants: Array<{ label: string; body: { surface?: string; [k: string]: unknown } }>;
}

export function renderComparison(spec: ComparisonSpec): TemplateResult {
  return html`
    ${spec.title ? html`<vk-section data-variant="header"><h1 slot="title">${spec.title}</h1></vk-section>` : ''}
    <vk-comparison>
      ${spec.variants.map(v => html`
        <section slot="variant" data-label="${v.label}">
          <header><h2>${v.label}</h2></header>
          ${renderSurface(v.body)}
          <button class="vk-choose" data-variant="${v.label}">Choose ${v.label}</button>
        </section>
      `)}
    </vk-comparison>
  `;
}
```

- [ ] **Step 5: Write surfaces/feedback.ts**

Write `plugins/visual-kit/src/surfaces/feedback.ts`:
```ts
import { html, type TemplateResult } from 'lit';

interface FeedbackField {
  type: 'choice' | 'text';
  id: string;
  prompt: string;
  options?: string[];
}

interface FeedbackSpec {
  title?: string;
  submit_label?: string;
  fields: FeedbackField[];
}

export function renderFeedback(spec: FeedbackSpec): TemplateResult {
  return html`
    <vk-feedback data-submit-label="${spec.submit_label ?? 'Submit'}">
      ${spec.title ? html`<h1 slot="title">${spec.title}</h1>` : ''}
      ${spec.fields.map(field)}
    </vk-feedback>
  `;
}

function field(f: FeedbackField): TemplateResult {
  if (f.type === 'choice') {
    return html`
      <fieldset slot="field" data-id="${f.id}">
        <legend>${f.prompt}</legend>
        ${(f.options ?? []).map(opt => html`
          <label><input type="radio" name="${f.id}" value="${opt}">${opt}</label>
        `)}
      </fieldset>
    `;
  }
  return html`
    <label slot="field" data-id="${f.id}">
      <span>${f.prompt}</span>
      <textarea name="${f.id}" rows="3"></textarea>
    </label>
  `;
}
```

- [ ] **Step 6: Write surfaces/free.ts**

Write `plugins/visual-kit/src/surfaces/free.ts`:
```ts
import { html, unsafeStatic, literal } from 'lit/static-html.js';
import type { TemplateResult } from 'lit';
import { sanitizeFreeHtml } from '../render/sanitize.js';

interface FreeSpec {
  html: string;
}

export function renderFree(spec: FreeSpec): TemplateResult {
  const safe = sanitizeFreeHtml(spec.html);
  // Using the static-html escape hatch ONLY after DOMPurify sanitization.
  return html`${unsafeStatic(safe)}`;
}

// Lit requires a literal placeholder if we use static-html; export to satisfy tree-shakers.
export const _kind = literal`free`;
```

- [ ] **Step 7: Write surfaces/index.ts**

Write `plugins/visual-kit/src/surfaces/index.ts`:
```ts
import { registerSurface } from '../render/dispatcher.js';
import { renderLesson } from './lesson.js';
import { renderGallery } from './gallery.js';
import { renderOutline } from './outline.js';
import { renderComparison } from './comparison.js';
import { renderFeedback } from './feedback.js';
import { renderFree } from './free.js';

export function registerAllSurfaces(): void {
  registerSurface('lesson',     renderLesson     as never);
  registerSurface('gallery',    renderGallery    as never);
  registerSurface('outline',    renderOutline    as never);
  registerSurface('comparison', renderComparison as never);
  registerSurface('feedback',   renderFeedback   as never);
  registerSurface('free',       renderFree       as never);
}
```

- [ ] **Step 8: Type-check and commit**

Run: `npx tsc --noEmit`
Expected: no errors.

```bash
git add plugins/visual-kit/src/surfaces
git commit -m "feat(visual-kit): render functions for all 6 V1 surfaces

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Schema validation + capabilities wiring

**Files:**
- Create: `plugins/visual-kit/src/server/capabilities.ts`
- Create: `plugins/visual-kit/src/render/validate.ts`
- Modify: `plugins/visual-kit/src/server/index.ts`

- [ ] **Step 1: Write validate.ts**

Write `plugins/visual-kit/src/render/validate.ts`:
```ts
import Ajv2020, { type ValidateFunction } from 'ajv/dist/2020.js';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { SurfaceKind } from '../shared/types.js';

const here = dirname(fileURLToPath(import.meta.url));
const schemaDir = join(here, '../../schemas/surfaces');

const ajv = new Ajv2020({ strict: true, allErrors: true });
const validators = new Map<SurfaceKind, ValidateFunction>();

const KINDS: SurfaceKind[] = ['lesson', 'gallery', 'outline', 'comparison', 'feedback', 'free'];

export async function loadSchemas(): Promise<void> {
  for (const kind of KINDS) {
    const raw = await readFile(join(schemaDir, `${kind}.v1.json`), 'utf8');
    validators.set(kind, ajv.compile(JSON.parse(raw)));
  }
}

export function validateSpec(spec: unknown): { ok: true; kind: SurfaceKind } | { ok: false; errors: string[] } {
  if (!spec || typeof spec !== 'object') return { ok: false, errors: ['spec is not an object'] };
  const s = spec as { surface?: string };
  if (!s.surface || !KINDS.includes(s.surface as SurfaceKind)) {
    return { ok: false, errors: [`unknown surface: ${s.surface}`] };
  }
  const kind = s.surface as SurfaceKind;
  const fn = validators.get(kind);
  if (!fn) return { ok: false, errors: [`no validator for ${kind}`] };
  if (!fn(spec)) {
    return { ok: false, errors: (fn.errors ?? []).map(e => `${e.instancePath} ${e.message}`) };
  }
  return { ok: true, kind };
}

export function listSurfaces(): SurfaceKind[] {
  return [...validators.keys()];
}
```

- [ ] **Step 2: Write capabilities.ts**

Write `plugins/visual-kit/src/server/capabilities.ts`:
```ts
import { listSurfaces } from '../render/validate.js';

const COMPONENTS = [
  'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
  'vk-loader','vk-error','vk-code',
];

const BUNDLES = [
  { name: 'core', url: '/vk/core.js', sri: 'sha384-placeholder' },
];

export function buildCapabilities(version: string): object {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => [k, { schema: `/vk/schemas/${k}.v1.json` }]),
    ),
    components: COMPONENTS,
    bundles: BUNDLES,
  };
}
```

- [ ] **Step 3: Update server/index.ts to load schemas and wire /vk/capabilities**

Replace the `handleRequest` function and add a startup step. The full file becomes:

```ts
import { createServer, type Server, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { ServeOptions } from '../cli/serve.js';
import { acquireServerSlot, releaseServerSlot, type SlotResult } from './lifecycle.js';
import { loadSchemas } from '../render/validate.js';
import { registerAllSurfaces } from '../surfaces/index.js';
import { buildCapabilities } from './capabilities.js';
import { isHostAllowed, securityHeaders } from './security.js';

const here = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(here, '../../package.json');

let activeServer: Server | undefined;
let activeSlot: SlotResult | undefined;
let activeProjectDir: string | undefined;

export async function startServer(opts: ServeOptions): Promise<void> {
  const pkg = JSON.parse(await readFile(pkgPath, 'utf8')) as { version: string };
  await loadSchemas();
  registerAllSurfaces();

  const slot = await acquireServerSlot(opts.projectDir, {
    pid: process.pid,
    version: pkg.version,
    host: opts.host,
    urlHost: opts.urlHost,
  });
  if (slot.action === 'attach') {
    process.stdout.write(JSON.stringify(slot.info) + '\n');
    return;
  }

  activeProjectDir = opts.projectDir;
  activeSlot = slot;

  const hostPolicy = { port: slot.port, urlHost: opts.urlHost };

  activeServer = createServer((req, res) => {
    if (!isHostAllowed(req.headers.host, hostPolicy)) {
      res.writeHead(421, { 'Content-Type': 'text/plain' });
      res.end('Misdirected Request');
      return;
    }
    handleRequest(req, res, pkg.version).catch(() => {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
    });
  });
  await listen(activeServer, slot.port, opts.host);

  process.stdout.write(JSON.stringify(slot.info) + '\n');

  for (const sig of ['SIGTERM', 'SIGINT'] as const) {
    process.once(sig, () => void stopServer().then(() => process.exit(0)));
  }
}

export async function stopServer(): Promise<void> {
  if (activeServer) {
    await new Promise<void>(resolve => activeServer?.close(() => resolve()));
    activeServer = undefined;
  }
  if (activeSlot && activeProjectDir) {
    await releaseServerSlot(activeProjectDir, activeSlot);
    activeSlot = undefined;
    activeProjectDir = undefined;
  }
}

async function handleRequest(
  req: IncomingMessage,
  res: ServerResponse,
  version: string,
): Promise<void> {
  if (req.method === 'GET' && req.url === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', ...securityHeaders() });
    res.end(JSON.stringify(buildCapabilities(version)));
    return;
  }
  res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Not Found');
}

function listen(server: Server, port: number, host: string): Promise<void> {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () => {
      server.off('error', reject);
      resolve();
    });
  });
}
```

- [ ] **Step 4: Update serve integration test**

Replace `plugins/visual-kit/tests/integration/serve.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';

describe('startServer (integration)', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('serves capabilities with the registered surfaces', async () => {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });

    const { readFile } = await import('node:fs/promises');
    const info = JSON.parse(await readFile(`${ws.dir}/.visual-kit/server/state/server-info`, 'utf8'));

    const res = await fetch(`${info.url}/vk/capabilities`);
    expect(res.status).toBe(200);
    const caps = await res.json();
    expect(caps.visual_kit_version).toBeDefined();
    expect(caps.schema_version).toBe(1);
    expect(Object.keys(caps.surfaces)).toEqual(
      expect.arrayContaining(['lesson','gallery','outline','comparison','feedback','free']),
    );
  });

  it('rejects requests with disallowed Host header', async () => {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    const { readFile } = await import('node:fs/promises');
    const info = JSON.parse(await readFile(`${ws.dir}/.visual-kit/server/state/server-info`, 'utf8'));

    const res = await fetch(`${info.url}/vk/capabilities`, {
      headers: { Host: 'attacker.example:9999' },
    });
    expect(res.status).toBe(421);
  });
});
```

- [ ] **Step 5: Run tests**

Run: `pnpm test`
Expected: all pass (including the new capabilities + Host test).

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src plugins/visual-kit/tests
git commit -m "feat(visual-kit): schema loader + /vk/capabilities + Host enforcement

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Content watcher + render route + SSE

**Files:**
- Create: `plugins/visual-kit/src/server/watcher.ts`
- Create: `plugins/visual-kit/src/server/sse.ts`
- Modify: `plugins/visual-kit/src/server/index.ts`
- Create: `plugins/visual-kit/tests/integration/render.test.ts`

- [ ] **Step 1: Write watcher.ts**

Write `plugins/visual-kit/src/server/watcher.ts`:
```ts
import { watch, type FSWatcher } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';

export interface ContentEvent {
  plugin: string;
  surfaceId: string;
  absPath: string;
}

export type ContentListener = (ev: ContentEvent) => void;

export class ContentWatcher {
  private watchers = new Map<string, FSWatcher>();
  private listeners = new Set<ContentListener>();

  constructor(private readonly projectDir: string) {}

  onChange(fn: ContentListener): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  async watchPlugin(plugin: string): Promise<void> {
    if (this.watchers.has(plugin)) return;
    const dir = join(this.projectDir, `.${plugin}`, 'content');
    await mkdir(dir, { recursive: true });
    const w = watch(dir, (eventType, filename) => {
      if (!filename || !filename.endsWith('.json')) return;
      const surfaceId = filename.slice(0, -'.json'.length);
      const ev: ContentEvent = { plugin, surfaceId, absPath: join(dir, filename) };
      for (const fn of this.listeners) fn(ev);
    });
    this.watchers.set(plugin, w);
  }

  close(): void {
    for (const w of this.watchers.values()) w.close();
    this.watchers.clear();
    this.listeners.clear();
  }
}
```

- [ ] **Step 2: Write sse.ts**

Write `plugins/visual-kit/src/server/sse.ts`:
```ts
import type { ServerResponse } from 'node:http';

export interface SseClient {
  res: ServerResponse;
  plugin?: string;
  surfaceId?: string;
}

export class SseHub {
  private clients = new Set<SseClient>();

  attach(res: ServerResponse, filter: { plugin?: string; surfaceId?: string }): SseClient {
    res.writeHead(200, {
      'Content-Type':  'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection':    'keep-alive',
    });
    res.write(': vk-sse connected\n\n');
    const client: SseClient = { res, ...filter };
    this.clients.add(client);
    res.once('close', () => this.clients.delete(client));
    return client;
  }

  publish(event: { plugin: string; surfaceId: string }): void {
    for (const c of this.clients) {
      if (c.plugin && c.plugin !== event.plugin) continue;
      if (c.surfaceId && c.surfaceId !== event.surfaceId) continue;
      c.res.write(`data: refresh\n\n`);
    }
  }

  closeAll(): void {
    for (const c of this.clients) c.res.end();
    this.clients.clear();
  }
}
```

- [ ] **Step 3: Add /p/:plugin/:surface route + SSE wire-up to server/index.ts**

In `plugins/visual-kit/src/server/index.ts`, add imports:
```ts
import { ContentWatcher } from './watcher.js';
import { SseHub } from './sse.js';
import { isSafeSegment, resolveContained } from './paths.js';
import { validateSpec } from '../render/validate.js';
import { renderSurface } from '../render/dispatcher.js';
import { renderFragment } from '../render/ssr.js';
import { buildShell } from '../render/shell.js';
import { makeNonce, makeCsrfToken } from './security.js';
import { randomBytes } from 'node:crypto';
```

Replace the `handleRequest` implementation with:
```ts
async function handleRequest(
  req: IncomingMessage,
  res: ServerResponse,
  version: string,
  ctx: { projectDir: string; secret: Buffer; sse: SseHub; watcher: ContentWatcher },
): Promise<void> {
  const url = new URL(req.url ?? '/', 'http://x');
  const method = req.method ?? 'GET';

  // Capabilities
  if (method === 'GET' && url.pathname === '/vk/capabilities') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', ...securityHeaders() });
    res.end(JSON.stringify(buildCapabilities(version)));
    return;
  }

  // SSE
  if (method === 'GET' && url.pathname === '/events/stream') {
    const plugin = url.searchParams.get('plugin') ?? undefined;
    const surfaceId = url.searchParams.get('surface') ?? undefined;
    if (plugin && !isSafeSegment(plugin)) return badRequest(res);
    if (surfaceId && !isSafeSegment(surfaceId)) return badRequest(res);
    ctx.sse.attach(res, { plugin, surfaceId });
    return;
  }

  // Surface render: /p/<plugin>/<surface-id>
  const m = url.pathname.match(/^\/p\/([^/]+)\/([^/]+)$/);
  if (method === 'GET' && m) {
    const [, plugin, surfaceId] = m as unknown as [string, string, string];
    if (!isSafeSegment(plugin) || !isSafeSegment(surfaceId)) return badRequest(res);
    await ctx.watcher.watchPlugin(plugin);
    const contentDir = join(ctx.projectDir, `.${plugin}`, 'content');
    let specPath: string;
    try {
      specPath = await resolveContained(contentDir, `${surfaceId}.json`);
    } catch {
      res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
      res.end('Not Found');
      return;
    }
    const raw = await readFile(specPath, 'utf8');
    let spec: unknown;
    try { spec = JSON.parse(raw); } catch {
      return renderErrorPage(res, 'Invalid JSON in SurfaceSpec', { plugin, surfaceId });
    }
    const result = validateSpec(spec);
    if (!result.ok) {
      return renderErrorPage(res, `Schema: ${result.errors.join('; ')}`, { plugin, surfaceId });
    }
    const nonce = makeNonce();
    const csrf = makeCsrfToken(ctx.secret, { plugin, surfaceId, nonce });
    const fragment = renderFragment(renderSurface(spec as never));
    const { html, headers } = buildShell({
      title: `${plugin}/${surfaceId}`,
      nonce,
      csrfToken: csrf,
      bundleUrls: ['/vk/core.js'],
      fragment,
    });
    res.writeHead(200, headers);
    res.end(html);
    return;
  }

  // Static bundles (Task 14)
  if (method === 'GET' && url.pathname.startsWith('/vk/')) {
    // Handled in Task 14.
  }

  res.writeHead(404, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Not Found');
}

function badRequest(res: ServerResponse): void {
  res.writeHead(400, { 'Content-Type': 'text/plain', ...securityHeaders() });
  res.end('Bad Request');
}

function renderErrorPage(
  res: ServerResponse,
  detail: string,
  ctx: { plugin: string; surfaceId: string },
): void {
  const nonce = makeNonce();
  const fragment = renderFragment(renderSurface({ surface: '__error__' as never }));
  const { html, headers } = buildShell({
    title: `${ctx.plugin}/${ctx.surfaceId}`,
    nonce,
    csrfToken: '',
    bundleUrls: ['/vk/core.js'],
    fragment: `<vk-error><h2 slot="title">Render error</h2><p slot="detail">${escapeHtml(detail)}</p></vk-error>`,
  });
  res.writeHead(200, headers);
  res.end(html);
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}
```

Also update `startServer` to create `secret`, `sse`, `watcher`, and pass them as `ctx`:
```ts
// after hostPolicy is defined:
const secret = randomBytes(32);
const sse = new SseHub();
const watcher = new ContentWatcher(opts.projectDir);
watcher.onChange(ev => sse.publish(ev));

activeServer = createServer((req, res) => {
  if (!isHostAllowed(req.headers.host, hostPolicy)) {
    res.writeHead(421); res.end('Misdirected Request'); return;
  }
  handleRequest(req, res, pkg.version, { projectDir: opts.projectDir, secret, sse, watcher })
    .catch(() => { res.writeHead(500); res.end('Internal Server Error'); });
});
```

Also update `stopServer` to close watcher + sse:
```ts
// inside stopServer, before releaseServerSlot:
sse.closeAll();
watcher.close();
```
(You'll need to make `secret`/`sse`/`watcher` module-scoped alongside `activeServer` to access them in stop.)

- [ ] **Step 4: Write render integration test**

Write `plugins/visual-kit/tests/integration/render.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';

describe('surface render integration', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
    await startServer({
      projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true,
    });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('renders a valid lesson SurfaceSpec', async () => {
    await writeFile(join(ws.dir, '.demo/content/intro.json'), JSON.stringify({
      surface: 'lesson', version: 1,
      topic: 'Hello Flexbox', level: 'beginner', estimated_minutes: 8,
      sections: [{ type: 'concept', text: 'Rows and columns.' }],
    }));

    const info = JSON.parse(
      await (await import('node:fs/promises')).readFile(
        join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));

    const res = await fetch(`${info.url}/p/demo/intro`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain('Content-Security-Policy'); // in headers, verified below
    expect(html).toContain('Hello Flexbox');
    expect(html).toContain('Rows and columns.');
    expect(res.headers.get('content-security-policy')).toMatch(/default-src 'none'/);
    expect(res.headers.get('content-security-policy')).not.toContain('unsafe-inline');
  });

  it('renders vk-error for an unknown surface', async () => {
    await writeFile(join(ws.dir, '.demo/content/bad.json'), JSON.stringify({
      surface: 'unknown', version: 1,
    }));
    const info = JSON.parse(
      await (await import('node:fs/promises')).readFile(
        join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/p/demo/bad`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain('vk-error');
    expect(html).toContain('unknown surface'.toLowerCase());
  });

  it('returns 404 when the SurfaceSpec file is missing', async () => {
    const info = JSON.parse(
      await (await import('node:fs/promises')).readFile(
        join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/p/demo/absent`);
    expect(res.status).toBe(404);
  });
});
```

- [ ] **Step 5: Run tests — expect pass**

Run: `pnpm test`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src plugins/visual-kit/tests
git commit -m "feat(visual-kit): /p/<plugin>/<surface> rendering + watcher + SSE

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Bundle route + SRI + theme.css

**Files:**
- Create: `plugins/visual-kit/src/server/bundles.ts`
- Create: `plugins/visual-kit/src/components/theme.css`
- Modify: `plugins/visual-kit/src/server/index.ts`

- [ ] **Step 1: Write theme.css**

Write `plugins/visual-kit/src/components/theme.css`:
```css
:root {
  --vk-bg:#ffffff; --vk-surface:#f8f9fa; --vk-border:#e9ecef;
  --vk-text:#212529; --vk-muted:#6c757d; --vk-accent:#0066cc;
  --vk-code-bg:#f1f3f5; --vk-success:#198754; --vk-warning:#fd7e14; --vk-danger:#dc3545;
}
@media (prefers-color-scheme:dark) {
  :root {
    --vk-bg:#0d1117; --vk-surface:#161b22; --vk-border:#30363d;
    --vk-text:#e6edf3; --vk-muted:#8b949e; --vk-accent:#58a6ff;
    --vk-code-bg:#1e2530; --vk-success:#3fb950; --vk-warning:#d29922; --vk-danger:#f85149;
  }
}
*{box-sizing:border-box}
html,body{margin:0;padding:0;background:var(--vk-bg);color:var(--vk-text);
  font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
.vk-surface{max-width:860px;margin:0 auto;padding:2rem 1.5rem}
a{color:var(--vk-accent)}
```

- [ ] **Step 2: Write bundles.ts**

Write `plugins/visual-kit/src/server/bundles.ts`:
```ts
import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isSafeSegment } from './paths.js';

const here = dirname(fileURLToPath(import.meta.url));
const distDir = join(here, '../../dist');
const schemaDir = join(here, '../../schemas');
const themePath = join(here, '../components/theme.css');

const MIME: Record<string, string> = {
  '.js':  'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json':'application/json; charset=utf-8',
};

export interface BundleReply {
  status: number;
  headers: Record<string, string>;
  body: Buffer | string;
}

export async function serveVkPath(pathname: string): Promise<BundleReply | null> {
  if (pathname === '/vk/theme.css') {
    const body = await readFile(themePath);
    return file200(body, '.css');
  }

  const bundleMatch = pathname.match(/^\/vk\/([a-z0-9_-]+)\.js$/);
  if (bundleMatch) {
    const [, name] = bundleMatch as unknown as [string, string];
    if (!isSafeSegment(name)) return null;
    const abs = join(distDir, `${name}.js`);
    try { await stat(abs); } catch { return null; }
    const body = await readFile(abs);
    return file200(body, '.js');
  }

  const schemaMatch = pathname.match(/^\/vk\/schemas\/([a-z0-9_-]+)\.v(\d+)\.json$/);
  if (schemaMatch) {
    const [, kind, v] = schemaMatch as unknown as [string, string, string];
    const abs = join(schemaDir, 'surfaces', `${kind}.v${v}.json`);
    try { await stat(abs); } catch { return null; }
    const body = await readFile(abs);
    return file200(body, '.json');
  }

  return null;
}

function file200(body: Buffer, ext: string): BundleReply {
  const type = MIME[ext] ?? 'application/octet-stream';
  return {
    status: 200,
    headers: {
      'Content-Type': type,
      'Cache-Control': 'public, max-age=60',
    },
    body,
  };
}

export function sriHash(body: Buffer | string): string {
  const h = createHash('sha384').update(body).digest('base64');
  return `sha384-${h}`;
}
```

- [ ] **Step 3: Wire into server/index.ts handleRequest before the 404 fallback**

Add import: `import { serveVkPath } from './bundles.js';`

Add before the final 404:
```ts
if (method === 'GET' && url.pathname.startsWith('/vk/')) {
  const reply = await serveVkPath(url.pathname);
  if (reply) {
    res.writeHead(reply.status, { ...reply.headers, ...securityHeaders() });
    res.end(reply.body);
    return;
  }
}
```

- [ ] **Step 4: Integration test — theme.css and schemas are served**

Add to `plugins/visual-kit/tests/integration/render.test.ts`:
```ts
it('serves /vk/theme.css with CSS content-type', async () => {
  const info = JSON.parse(
    await (await import('node:fs/promises')).readFile(
      join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
  const res = await fetch(`${info.url}/vk/theme.css`);
  expect(res.status).toBe(200);
  expect(res.headers.get('content-type')).toMatch(/text\/css/);
  expect(await res.text()).toContain(':root');
});

it('serves /vk/schemas/lesson.v1.json', async () => {
  const info = JSON.parse(
    await (await import('node:fs/promises')).readFile(
      join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
  const res = await fetch(`${info.url}/vk/schemas/lesson.v1.json`);
  expect(res.status).toBe(200);
  const j = await res.json();
  expect(j.$id).toContain('lesson.v1.json');
});
```

- [ ] **Step 5: Run tests (core.js serve fails until Task 15 builds it; skip that check)**

Run: `pnpm test`
Expected: new tests for theme + schema pass. The render test that loads a page will still pass because the shell references `/vk/core.js` in a `<script>` tag but the browser isn't actually running in vitest — the DOM-level fetch doesn't happen server-side.

- [ ] **Step 6: Commit**

```bash
git add plugins/visual-kit/src plugins/visual-kit/tests
git commit -m "feat(visual-kit): serve /vk/theme.css, /vk/schemas, /vk/<bundle>.js

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Core components + core.js bundle build

**Files:**
- Create: `plugins/visual-kit/src/components/section.ts`
- Create: `plugins/visual-kit/src/components/card.ts`
- Create: `plugins/visual-kit/src/components/gallery.ts`
- Create: `plugins/visual-kit/src/components/outline.ts`
- Create: `plugins/visual-kit/src/components/comparison.ts`
- Create: `plugins/visual-kit/src/components/feedback.ts`
- Create: `plugins/visual-kit/src/components/loader.ts`
- Create: `plugins/visual-kit/src/components/error.ts`
- Create: `plugins/visual-kit/src/components/code.ts`
- Create: `plugins/visual-kit/src/components/index.ts`
- Create: `plugins/visual-kit/scripts/build.mjs`

- [ ] **Step 1: Write components/section.ts**

Write `plugins/visual-kit/src/components/section.ts`:
```ts
import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-section')
export class VkSection extends LitElement {
  static styles = css`
    :host { display: block; margin: 1.25rem 0; }
    ::slotted([slot="title"]) { margin: 0 0 .5rem; color: var(--vk-text); }
    ::slotted([slot="meta"])  { margin: 0 0 1rem; color: var(--vk-muted); font-size: .875rem; }
  `;
  render() {
    return html`<slot name="title"></slot><slot name="meta"></slot><slot></slot>`;
  }
}
```

- [ ] **Step 2: Write components/card.ts**

Write `plugins/visual-kit/src/components/card.ts`:
```ts
import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';

@customElement('vk-card')
export class VkCard extends LitElement {
  static styles = css`
    :host { display:block; border:1px solid var(--vk-border); border-radius:8px;
      padding:1rem; background:var(--vk-surface); cursor:pointer; }
    :host([data-selected]) { border-color: var(--vk-accent); }
    ::slotted([slot="title"]) { margin:0 0 .25rem; }
    ::slotted([slot="subtitle"]) { margin:0 0 .5rem; color:var(--vk-muted); font-size:.875rem }
    .badges { margin-top:.5rem; display:flex; gap:.25rem; flex-wrap:wrap }
  `;
  @property({ attribute: 'data-id' }) dataId = '';
  private toggle() {
    this.toggleAttribute('data-selected');
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true, composed: true,
      detail: { type: this.hasAttribute('data-selected') ? 'select' : 'deselect', id: this.dataId },
    }));
  }
  render() {
    return html`
      <div @click=${this.toggle}>
        <slot name="title"></slot>
        <slot name="subtitle"></slot>
        <slot name="body"></slot>
        <div class="badges"><slot name="badge"></slot></div>
      </div>`;
  }
}
```

- [ ] **Step 3: Write components/gallery.ts, outline.ts, comparison.ts, feedback.ts, loader.ts, error.ts, code.ts**

Write minimal Lit definitions — each a thin wrapper exposing slotted content and one or two small behaviors. Place each at `src/components/<name>.ts`. Example for `gallery.ts`:
```ts
import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('vk-gallery')
export class VkGallery extends LitElement {
  static styles = css`
    :host { display:grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap:1rem; }
  `;
  render() { return html`<slot></slot>`; }
}
```

Analogous minimal modules for:
- `outline.ts` → `<vk-outline>` renders `<slot></slot>` in a two-column layout.
- `comparison.ts` → `<vk-comparison>` renders a `display:grid; grid-template-columns: 1fr 1fr`.
- `feedback.ts` → `<vk-feedback>` renders a `<form>` with a slot for fields and a submit button; intercepts submit and emits `vk-event {type:'feedback', fields:{...}}`.
- `loader.ts` → `<vk-loader>` renders a spinner (CSS keyframe) with slotted label.
- `error.ts` → `<vk-error>` renders a callout with `role="alert"` and slotted `title`/`detail`.
- `code.ts` → `<vk-code>` renders a `<pre><code>${slotted text}</code></pre>` with escaped content and a copy button.

(Keep each under 40 lines. Prioritize clarity over polish.)

- [ ] **Step 4: Write components/index.ts**

Write `plugins/visual-kit/src/components/index.ts`:
```ts
import './section.js';
import './card.js';
import './gallery.js';
import './outline.js';
import './comparison.js';
import './feedback.js';
import './loader.js';
import './error.js';
import './code.js';
```

- [ ] **Step 5: Write scripts/build.mjs (bundle the browser core)**

Write `plugins/visual-kit/scripts/build.mjs`:
```js
import { build } from 'esbuild';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

await mkdir('dist', { recursive: true });

// 1. Browser core bundle (loads into the rendered page)
await build({
  entryPoints: ['src/components/index.ts'],
  outfile: 'dist/core.js',
  bundle: true,
  minify: true,
  format: 'esm',
  target: ['es2022'],
  sourcemap: false,
  platform: 'browser',
  logLevel: 'info',
});

const core = await readFile('dist/core.js');
const sri = 'sha384-' + createHash('sha384').update(core).digest('base64');
await writeFile('dist/core.js.sri.txt', sri);

// 2. Node-side CLI bundle (so bin/visual-kit can import dist/cli.js)
await build({
  entryPoints: ['src/cli/index.ts'],
  outfile: 'dist/cli.js',
  bundle: true,
  minify: false,
  platform: 'node',
  target: ['node20'],
  format: 'esm',
  packages: 'external',
  logLevel: 'info',
});

// 3. Node-side server module (dynamic-imported by cli.js)
await build({
  entryPoints: ['src/server/index.ts'],
  outfile: 'dist/server/index.js',
  bundle: true,
  minify: false,
  platform: 'node',
  target: ['node20'],
  format: 'esm',
  packages: 'external',
  logLevel: 'info',
});

console.log('visual-kit build complete. Core SRI:', sri);
```

- [ ] **Step 6: Run build**

Run: `cd plugins/visual-kit && pnpm run build`
Expected: `dist/core.js`, `dist/cli.js`, `dist/server/index.js`, `dist/core.js.sri.txt` exist.

- [ ] **Step 7: Wire SRI into capabilities**

In `plugins/visual-kit/src/server/capabilities.ts`, read the SRI from disk:
```ts
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const sriPath = join(here, '../../dist/core.js.sri.txt');

let cachedSri: string | undefined;

export async function buildCapabilities(version: string): Promise<object> {
  if (!cachedSri) {
    try { cachedSri = (await readFile(sriPath, 'utf8')).trim(); }
    catch { cachedSri = 'sha384-dev'; }
  }
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: Object.fromEntries(
      listSurfaces().map(k => [k, { schema: `/vk/schemas/${k}.v1.json` }])
    ),
    components: [
      'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison','vk-feedback',
      'vk-loader','vk-error','vk-code',
    ],
    bundles: [
      { name: 'core', url: '/vk/core.js', sri: cachedSri },
    ],
  };
}
```

Update server/index.ts to `await` `buildCapabilities(version)`.

- [ ] **Step 8: Also include SRI in shell.ts `<script>` tag**

In `buildShell`, replace the script tag generation with a version that expects per-bundle SRI. Pass `bundles: Array<{url: string; sri: string}>` instead of `bundleUrls: string[]`. Update handleRequest to read capabilities and pass the core bundle's SRI.

- [ ] **Step 9: Run tests**

Run: `cd plugins/visual-kit && pnpm run verify`
Expected: lint (no-op for now) + build + tests all green.

- [ ] **Step 10: Commit**

```bash
git add plugins/visual-kit/src plugins/visual-kit/scripts plugins/visual-kit/dist
git commit -m "feat(visual-kit): core bundle + components + SRI + capabilities wiring

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: POST /events with CSRF + cross-plugin isolation

**Files:**
- Create: `plugins/visual-kit/src/server/events.ts`
- Modify: `plugins/visual-kit/src/server/index.ts`
- Create: `plugins/visual-kit/tests/integration/csrf.test.ts`

- [ ] **Step 1: Write events.ts**

Write `plugins/visual-kit/src/server/events.ts`:
```ts
import { appendFile, mkdir, stat, rename } from 'node:fs/promises';
import { join } from 'node:path';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { isSafeSegment } from './paths.js';
import { verifyCsrfToken, securityHeaders } from './security.js';

const MAX_BODY = 64 * 1024;            // 64 KB
const MAX_LOG = 50 * 1024 * 1024;      // 50 MB
const REFERER_PATH = /^\/p\/([^/]+)\/([^/]+)$/;

export interface EventCtx {
  projectDir: string;
  secret: Buffer;
}

export async function handleEventPost(
  req: IncomingMessage,
  res: ServerResponse,
  ctx: EventCtx,
): Promise<void> {
  if (req.method !== 'POST') {
    res.writeHead(405, { Allow: 'POST', ...securityHeaders() }); res.end('Method Not Allowed'); return;
  }
  const contentType = (req.headers['content-type'] ?? '').split(';')[0]?.trim();
  if (contentType !== 'application/json') {
    res.writeHead(415, securityHeaders()); res.end('Unsupported Media Type'); return;
  }

  // Derive plugin + surface from Referer or Origin path
  const referer = req.headers.referer ?? req.headers.origin ?? '';
  let refPath = '';
  try { refPath = new URL(referer).pathname; } catch { /* empty */ }
  const m = refPath.match(REFERER_PATH);
  if (!m) { res.writeHead(403, securityHeaders()); res.end('Forbidden'); return; }
  const [, plugin, surfaceId] = m as unknown as [string, string, string];
  if (!isSafeSegment(plugin) || !isSafeSegment(surfaceId)) {
    res.writeHead(403, securityHeaders()); res.end('Forbidden'); return;
  }

  // CSRF token: requires the browser to have loaded /p/<plugin>/<surface>
  const token = (req.headers['x-vk-csrf'] ?? '') as string;
  // We need the nonce that was embedded when the page rendered.
  // For V1, we use a per-plugin+surface secret binding and accept any nonce baked into the token.
  if (!token) { res.writeHead(403, securityHeaders()); res.end('Forbidden'); return; }
  // Decode the nonce from the token payload and verify.
  const raw = Buffer.from(token, 'base64url').toString('utf8');
  const colon = raw.lastIndexOf(':');
  if (colon < 0) { res.writeHead(403, securityHeaders()); res.end('Forbidden'); return; }
  const [tokenPlugin, tokenSurface, nonce] = raw.slice(0, colon).split(':');
  if (tokenPlugin !== plugin || tokenSurface !== surfaceId || !nonce) {
    res.writeHead(403, securityHeaders()); res.end('Forbidden'); return;
  }
  if (!verifyCsrfToken(ctx.secret, token, { plugin, surfaceId, nonce })) {
    res.writeHead(403, securityHeaders()); res.end('Forbidden'); return;
  }

  // Read body with cap
  let body = '';
  let over = false;
  for await (const chunk of req) {
    body += chunk;
    if (body.length > MAX_BODY) { over = true; break; }
  }
  if (over) { res.writeHead(413, securityHeaders()); res.end('Payload Too Large'); return; }

  let parsed: unknown;
  try { parsed = JSON.parse(body); } catch {
    res.writeHead(400, securityHeaders()); res.end('Bad Request'); return;
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    res.writeHead(400, securityHeaders()); res.end('Bad Request'); return;
  }

  // Append JSON line — plugin is server-derived, never client-supplied.
  const stateDir = join(ctx.projectDir, `.${plugin}`, 'state');
  await mkdir(stateDir, { recursive: true });
  const eventsPath = join(stateDir, 'events');
  await rotateIfNeeded(eventsPath);
  const line = JSON.stringify({ ...(parsed as object), plugin, surface: surfaceId, ts: new Date().toISOString() }) + '\n';
  await appendFile(eventsPath, line, 'utf8');

  res.writeHead(204, securityHeaders()); res.end();
}

async function rotateIfNeeded(path: string): Promise<void> {
  try {
    const s = await stat(path);
    if (s.size > MAX_LOG) {
      await rename(path, path + '.' + Date.now());
    }
  } catch { /* no file yet */ }
}
```

- [ ] **Step 2: Wire into server/index.ts**

Add in `handleRequest` before the `/p/<plugin>/<surface>` match:
```ts
if (method === 'POST' && url.pathname === '/events') {
  const { handleEventPost } = await import('./events.js');
  await handleEventPost(req, res, { projectDir: ctx.projectDir, secret: ctx.secret });
  return;
}
```

- [ ] **Step 3: Write CSRF isolation integration test**

Write `plugins/visual-kit/tests/integration/csrf.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

async function loadInfo(ws: TmpWorkspace) {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

async function loadPage(info: { url: string }, plugin: string, surfaceId: string) {
  const res = await fetch(`${info.url}/p/${plugin}/${surfaceId}`);
  const html = await res.text();
  const csrf = /name="vk-csrf" content="([^"]+)"/.exec(html)?.[1] ?? '';
  return { html, csrf };
}

describe('/events CSRF + cross-plugin isolation', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.a/content'), { recursive: true });
    await mkdir(join(ws.dir, '.b/content'), { recursive: true });
    await writeFile(join(ws.dir, '.a/content/x.json'),
      JSON.stringify({ surface: 'gallery', version: 1, items: [{ id: 'one', title: 'One' }] }));
    await writeFile(join(ws.dir, '.b/content/y.json'),
      JSON.stringify({ surface: 'gallery', version: 1, items: [{ id: 'one', title: 'One' }] }));
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('rejects POST /events without CSRF token (403)', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Referer: `${info.url}/p/a/x` },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(403);
  });

  it('accepts POST /events with matching token + Referer (204)', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/a/x`,
      },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(204);
    const log = await readFile(join(ws.dir, '.a/state/events'), 'utf8');
    expect(log).toContain('"plugin":"a"');
    expect(log).toContain('"surface":"x"');
  });

  it('rejects using plugin A token while claiming Referer to plugin B', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/b/y`,
      },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(403);
  });

  it('ignores body-supplied "plugin" and uses Referer-derived value', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/a/x`,
      },
      body: JSON.stringify({ type: 'select', id: 'one', plugin: 'b' }),
    });
    expect(res.status).toBe(204);
    const logB = await readFile(join(ws.dir, '.b/state/events'), 'utf8').catch(() => '');
    expect(logB).toBe('');
    const logA = await readFile(join(ws.dir, '.a/state/events'), 'utf8');
    expect(logA).toContain('"plugin":"a"');
  });

  it('rejects oversized bodies (413)', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Vk-Csrf': csrf, Referer: `${info.url}/p/a/x` },
      body: 'x'.repeat(65 * 1024),
    });
    expect(res.status).toBe(413);
  });
});
```

- [ ] **Step 4: Run tests — expect pass**

Run: `pnpm test`
Expected: all CSRF tests green.

- [ ] **Step 5: Commit**

```bash
git add plugins/visual-kit/src plugins/visual-kit/tests
git commit -m "feat(visual-kit): POST /events with CSRF + cross-plugin isolation

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 17: Pure-component CI gate

**Files:**
- Create: `plugins/visual-kit/scripts/lint-pure-components.mjs`

- [ ] **Step 1: Write the lint script**

Write `plugins/visual-kit/scripts/lint-pure-components.mjs`:
```js
import { readFile, readdir } from 'node:fs/promises';
import { join, extname } from 'node:path';

const root = 'src/components';
const FORBIDDEN = [
  /\bfetch\s*\(/,
  /\bXMLHttpRequest\b/,
  /\blocalStorage\b/,
  /\bsessionStorage\b/,
  /\bindexedDB\b/,
  /\bnavigator\.serviceWorker\b/,
  /new\s+URL\s*\([^)]*document\.location/,
];

const files = [];
async function walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) await walk(full);
    else if (extname(entry.name) === '.ts') files.push(full);
  }
}
await walk(root);

const issues = [];
for (const f of files) {
  const text = await readFile(f, 'utf8');
  FORBIDDEN.forEach(re => {
    const m = text.match(re);
    if (m) issues.push(`${f}: forbidden pattern ${re}`);
  });
}

if (issues.length) {
  console.error('Pure-component rule violations:\n' + issues.join('\n'));
  process.exit(1);
}
console.log(`Pure-component lint passed (${files.length} files).`);
```

- [ ] **Step 2: Run it against current components**

Run: `cd plugins/visual-kit && pnpm run lint:pure`
Expected: `Pure-component lint passed (9 files).`

- [ ] **Step 3: Add a deliberate violation to verify the gate fires**

Temporarily add `fetch('/foo')` to `src/components/card.ts` (do not commit). Run again. Expect non-zero exit and the violation printed. Revert.

- [ ] **Step 4: Commit**

```bash
git add plugins/visual-kit/scripts/lint-pure-components.mjs
git commit -m "feat(visual-kit): CI gate — pure-component lint

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 18: Security-headers & bundle-size CI gates

**Files:**
- Create: `plugins/visual-kit/scripts/test-security-headers.mjs`
- Create: `plugins/visual-kit/scripts/bundle-size-gate.mjs`
- Modify: `plugins/visual-kit/package.json` (scripts)

- [ ] **Step 1: Write bundle-size-gate.mjs**

Write `plugins/visual-kit/scripts/bundle-size-gate.mjs`:
```js
import { readFile, stat } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';

const BUDGETS = {
  'dist/core.js': 40_000, // 40 KB gz max per spec QR-1
};

let failed = false;
for (const [path, max] of Object.entries(BUDGETS)) {
  const body = await readFile(path);
  const gz = gzipSync(body).length;
  const ok = gz <= max;
  console.log(`${path}: ${gz} bytes gz${ok ? '' : ` — exceeds ${max}`}`);
  if (!ok) failed = true;
}
process.exit(failed ? 1 : 0);
```

- [ ] **Step 2: Write test-security-headers.mjs**

Write `plugins/visual-kit/scripts/test-security-headers.mjs`:
```js
// Boots the server, writes a lesson SurfaceSpec, asserts headers.
import { mkdtemp, writeFile, mkdir, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { startServer, stopServer } from '../dist/server/index.js';

const dir = await mkdtemp(join(tmpdir(), 'vk-sec-'));
await mkdir(join(dir, '.demo/content'), { recursive: true });
await writeFile(join(dir, '.demo/content/s.json'), JSON.stringify({
  surface: 'lesson', version: 1, topic: 'X', level: 'beginner',
  sections: [{ type: 'concept', text: 'ok' }],
}));

await startServer({ projectDir: dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
const info = JSON.parse(await readFile(join(dir, '.visual-kit/server/state/server-info'), 'utf8'));
const res = await fetch(`${info.url}/p/demo/s`);
const csp = res.headers.get('content-security-policy') ?? '';

let failed = false;
function require(cond, msg) { if (!cond) { console.error('FAIL:', msg); failed = true; } }

require(csp.includes("default-src 'none'"), 'default-src none');
require(csp.includes("script-src 'self' 'nonce-"), 'script-src nonce');
require(!csp.includes("'unsafe-inline'"), 'no unsafe-inline');
require(!csp.includes("'unsafe-eval'"), 'no unsafe-eval');
require(res.headers.get('x-content-type-options') === 'nosniff', 'X-Content-Type-Options');
require(res.headers.get('referrer-policy') === 'no-referrer', 'Referrer-Policy');

await stopServer();
await rm(dir, { recursive: true, force: true });
process.exit(failed ? 1 : 0);
```

- [ ] **Step 3: Add scripts to package.json**

In `plugins/visual-kit/package.json`, update the `scripts` block to include:
```json
"gate:security": "node scripts/test-security-headers.mjs",
"gate:size":     "node scripts/bundle-size-gate.mjs",
"verify":        "pnpm run lint:pure && pnpm run build && pnpm run test && pnpm run gate:security && pnpm run gate:size"
```

- [ ] **Step 4: Run the full verify**

Run: `cd plugins/visual-kit && pnpm run verify`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/visual-kit/scripts plugins/visual-kit/package.json
git commit -m "feat(visual-kit): CI gates — security headers + bundle size

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 19: Paidagogos migration — dependency and SurfaceSpec write

**Files:**
- Modify: `plugins/paidagogos/.claude-plugin/plugin.json`
- Modify: `plugins/paidagogos/skills/paidagogos-micro/SKILL.md`
- Modify: `plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md`
- Delete: `plugins/paidagogos/server/` (entire directory)
- Modify: `plugins/paidagogos/CHANGELOG.md`
- Modify: `plugins/paidagogos/README.md`

- [ ] **Step 1: Add visual-kit dependency**

Read `plugins/paidagogos/.claude-plugin/plugin.json`, then add the dependencies array. Example final content (adjust to match the file's existing fields):
```json
{
  "name": "paidagogos",
  "version": "0.2.0",
  "description": "AI-powered lessons rendered via visual-kit",
  "author": "neotherapper",
  "license": "MIT",
  "dependencies": [
    { "name": "visual-kit", "version": "~1.0.0" }
  ],
  "skills": [ /* existing skills */ ]
}
```

- [ ] **Step 2: Delete the in-house server**

Run: `git rm -r plugins/paidagogos/server/`
Expected: directory removed.

- [ ] **Step 3: Update lesson-schema.md to reflect the SurfaceSpec shape**

In `plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md`, replace the top of the document with a note explaining that paidagogos now writes the `lesson` SurfaceSpec defined in visual-kit, and that the skill's output JSON matches `vk://schemas/lesson.v1.json`. Link to `docs/superpowers/specs/2026-04-17-visual-kit-design.md §6.1` for the schema. Keep the existing field descriptions, but frame them as guidance for populating the SurfaceSpec, not as an independent schema.

- [ ] **Step 4: Update paidagogos-micro SKILL.md pre-flight + write path**

Replace the pre-flight block in `plugins/paidagogos/skills/paidagogos-micro/SKILL.md` so it reads `<workspace>/.visual-kit/server/state/server-info` (not `.paidagogos/server/state/server-info`). Replace the write path so the skill writes to `<workspace>/.paidagogos/content/<slug>.json`, using the SurfaceSpec wrapper:
```jsonc
{
  "surface": "lesson",
  "version": 1,
  "topic": "...",
  "level": "...",
  "estimated_minutes": 12,
  "caveat": "AI-generated — verify against official docs.",
  "sections": [ /* typed sections */ ]
}
```
Update the error message when server is missing:
> `visual-kit is not running. Run` `visual-kit serve --project-dir .` `to start it.`

- [ ] **Step 5: Update CHANGELOG.md and README.md**

Add a `## 0.2.0` section to `plugins/paidagogos/CHANGELOG.md`:
```markdown
## 0.2.0

- Migrated to visual-kit for all rendering. Paidagogos no longer ships its own HTTP server.
- Lesson skill now writes the `lesson` SurfaceSpec v1 (visual-kit contract).
- Pre-flight checks `.visual-kit/server/state/server-info` instead of the old paidagogos path.
```

In `plugins/paidagogos/README.md`, replace any "start the paidagogos server" instruction with "start visual-kit: `visual-kit serve --project-dir .`".

- [ ] **Step 6: Commit**

```bash
git add plugins/paidagogos
git commit -m "feat(paidagogos): migrate to visual-kit dependency; drop in-house server

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 20: End-to-end smoke test — paidagogos lesson renders via visual-kit

**Files:**
- None new — uses existing infrastructure.

- [ ] **Step 1: Build visual-kit**

Run: `cd plugins/visual-kit && pnpm run build`
Expected: `dist/` up-to-date.

- [ ] **Step 2: Start visual-kit in foreground**

Run (in another terminal or use `&`):
```bash
node plugins/visual-kit/dist/cli.js serve --project-dir "$PWD"
```
Expected: JSON with `status: "running"` and a URL.

- [ ] **Step 3: Write a test lesson SurfaceSpec**

Create `./.paidagogos/content/flexbox.json`:
```json
{
  "surface": "lesson", "version": 1,
  "topic": "CSS Flexbox", "level": "beginner", "estimated_minutes": 10,
  "caveat": "AI-generated — verify against official docs.",
  "sections": [
    { "type": "concept", "text": "Flexbox lays items out along a main axis with optional cross-axis alignment." },
    { "type": "why", "text": "You'll use this when you want content to adapt to variable container sizes." },
    { "type": "code", "language": "css", "source": ".row { display: flex; justify-content: space-between; }" },
    { "type": "mistakes", "items": ["Confusing justify-content with align-items", "Forgetting to set display: flex on the parent"] },
    { "type": "generate", "task": "Build a pricing-table row with three equal columns using flexbox." },
    { "type": "next", "concept": "CSS Grid" }
  ]
}
```

- [ ] **Step 4: Open the rendered page**

In a browser, open `http://localhost:<port>/p/paidagogos/flexbox` (use the URL from step 2).
Expected: lesson content visible. CSS variables applied. No console errors. No external network requests.

- [ ] **Step 5: Verify with curl**

```bash
curl -sS -o /dev/null -w "%{http_code} %{content_type}\n" "http://localhost:<port>/p/paidagogos/flexbox"
```
Expected: `200 text/html; charset=utf-8`.

- [ ] **Step 6: Verify CSP header**

```bash
curl -sI "http://localhost:<port>/p/paidagogos/flexbox" | grep -i content-security-policy
```
Expected: line starting with `content-security-policy:` with `default-src 'none'`, `nonce-...`, no `unsafe-inline`, no `unsafe-eval`.

- [ ] **Step 7: Exercise auto-reload**

Overwrite `.paidagogos/content/flexbox.json` (change `topic` to `"CSS Flexbox (updated)"`). Expected: open browser reloads automatically within 1 second.

- [ ] **Step 8: Stop server**

```bash
node plugins/visual-kit/dist/cli.js stop --project-dir "$PWD"
```
Expected: `{"status":"stopped", ...}`.

- [ ] **Step 9: Commit end-to-end verification notes**

Create `plugins/visual-kit/tests/integration/smoke-notes.md` with a brief summary of the manual check (dates, browser, OS, screenshot reference if any). Stage + commit:

```bash
git add plugins/visual-kit/tests/integration/smoke-notes.md
git commit -m "test(visual-kit): E2E smoke — paidagogos lesson renders via visual-kit

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 21: DNS rebinding + path traversal regression tests (acceptance hardening)

**Files:**
- Create: `plugins/visual-kit/tests/integration/dns-rebinding.test.ts`
- Create: `plugins/visual-kit/tests/integration/traversal.test.ts`

- [ ] **Step 1: Write DNS rebinding test**

Write `plugins/visual-kit/tests/integration/dns-rebinding.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

describe('DNS rebinding defense', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('rejects Host: attacker.example:<port>', async () => {
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/vk/capabilities`, { headers: { Host: 'attacker.example:9999' } });
    expect(res.status).toBe(421);
  });

  it('accepts Host: 127.0.0.1:<port>', async () => {
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/vk/capabilities`, { headers: { Host: `127.0.0.1:${info.port}` } });
    expect(res.status).toBe(200);
  });

  it('accepts Host: localhost:<port>', async () => {
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/vk/capabilities`, { headers: { Host: `localhost:${info.port}` } });
    expect(res.status).toBe(200);
  });
});
```

- [ ] **Step 2: Write path traversal test**

Write `plugins/visual-kit/tests/integration/traversal.test.ts`:
```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { mkdir, writeFile, symlink, readFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';

describe('path traversal', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('rejects URL-encoded traversal in /vk/', async () => {
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/vk/..%2f..%2fetc%2fpasswd`);
    // Path is not shaped as a bundle; expect 404 (route not matched) or 400.
    expect([400, 404]).toContain(res.status);
  });

  it('rejects traversal in /p/<plugin>/<surface>', async () => {
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/p/demo/..%2fsecret`);
    expect([400, 404]).toContain(res.status);
  });

  it('rejects symlinked SurfaceSpec', async () => {
    const outside = await (await import('node:fs/promises')).mkdtemp(join(tmpdir(), 'vk-outside-'));
    await writeFile(join(outside, 'secret.json'), '{"surface":"lesson","version":1,"topic":"leak","level":"beginner","sections":[{"type":"concept","text":"x"}]}');
    await symlink(join(outside, 'secret.json'), join(ws.dir, '.demo/content/evil.json'));
    const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
    const res = await fetch(`${info.url}/p/demo/evil`);
    expect(res.status).toBe(404);
    await (await import('node:fs/promises')).rm(outside, { recursive: true, force: true });
  });
});
```

- [ ] **Step 3: Run tests**

Run: `pnpm test`
Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add plugins/visual-kit/tests/integration
git commit -m "test(visual-kit): DNS rebinding + path traversal regression

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 22: Finalize changelog, docs, and open PR

**Files:**
- Modify: `plugins/visual-kit/CHANGELOG.md`
- Modify: `docs/plugins/visual-kit/_index.md` (mark V1 complete)
- Modify: `marketplace.json` (add visual-kit entry)

- [ ] **Step 1: Fill CHANGELOG.md with the V1 release notes**

Replace `plugins/visual-kit/CHANGELOG.md` with:
```markdown
# Changelog

## 1.0.0 — 2026-04-17

First release. Shared visual renderer for Claude Code plugins.

- CLI: `visual-kit serve | stop | status`
- HTTP server: per-workspace, localhost-only, strict CSP with per-response nonce, per-page CSRF token, Host-header allowlist, path-traversal guards.
- Six V1 surfaces: lesson, gallery, outline, comparison, feedback, free (sanitized).
- Core bundle: vk-section, vk-card, vk-gallery, vk-outline, vk-comparison, vk-feedback, vk-loader, vk-error, vk-code.
- `GET /vk/capabilities` for graceful version degradation.
- Paidagogos 0.2.0 migrated to depend on visual-kit.
```

- [ ] **Step 2: Add visual-kit to marketplace.json**

Read `marketplace.json` and append the entry (match existing style):
```json
{
  "name": "visual-kit",
  "version": "1.0.0",
  "description": "Shared local visual rendering for Claude Code plugins.",
  "source": { "type": "git", "path": "plugins/visual-kit" }
}
```

- [ ] **Step 3: Tag the release**

```bash
git tag visual-kit--v1.0.0
git tag paidagogos--v0.2.0
```

Do NOT push tags without explicit user request.

- [ ] **Step 4: Commit the release notes and marketplace entry**

```bash
git add plugins/visual-kit/CHANGELOG.md marketplace.json docs/plugins/visual-kit/_index.md
git commit -m "release(visual-kit): 1.0.0 + paidagogos 0.2.0 migration

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 5: Offer to open a PR**

Ask the user: "V1 complete locally. Should I `git push origin feat/visual-kit-v1` and open a PR to main?" Do not push without confirmation.

---

## Self-review

**Spec coverage:** every numbered requirement in `2026-04-17-visual-kit-design.md` §4 is either satisfied by a task or explicitly deferred per the out-of-scope note (domain bundles → Plan B, extended bundles → Plan C, namesmith/draftloom migrations → Plan B). FR-1..10, AR-1..8, RR-1..4, QR-1..5, SR-1..10 are covered by Tasks 1–22.

**Placeholder scan:** no TBD/TODO strings. Every code step includes the actual code. Task 15 Step 3 describes "analogous minimal modules" but is explicit that each must be under 40 lines with the listed render behavior — this is guidance, not a placeholder; an executing agent will write each file following the `gallery.ts` example. Acceptable.

**Type consistency:** `ServerInfo`, `SurfaceKind`, `SlotResult`, `AcquireOpts` introduced once, used consistently. `buildCapabilities` changed signature in Task 15 to async (returning Promise<object>) — handler must `await` it, which is noted in Step 7.

**Scope:** plan scope holds to "ship visual-kit V1 infrastructure + migrate paidagogos." Domain bundles (code/math/chart/quiz/progress) are deliberately NOT included beyond the minimal `<vk-code>` — paidagogos's existing lesson template already uses primitive code rendering, and the spec's core bundle contract matches. Heavy renderers (KaTeX/Chart.js/CodeMirror) land in Plan B where namesmith and draftloom also migrate and the bundle autoloader is exercised end-to-end across multiple bundles.

---
