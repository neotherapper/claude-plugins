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
