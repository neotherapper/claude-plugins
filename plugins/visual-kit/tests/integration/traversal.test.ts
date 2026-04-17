import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { mkdir, writeFile, symlink, readFile, mkdtemp, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

async function loadInfo(ws: TmpWorkspace): Promise<{ url: string }> {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

describe('path traversal', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('rejects URL-encoded traversal in /vk/', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/vk/..%2f..%2fetc%2fpasswd`);
    expect([400, 404]).toContain(res.status);
  });

  it('rejects traversal in /p/<plugin>/<surface>', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/..%2fsecret`);
    expect([400, 404]).toContain(res.status);
  });

  it('rejects symlinked SurfaceSpec', async () => {
    const outside = await mkdtemp(join(tmpdir(), 'vk-outside-'));
    await writeFile(join(outside, 'secret.json'),
      '{"surface":"lesson","version":1,"topic":"leak","level":"beginner","sections":[{"type":"concept","text":"x"}]}');
    await symlink(join(outside, 'secret.json'), join(ws.dir, '.demo/content/evil.json'));
    try {
      const info = await loadInfo(ws);
      const res = await fetch(`${info.url}/p/demo/evil`);
      expect(res.status).toBe(404);
    } finally {
      await rm(outside, { recursive: true, force: true });
    }
  });
});
