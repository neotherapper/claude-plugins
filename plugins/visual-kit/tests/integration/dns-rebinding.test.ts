import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { request } from 'node:http';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

interface InfoLite { url: string; port: number }

async function loadInfo(ws: TmpWorkspace): Promise<InfoLite> {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

function rawGet(port: number, path: string, headers: Record<string, string>): Promise<{ status: number }> {
  return new Promise((resolve, reject) => {
    const req = request({ host: '127.0.0.1', port, path, method: 'GET', headers }, res => {
      res.resume();
      res.on('end', () => resolve({ status: res.statusCode ?? 0 }));
    });
    req.on('error', reject);
    req.end();
  });
}

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
    const info = await loadInfo(ws);
    const res = await rawGet(info.port, '/vk/capabilities', { Host: `attacker.example:${info.port}` });
    expect(res.status).toBe(421);
  });

  it('accepts Host: 127.0.0.1:<port>', async () => {
    const info = await loadInfo(ws);
    const res = await rawGet(info.port, '/vk/capabilities', { Host: `127.0.0.1:${info.port}` });
    expect(res.status).toBe(200);
  });

  it('accepts Host: localhost:<port>', async () => {
    const info = await loadInfo(ws);
    const res = await rawGet(info.port, '/vk/capabilities', { Host: `localhost:${info.port}` });
    expect(res.status).toBe(200);
  });
});
