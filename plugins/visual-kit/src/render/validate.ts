import Ajv2020, { type ValidateFunction } from 'ajv/dist/2020.js';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { SurfaceKind } from '../shared/types.js';

// __VK_ASSET_OFFSET__ is injected at build time by scripts/build.mjs.
// It encodes the hop from the bundle's directory to the dist/ root where
// schemas/ was copied:
//   cli.js (dist/)             → offset = ''
//   server/index.js (dist/server/) → offset = '../'
// Falls back to '../../' for source-level runs (vitest reads from schemas/).
declare const __VK_ASSET_OFFSET__: string;
const ASSET_OFFSET: string =
  typeof __VK_ASSET_OFFSET__ !== 'undefined' ? __VK_ASSET_OFFSET__ : '../../';

const here = dirname(fileURLToPath(import.meta.url));
// In source context: here = src/render/, offset = '../../' → schemas/surfaces ✓
// In dist/server bundle: here = dist/server/, offset = '../' → dist/schemas/surfaces ✓
// In dist/cli bundle: here = dist/, offset = '' → dist/schemas/surfaces ✓
const schemaDir = join(here, ASSET_OFFSET, 'schemas/surfaces');

// strict: false because some schemas use enum values inside oneOf branches
// that Ajv strict mode flags as unknown keywords (e.g. bare "enum" alongside
// "const" in the same properties sub-schema). The schemas are authored by this
// project and are correct JSON Schema 2020-12 — strict mode is overly
// conservative here.
const ajv = new Ajv2020({ strict: false, allErrors: true });
const validators = new Map<SurfaceKind, ValidateFunction>();

const KINDS: SurfaceKind[] = ['lesson', 'gallery', 'outline', 'comparison', 'feedback', 'free'];

export async function loadSchemas(): Promise<void> {
  // Skip if already loaded — Ajv rejects duplicate schema IDs, and in tests
  // startServer may be called multiple times within the same module instance.
  if (validators.size === KINDS.length) return;
  for (const kind of KINDS) {
    if (validators.has(kind)) continue;
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
