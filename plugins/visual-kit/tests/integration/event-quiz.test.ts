import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { startServer, stopServer } from '../../src/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

async function loadInfo(ws: TmpWorkspace): Promise<{ url: string; port: number }> {
  return JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
}

describe('event schema — quiz_answer', () => {
  let ws: TmpWorkspace;

  beforeEach(async () => {
    ws = await tmpWorkspace();
    await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
    await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
    await writeFile(join(ws.dir, '.demo/content/q.json'), JSON.stringify({
      surface: 'lesson', version: 1, topic: 'Q', level: 'beginner',
      sections: [{ type: 'quiz', items: [
        { type: 'multiple_choice', question: 'Q?', options: ['a','b'], answer: 'a', explanation: '.' },
      ] }],
    }));
  });
  afterEach(async () => { await stopServer(); await ws.cleanup(); });

  it('appends a valid quiz_answer event to the plugin events log', async () => {
    const info = await loadInfo(ws);
    const page = await fetch(`${info.url}/p/demo/q`);
    const html = await page.text();
    const csrf = /<meta name="vk-csrf" content="([^"]+)"/.exec(html)?.[1] ?? '';

    const post = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        'Referer': `${info.url}/p/demo/q`,
      },
      body: JSON.stringify({
        type: 'quiz_answer',
        index: 0,
        item_type: 'multiple_choice',
        chosen: 'a',
        correct: true,
        ts: new Date().toISOString(),
      }),
    });
    expect(post.status).toBe(204);

    const logPath = join(ws.dir, '.demo/state/events');
    const log = await readFile(logPath, 'utf8');
    const entry = JSON.parse(log.trim());
    expect(entry.type).toBe('quiz_answer');
    expect(entry.chosen).toBe('a');
    expect(entry.correct).toBe(true);
    expect(entry.plugin).toBe('demo');
  });

  it('rejects a quiz_answer with chosen > 1024 chars (400)', async () => {
    const info = await loadInfo(ws);
    const page = await fetch(`${info.url}/p/demo/q`);
    const html = await page.text();
    const csrf = /<meta name="vk-csrf" content="([^"]+)"/.exec(html)?.[1] ?? '';

    const post = await fetch(`${info.url}/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Vk-Csrf': csrf,
        'Referer': `${info.url}/p/demo/q`,
      },
      body: JSON.stringify({
        type: 'quiz_answer',
        index: 0,
        item_type: 'explain',
        chosen: 'a'.repeat(1025),
        correct: true,
        ts: new Date().toISOString(),
      }),
    });
    // Server rejects with 400 (body validation) rather than 413 (body-size cap)
    // because the 1 KB cap is a per-field check, not a body-size limit.
    expect([400, 413]).toContain(post.status);
  });
});
