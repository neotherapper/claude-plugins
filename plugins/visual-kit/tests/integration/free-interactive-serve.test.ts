import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';

describe('free-interactive surface (integration)', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => { ws = await tmpWorkspace(); });
  afterEach(async () => { await stopServer(); await ws.cleanup(); });

  async function startAndReadInfo() {
    await startServer({
      projectDir: ws.dir,
      host: '127.0.0.1',
      urlHost: 'localhost',
      foreground: true,
    });
    return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
  }

  async function writeSpec(plugin: string, id: string, spec: object) {
    const dir = join(ws.dir, `.${plugin}`, 'content');
    await mkdir(dir, { recursive: true });
    await writeFile(join(dir, `${id}.json`), JSON.stringify(spec), 'utf8');
  }

  it('serves free-interactive HTML without a CSP header', async () => {
    await writeSpec('demo', 'parabola', {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body><script>window.__marker=42</script></body></html>',
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/parabola`);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/html/);
    expect(res.headers.get('content-security-policy')).toBeNull();
    expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    expect(res.headers.get('referrer-policy')).toBe('no-referrer');

    const body = await res.text();
    expect(body).toContain('<script>window.__marker=42</script>');
    expect(body).toContain("new EventSource('/events/stream')");
  });

  it('does NOT wrap free-interactive in the vk-surface shell', async () => {
    await writeSpec('demo', 'raw', {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body><p>raw</p></body></html>',
    });
    const info = await startAndReadInfo();

    const body = await (await fetch(`${info.url}/p/demo/raw`)).text();
    expect(body).not.toContain('<main class="vk-surface">');
    expect(body).not.toContain('meta name="vk-csrf"');
    expect(body).not.toContain('/vk/core.js');
  });

  it('regression guard: lesson surface still uses strict shell + CSP', async () => {
    // Minimum lesson spec — sections use "type" not "kind" per lesson.v1.json schema.
    await writeSpec('demo', 'les', {
      surface: 'lesson',
      version: 1,
      topic: 'regression',
      level: 'beginner',
      sections: [{ type: 'why', text: 'x' }],
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/les`);
    expect(res.status).toBe(200);
    const csp = res.headers.get('content-security-policy');
    expect(csp).toBeTruthy();
    expect(csp).toContain("script-src 'self'");
    expect(csp).toContain("nonce-");
    const body = await res.text();
    expect(body).toContain('<main class="vk-surface">');
  });

  it('returns the vk-error page for an invalid free-interactive spec', async () => {
    await writeSpec('demo', 'bad', {
      surface: 'free-interactive',
      version: 1,
      // html field missing — schema should reject.
    });
    const info = await startAndReadInfo();

    const res = await fetch(`${info.url}/p/demo/bad`);
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body).toContain('vk-error');
    expect(body).toContain('Schema');
  });
});
