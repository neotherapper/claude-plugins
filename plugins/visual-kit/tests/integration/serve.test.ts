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
      expect.arrayContaining(['lesson','gallery','outline','comparison','feedback','free','free-interactive']),
    );
  });

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

  it('rejects requests with disallowed Host header', async () => {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    const { readFile } = await import('node:fs/promises');
    const info = JSON.parse(await readFile(`${ws.dir}/.visual-kit/server/state/server-info`, 'utf8'));

    // Use http.request directly so we can set an arbitrary Host header.
    // fetch() rewrites or rejects mismatched Host headers before sending,
    // making it unsuitable for testing the server-side 421 response.
    const { request } = await import('node:http');
    const url = new URL('/vk/capabilities', info.url);
    const statusCode = await new Promise<number>((resolve, reject) => {
      const req = request(
        {
          hostname: url.hostname,
          port: Number(url.port),
          path: url.pathname,
          method: 'GET',
          headers: { Host: 'attacker.example:9999' },
        },
        res => resolve(res.statusCode ?? 0),
      );
      req.once('error', reject);
      req.end();
    });
    expect(statusCode).toBe(421);
  });
});
