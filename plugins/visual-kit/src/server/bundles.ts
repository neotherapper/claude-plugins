import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
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
