import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, rm, readFile, writeFile, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { acquireServerSlot, releaseServerSlot } from '../../src/server/lifecycle.js';

describe('acquireServerSlot', () => {
  let projectDir: string;

  beforeEach(async () => {
    projectDir = await mkdtemp(join(tmpdir(), 'vk-life-'));
  });

  afterEach(async () => {
    await rm(projectDir, { recursive: true, force: true });
  });

  it('writes server-info with the derived port', async () => {
    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('acquired');
    if (slot.action !== 'acquired') throw new Error('unreachable');
    const info = JSON.parse(
      await readFile(join(projectDir, '.visual-kit/server/state/server-info'), 'utf8')
    );
    expect(info.port).toBe(slot.port);
    expect(info.pid).toBe(process.pid);
    await releaseServerSlot(projectDir, slot);
  });

  it('returns attach when a live server-info already exists', async () => {
    const infoDir = join(projectDir, '.visual-kit/server/state');
    await mkdir(infoDir, { recursive: true });
    await writeFile(
      join(infoDir, 'server-info'),
      JSON.stringify({
        status: 'running',
        pid: process.pid,
        port: 34287,
        host: '127.0.0.1',
        url: 'http://localhost:34287',
        started_at: new Date().toISOString(),
        project_dir: projectDir,
        visual_kit_version: '1.0.0',
      })
    );

    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('attach');
  });

  it('removes stale server-info when pid is dead', async () => {
    const infoDir = join(projectDir, '.visual-kit/server/state');
    await mkdir(infoDir, { recursive: true });
    await writeFile(
      join(infoDir, 'server-info'),
      JSON.stringify({
        status: 'running',
        pid: 999999999,
        port: 34287,
        host: '127.0.0.1',
        url: 'http://localhost:34287',
        started_at: new Date().toISOString(),
        project_dir: projectDir,
        visual_kit_version: '1.0.0',
      })
    );

    const slot = await acquireServerSlot(projectDir, { pid: process.pid, version: '1.0.0' });
    expect(slot.action).toBe('acquired');
  });
});
