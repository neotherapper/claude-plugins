// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from 'vitest';
import '../../src/components/quiz.js';

function makeQuiz(items: unknown): HTMLElement {
  const el = document.createElement('vk-quiz');
  const sc = document.createElement('script');
  sc.type = 'application/json';
  sc.textContent = JSON.stringify({ items });
  el.appendChild(sc);
  return el;
}

describe('<vk-quiz>', () => {
  beforeEach(() => { document.body.innerHTML = ''; });

  it('renders <vk-error> when no config script is present', async () => {
    const el = document.createElement('vk-quiz');
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('vk-error');
  });

  it('renders <vk-error> when JSON is malformed', async () => {
    const el = document.createElement('vk-quiz');
    const sc = document.createElement('script');
    sc.type = 'application/json';
    sc.textContent = 'not-json';
    el.appendChild(sc);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('vk-error');
  });

  it('renders <vk-error> when items array is empty', async () => {
    const el = makeQuiz([]);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('vk-error');
  });

  it('renders multiple_choice items with radio-like buttons', async () => {
    const el = makeQuiz([
      { type: 'multiple_choice', question: 'Q?', options: ['a', 'b'], answer: 'a', explanation: 'ok' },
    ]);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('Q?');
    expect(el.innerHTML).toContain('"a"');
    expect(el.innerHTML).toContain('"b"');
  });

  it('renders fill_blank items with an input', async () => {
    const el = makeQuiz([
      { type: 'fill_blank', question: 'fill__', answer: 'x', explanation: 'y' },
    ]);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('<input');
  });

  it('renders explain items with a textarea', async () => {
    const el = makeQuiz([
      { type: 'explain', question: 'why?', answer: 'because', explanation: 'ref' },
    ]);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('<textarea');
  });

  it('emits vk-event with correct shape on multiple_choice click', async () => {
    const el = makeQuiz([
      { type: 'multiple_choice', question: 'Q?', options: ['a', 'b'], answer: 'a', explanation: 'ok' },
    ]);
    document.body.appendChild(el);
    await (el as any).updateComplete;

    const received: unknown[] = [];
    el.addEventListener('vk-event', (e) => received.push((e as CustomEvent).detail));

    const correctButton = el.querySelector<HTMLButtonElement>('button[data-value="a"]');
    expect(correctButton).not.toBeNull();
    correctButton!.click();

    expect(received.length).toBe(1);
    const ev = received[0] as any;
    expect(ev.type).toBe('quiz_answer');
    expect(ev.index).toBe(0);
    expect(ev.item_type).toBe('multiple_choice');
    expect(ev.chosen).toBe('a');
    expect(ev.correct).toBe(true);
    expect(typeof ev.ts).toBe('string');
  });

  it('caps chosen at 1024 chars', async () => {
    const el = makeQuiz([
      { type: 'explain', question: 'why?', answer: 'ref', explanation: 'x' },
    ]);
    document.body.appendChild(el);
    await (el as any).updateComplete;

    const received: any[] = [];
    el.addEventListener('vk-event', (e) => received.push((e as CustomEvent).detail));

    const textarea = el.querySelector('textarea') as HTMLTextAreaElement;
    textarea.value = 'a'.repeat(5000);
    const submit = el.querySelector<HTMLButtonElement>('button[data-submit="0"]');
    submit!.click();

    expect(received[0].chosen.length).toBe(1024);
  });
});
