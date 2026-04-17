import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

async function loadInfo(ws: TmpWorkspace): Promise<{ url: string }> {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

async function loadPage(info: { url: string }, plugin: string, surfaceId: string): Promise<{ html: string; csrf: string }> {
  const res = await fetch(`${info.url}/p/${plugin}/${surfaceId}`);
  const html = await res.text();
  const csrf = /name="vk-csrf" content="([^"]+)"/.exec(html)?.[1] ?? '';
  return { html, csrf };
}

describe('/events CSRF + cross-plugin isolation', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.a/content'), { recursive: true });
    await mkdir(join(ws.dir, '.b/content'), { recursive: true });
    await writeFile(join(ws.dir, '.a/content/x.json'),
      JSON.stringify({ surface: 'gallery', version: 1, items: [{ id: 'one', title: 'One' }] }));
    await writeFile(join(ws.dir, '.b/content/y.json'),
      JSON.stringify({ surface: 'gallery', version: 1, items: [{ id: 'one', title: 'One' }] }));
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });

  afterEach(async () => {
    await stopServer();
    await ws.cleanup();
  });

  it('rejects POST /events without CSRF token (403)', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Referer: `${info.url}/p/a/x` },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(403);
  });

  it('accepts POST /events with matching token + Referer (204)', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/a/x`,
      },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(204);
    const log = await readFile(join(ws.dir, '.a/state/events'), 'utf8');
    expect(log).toContain('"plugin":"a"');
    expect(log).toContain('"surface":"x"');
  });

  it('rejects using plugin A token while claiming Referer to plugin B', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/b/y`,
      },
      body: JSON.stringify({ type: 'select', id: 'one' }),
    });
    expect(res.status).toBe(403);
  });

  it('ignores body-supplied "plugin" and uses Referer-derived value', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        Referer: `${info.url}/p/a/x`,
      },
      body: JSON.stringify({ type: 'select', id: 'one', plugin: 'b' }),
    });
    expect(res.status).toBe(204);
    const logB = await readFile(join(ws.dir, '.b/state/events'), 'utf8').catch(() => '');
    expect(logB).toBe('');
    const logA = await readFile(join(ws.dir, '.a/state/events'), 'utf8');
    expect(logA).toContain('"plugin":"a"');
  });

  it('rejects oversized bodies (413)', async () => {
    const info = await loadInfo(ws);
    const { csrf } = await loadPage(info, 'a', 'x');
    const res = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Vk-Csrf': csrf, Referer: `${info.url}/p/a/x` },
      body: 'x'.repeat(65 * 1024),
    });
    expect(res.status).toBe(413);
  });
});
