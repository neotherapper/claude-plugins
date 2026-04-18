import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

async function loadInfo(ws: TmpWorkspace) {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

describe('autoloader dedup and preload', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  });
  afterEach(async () => { await stopServer(); await ws.cleanup(); });

  it('preloads each bundle exactly once for a multi-section lesson', async () => {
    await writeFile(join(ws.dir, '.demo/content/multi.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Multi', level: 'beginner',
      sections: [
        { type: 'math', latex: 'a' },
        { type: 'math', latex: 'b', display: true },
        { type: 'chart', config: { type: 'bar', data: { datasets: [] } } },
        { type: 'quiz', items: [{ type: 'explain', question: 'Q', answer: 'a', explanation: 'e' }] },
      ],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/multi`);
    const html = await res.text();

    // Core + 3 domain bundles = 4 modulepreload links.
    const preloads = html.match(/<link rel="modulepreload"/g) ?? [];
    expect(preloads.length).toBe(4);

    // Each bundle url appears exactly once in preload links.
    expect((html.match(/href="\/vk\/math\.js"/g) ?? []).length).toBe(1);
    expect((html.match(/href="\/vk\/chart\.js"/g) ?? []).length).toBe(1);
    expect((html.match(/href="\/vk\/quiz\.js"/g) ?? []).length).toBe(1);
    expect((html.match(/href="\/vk\/core\.js"/g) ?? []).length).toBe(1);
  });

  it('does NOT preload domain bundles for a lesson with only concept sections', async () => {
    await writeFile(join(ws.dir, '.demo/content/plain.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Plain', level: 'beginner',
      sections: [{ type: 'concept', text: 'Hello' }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/plain`);
    const html = await res.text();

    const preloads = html.match(/<link rel="modulepreload"/g) ?? [];
    expect(preloads.length).toBe(1); // just core
    expect(html).not.toContain('/vk/math.js');
    expect(html).not.toContain('/vk/chart.js');
    expect(html).not.toContain('/vk/quiz.js');
  });

  it('renders malformed chart config as <vk-error>', async () => {
    // Chart config that fails schema validation (missing type).
    await writeFile(join(ws.dir, '.demo/content/bad.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Bad', level: 'beginner',
      sections: [{ type: 'chart', config: { data: {} } }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/bad`);
    const html = await res.text();
    // Schema failure → the whole page is an error page.
    expect(html.toLowerCase()).toContain('vk-error');
  });
});
