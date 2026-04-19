import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

async function loadInfo(ws: TmpWorkspace): Promise<{ url: string; port: number }> {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

describe('surface render integration', () => {
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

  it('renders a valid lesson SurfaceSpec', async () => {
    await writeFile(join(ws.dir, '.demo/content/intro.json'), JSON.stringify({
      surface: 'lesson', version: 1,
      topic: 'Hello Flexbox', level: 'beginner', estimated_minutes: 8,
      sections: [{ type: 'concept', text: 'Rows and columns.' }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/intro`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain('Hello Flexbox');
    expect(html).toContain('Rows and columns.');
    expect(res.headers.get('content-security-policy')).toMatch(/default-src 'none'/);
    expect(res.headers.get('content-security-policy')).not.toContain('unsafe-inline');
  });

  it('renders vk-error for an unknown surface', async () => {
    await writeFile(join(ws.dir, '.demo/content/bad.json'), JSON.stringify({
      surface: 'unknown', version: 1,
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/bad`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html.toLowerCase()).toContain('vk-error');
    expect(html.toLowerCase()).toContain('unknown surface');
  });

  it('returns 404 when the SurfaceSpec file is missing', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/absent`);
    expect(res.status).toBe(404);
  });

  it('serves /vk/theme.css with CSS content-type', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/vk/theme.css`);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/css/);
    expect(await res.text()).toContain(':root');
  });

  it('serves /vk/schemas/lesson.v1.json', async () => {
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/vk/schemas/lesson.v1.json`);
    expect(res.status).toBe(200);
    const j = await res.json();
    expect(j.$id).toContain('lesson.v1.json');
  });

  it('renders a code section with Prism tokens slotted into <vk-code>', async () => {
    await writeFile(join(ws.dir, '.demo/content/code.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Code', level: 'beginner',
      sections: [{ type: 'code', language: 'javascript', source: 'const x = 1;' }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/code`);
    const html = await res.text();
    expect(html).toContain('<vk-code');
    expect(html).toContain('token keyword');
  });

  it('renders a math section as <vk-math>', async () => {
    await writeFile(join(ws.dir, '.demo/content/math.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Math', level: 'beginner',
      sections: [{ type: 'math', latex: 'a^2+b^2=c^2', display: true }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/math`);
    const html = await res.text();
    expect(html).toContain('<vk-math');
    expect(html).toContain('a^2+b^2=c^2');
  });

  it('renders a chart section with sibling JSON script', async () => {
    await writeFile(join(ws.dir, '.demo/content/chart.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Chart', level: 'beginner',
      sections: [{ type: 'chart', config: { type: 'bar', data: { labels: ['a'], datasets: [{ data: [1] }] } } }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/chart`);
    const html = await res.text();
    expect(html).toContain('<vk-chart');
    expect(html).toMatch(/<script type="application\/json">[^<]*"type":"bar"/);
  });

  it('renders a quiz section with sibling JSON and <vk-quiz> tag', async () => {
    await writeFile(join(ws.dir, '.demo/content/quiz.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Quiz', level: 'beginner',
      sections: [{ type: 'quiz', items: [
        { type: 'multiple_choice', question: 'Q?', options: ['a','b'], answer: 'a', explanation: 'ok' },
      ] }],
    }));
    const info = await loadInfo(ws);
    const res = await fetch(`${info.url}/p/demo/quiz`);
    const html = await res.text();
    expect(html).toContain('<vk-quiz');
    expect(html).toContain('multiple_choice');
  });
});
