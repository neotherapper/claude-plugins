import { build } from 'esbuild';
import { mkdir, writeFile, readFile, copyFile, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { join } from 'node:path';

const pkg = JSON.parse(await readFile('package.json', 'utf8'));
const version = pkg.version;

await mkdir('dist', { recursive: true });

// Copy static assets into dist so server bundles can locate them at runtime
// using paths relative to the bundle file itself.
await copyFile('src/components/theme.css', 'dist/theme.css');

const schemaDestDir = 'dist/schemas/surfaces';
await mkdir(schemaDestDir, { recursive: true });
const schemaFiles = await readdir('schemas/surfaces');
await Promise.all(
  schemaFiles
    .filter(f => f.endsWith('.json'))
    .map(f => copyFile(join('schemas/surfaces', f), join(schemaDestDir, f))),
);

await build({
  entryPoints: ['src/components/index.ts'],
  outfile: 'dist/core.js',
  bundle: true,
  minify: true,
  format: 'esm',
  target: ['es2022'],
  sourcemap: false,
  platform: 'browser',
  loader: { '.css': 'text' },
  logLevel: 'info',
});

const core = await readFile('dist/core.js');
const sri = 'sha384-' + createHash('sha384').update(core).digest('base64');
await writeFile('dist/core.js.sri.txt', sri);

// Shared define block: embeds version + SRI at build time so the
// server bundles do not need to locate package.json / sri.txt at runtime.
const baseDefine = {
  __VK_VERSION__: JSON.stringify(version),
  __VK_CORE_SRI__: JSON.stringify(sri),
};

// cli.js lives at dist/cli.js → static assets are one level up from it
// in relative terms AFTER copying to dist/.
// We inject __VK_ASSET_OFFSET__ so bundles.ts / validate.ts can locate
// schemas + theme.css using: join(here, __VK_ASSET_OFFSET__, 'schemas/...')
// cli:    here = dist/   → offset = ''   → dist/schemas/...       ✓
// server: here = dist/server/ → offset = '../' → dist/schemas/... ✓
await build({
  entryPoints: ['src/cli/index.ts'],
  outfile: 'dist/cli.js',
  bundle: true,
  minify: false,
  platform: 'node',
  target: ['node20'],
  format: 'esm',
  packages: 'external',
  define: { ...baseDefine, __VK_ASSET_OFFSET__: JSON.stringify('') },
  logLevel: 'info',
});

await build({
  entryPoints: ['src/server/index.ts'],
  outfile: 'dist/server/index.js',
  bundle: true,
  minify: false,
  platform: 'node',
  target: ['node20'],
  format: 'esm',
  packages: 'external',
  define: { ...baseDefine, __VK_ASSET_OFFSET__: JSON.stringify('../') },
  logLevel: 'info',
});

console.log('visual-kit build complete. Core SRI:', sri);
