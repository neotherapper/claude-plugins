import { build } from 'esbuild';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

await mkdir('dist', { recursive: true });

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
