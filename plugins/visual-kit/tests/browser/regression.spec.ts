import { test, expect } from '@playwright/test';
// Import from the built server bundle, not src/. The esbuild build injects
// __VK_CORE_SRI__ / __VK_MATH_SRI__ / etc. via `define`; running from src
// means those fall back to the `sha384-dev` sentinel, which causes real
// Chromium to refuse to execute the bundle and masks the components under test.
import { startServer, stopServer } from '../../dist/server/index.js';
import { tmpWorkspace, type TmpWorkspace } from '../helpers/tmp-workspace.js';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

let ws: TmpWorkspace;
let url: string;

test.beforeAll(async () => {
  ws = await tmpWorkspace();
  await mkdir(join(ws.dir, '.demo/content'), { recursive: true });
  await startServer({ projectDir: ws.dir, host: '127.0.0.1', urlHost: 'localhost', foreground: true });
  const info = JSON.parse(await readFile(join(ws.dir, '.visual-kit/server/state/server-info'), 'utf8'));
  url = info.url;
});

test.afterAll(async () => {
  await stopServer();
  await ws.cleanup();
});

async function writeLesson(id: string, spec: object) {
  await writeFile(join(ws.dir, `.demo/content/${id}.json`), JSON.stringify(spec));
}

test('katex renders styled (shadow-DOM CSS cascade reaches KaTeX output)', async ({ page }) => {
  await writeLesson('math', {
    surface: 'lesson', version: 1, topic: 'Math', level: 'beginner',
    sections: [{ type: 'math', latex: 'a^2+b^2=c^2', display: true }],
  });
  await page.goto(`${url}/p/demo/math`);
  // Element becomes attached as soon as the vk-math bundle upgrades it; visibility
  // depends on the KaTeX inline-style layout hints (height/vertical-align) which
  // may be CSP-restricted. We only need to know the component rendered and KaTeX
  // produced output — CSS cascade is verified via getComputedStyle below.
  await page.waitForSelector('vk-math .katex', { state: 'attached' });
  const fontFamily = await page.evaluate(() => {
    const base = document.querySelector('vk-math .katex .base, vk-math .katex .mord');
    return base ? getComputedStyle(base).fontFamily : '';
  });
  expect(fontFamily).toMatch(/KaTeX_/);
});

test('katex fonts load from data URLs (document.fonts contains KaTeX family)', async ({ page }) => {
  await writeLesson('math-font', {
    surface: 'lesson', version: 1, topic: 'Font', level: 'beginner',
    sections: [{ type: 'math', latex: 'x+y', display: true }],
  });
  await page.goto(`${url}/p/demo/math-font`);
  await page.waitForSelector('vk-math .katex', { state: 'attached' });
  const hasKatexFont = await page.evaluate(async () => {
    await (document as any).fonts.ready;
    for (const f of (document as any).fonts as Set<FontFace>) {
      if (/KaTeX/.test(f.family)) return true;
    }
    return false;
  });
  expect(hasKatexFont).toBe(true);
});

test('chart renders pixels onto the canvas', async ({ page }) => {
  await writeLesson('chart', {
    surface: 'lesson', version: 1, topic: 'Chart', level: 'beginner',
    sections: [{ type: 'chart', config: {
      type: 'bar',
      data: { labels: ['a','b','c'], datasets: [{ data: [1,2,3], backgroundColor: '#6cb6ff' }] },
    } }],
  });
  await page.goto(`${url}/p/demo/chart`);
  await page.waitForSelector('vk-chart canvas', { state: 'attached' });
  await page.waitForTimeout(300); // Chart.js draws on rAF
  const hasPixels = await page.evaluate(() => {
    const canvas = document.querySelector('vk-chart canvas') as HTMLCanvasElement;
    if (!canvas) return false;
    const ctx = canvas.getContext('2d')!;
    const { width, height } = canvas;
    const img = ctx.getImageData(0, 0, width, height);
    for (let i = 3; i < img.data.length; i += 4) {
      if (img.data[i] !== 0) return true;
    }
    return false;
  });
  expect(hasPixels).toBe(true);
});

test('prism tokens render with theme colors', async ({ page }) => {
  await writeLesson('code', {
    surface: 'lesson', version: 1, topic: 'Code', level: 'beginner',
    sections: [{ type: 'code', language: 'javascript', source: 'const x = 1;' }],
  });
  await page.goto(`${url}/p/demo/code`);
  await page.waitForSelector('vk-code span.token.keyword', { state: 'attached' });
  const { keywordColor, textColor } = await page.evaluate(() => {
    const kw = document.querySelector('vk-code span.token.keyword');
    const txt = document.querySelector('vk-code span:not(.token)') ?? document.querySelector('vk-code code');
    return {
      keywordColor: kw ? getComputedStyle(kw).color : '',
      textColor: txt ? getComputedStyle(txt).color : '',
    };
  });
  expect(keywordColor).not.toBe(textColor);
  expect(keywordColor).not.toBe('');
});

test('modulepreload SRI is set and resolves without CSP violation', async ({ page }) => {
  const violations: string[] = [];
  page.on('console', msg => {
    const text = msg.text();
    if (/Content Security Policy/i.test(text)) violations.push(text);
  });
  await writeLesson('simple', {
    surface: 'lesson', version: 1, topic: 'Simple', level: 'beginner',
    sections: [{ type: 'concept', text: 'hi' }],
  });
  const resp = await page.goto(`${url}/p/demo/simple`);
  expect(resp?.status()).toBe(200);
  // Do NOT waitForLoadState('networkidle') — the page opens a persistent SSE
  // connection (/events/stream) which keeps the network from ever going idle.
  await page.waitForLoadState('domcontentloaded');
  const hasSri = await page.evaluate(() => {
    const link = document.querySelector('link[rel="modulepreload"]');
    return !!link?.getAttribute('integrity');
  });
  expect(hasSri).toBe(true);
  expect(violations).toHaveLength(0);
});

test('quiz multiple_choice is keyboard-accessible', async ({ page }) => {
  await writeLesson('quiz', {
    surface: 'lesson', version: 1, topic: 'Quiz', level: 'beginner',
    sections: [{ type: 'quiz', items: [
      { type: 'multiple_choice', question: 'Q?', options: ['a','b','c'], answer: 'a', explanation: 'ok' },
    ] }],
  });
  await page.goto(`${url}/p/demo/quiz`);
  await page.waitForSelector('vk-quiz button[role="radio"]', { state: 'attached' });
  const first = page.locator('vk-quiz button[role="radio"]').first();
  await first.focus();
  const activeTag = await page.evaluate(() => document.activeElement?.tagName);
  expect(activeTag).toBe('BUTTON');
});

test('CSP blocks inline <script> even if injected via evaluate', async ({ page }) => {
  const violations: string[] = [];
  page.on('console', msg => {
    if (/Content Security Policy/i.test(msg.text())) violations.push(msg.text());
  });
  await writeLesson('csp', {
    surface: 'lesson', version: 1, topic: 'CSP', level: 'beginner',
    sections: [{ type: 'concept', text: 'hi' }],
  });
  await page.goto(`${url}/p/demo/csp`);
  await page.evaluate(() => {
    const s = document.createElement('script');
    s.textContent = 'window.__injected = true';
    document.head.appendChild(s);
  });
  const injected = await page.evaluate(() => (window as any).__injected === true);
  expect(injected).toBe(false);
});
