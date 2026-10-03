#!/usr/bin/env node
/**
 * Builds the roadmap index from the pack manifests.
 *
 * Discovery is a glob rather than a list, so a new pack appears in the index
 * by existing. The previous arrangement was a markdown table inside a skill,
 * which is the shape of instruction this project has twice found gets skipped.
 *
 * Fails closed: one invalid manifest aborts the whole index rather than
 * silently emitting a directory with a hole in it.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const here = dirname(fileURLToPath(import.meta.url));
const packsDir = join(here, '..', 'packs');
const schemaPath = join(here, '..', 'schemas', 'pack.v1.json');

const ajv = new Ajv.default({ strict: false, allErrors: true });
addFormats(ajv);
const validate = ajv.compile(JSON.parse(await readFile(schemaPath, 'utf8')));

const errors = [];
const packs = [];

for (const entry of await readdir(packsDir, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const manifestPath = join(packsDir, entry.name, 'pack.json');
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  } catch (err) {
    errors.push(`${entry.name}: ${err.code === 'ENOENT' ? 'no pack.json' : err.message}`);
    continue;
  }
  if (!validate(manifest)) {
    errors.push(`${entry.name}: ${validate.errors.map(e => `${e.instancePath} ${e.message}`).join('; ')}`);
    continue;
  }
  // A manifest that disagrees with its own directory yields links that 404,
  // and the schema cannot see the filesystem.
  if (manifest.id !== entry.name) {
    errors.push(`${entry.name}: manifest id "${manifest.id}" does not match directory name`);
    continue;
  }
  packs.push(manifest);
}

if (errors.length) {
  console.error('build-index failed:\n  ' + errors.join('\n  '));
  process.exit(1);
}

// Stable order: the index must not reshuffle between runs.
packs.sort((a, b) => a.title.localeCompare(b.title, 'en'));

const items = packs.map(p => {
  const main = p.surfaces.find(s => s.role === 'curriculum') ?? p.surfaces[0];
  const extra = p.surfaces.filter(s => s !== main);
  // Only a tree surface has a SurfaceSpec the server can render. A markdown
  // pack has nothing at /p/paidagogos/<id>, so linking it produces a card that
  // 404s — worse than one that is plainly not a link. href is optional in the
  // gallery schema precisely so a card can decline to be one.
  const renderable = (main.format ?? 'tree') === 'tree';
  return {
    id: p.id,
    title: p.title,
    ...(p.subtitle ? { subtitle: p.subtitle } : {}),
    ...(p.summary ? { body: p.summary } : {}),
    ...(renderable ? { href: `/p/paidagogos/${main.id}` } : {}),
    badges: [
      ...(renderable ? [] : [{ label: 'not rendered', tone: 'muted' }]),
      ...(p.badges ?? []),
      ...extra.map(s => ({ label: s.title, tone: 'muted' })),
    ].slice(0, 6),
  };
});

const spec = {
  surface: 'gallery',
  version: 1,
  title: 'Roadmaps',
  items,
};

const outFlag = process.argv.indexOf('--out');
const json = JSON.stringify(spec, null, 2);
if (outFlag !== -1 && process.argv[outFlag + 1]) {
  await writeFile(process.argv[outFlag + 1], json + '\n', 'utf8');
  console.error(`wrote ${items.length} roadmap(s)`);
} else {
  process.stdout.write(json + '\n');
}
