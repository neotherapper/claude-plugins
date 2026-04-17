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
if (failed) process.exit(1);
console.log('Security headers OK.');
process.exit(0);
