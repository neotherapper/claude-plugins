import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isSafeSegment } from './paths.js';

// __VK_ASSET_OFFSET__ is injected at build time by scripts/build.mjs.
// It encodes the relative hop from this bundle file's directory to dist/:
//   dist/cli.js (here=dist/)         → offset = ''
//   dist/server/index.js (here=dist/server/) → offset = '../'
// In source runs (vitest / ts-node), here = src/server/ so we go '../../dist/'.
declare const __VK_ASSET_OFFSET__: string;
const IS_BUILT = typeof __VK_ASSET_OFFSET__ !== 'undefined';
const ASSET_OFFSET: string = IS_BUILT ? __VK_ASSET_OFFSET__ : '../../dist/';

const here = dirname(fileURLToPath(import.meta.url));
// Resolves to dist/ in all contexts:
//   src/server + ../../dist/ = dist/
//   dist/server + ../        = dist/
//   dist/       + ''         = dist/
const distDir = join(here, ASSET_OFFSET);
const schemaDir = join(here, ASSET_OFFSET, 'schemas');
// theme.css is copied to dist/theme.css during build.
// In source-only runs (vitest), fall back to original src location.
const themePath = IS_BUILT
  ? join(here, ASSET_OFFSET, 'theme.css')
  : join(here, '../components/theme.css');

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
