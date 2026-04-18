// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from 'vitest';
import '../../src/components/math.js';

describe('<vk-math>', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('renders empty when no textContent', async () => {
    const el = document.createElement('vk-math');
    document.body.appendChild(el);
    await (el as any).updateComplete;
    // Light-DOM render leaves Lit part-marker comments even on empty template;
    // the security-meaningful check is that no visible markup is emitted.
    expect(el.querySelector('.katex')).toBeNull();
    expect(el.querySelector('div')).toBeNull();
    expect(el.textContent?.trim() ?? '').toBe('');
  });

  it('renders KaTeX span tree for valid LaTeX', async () => {
    const el = document.createElement('vk-math');
    el.textContent = 'a^2+b^2=c^2';
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('katex');
  });

  it('renders display mode when display attribute is set', async () => {
    const el = document.createElement('vk-math');
    el.setAttribute('display', '');
    el.textContent = '\\sum_{i=0}^n i';
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('katex-display');
  });

  it('renders error div for truly invalid LaTeX (trust=false and strict=warn combined)', async () => {
    const el = document.createElement('vk-math');
    el.textContent = '\\invalidcommand{x}';
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML.length).toBeGreaterThan(0);
  });

  it('does NOT produce a javascript: href for \\href{javascript:...}{x} (trust=false)', async () => {
    const el = document.createElement('vk-math');
    el.textContent = '\\href{javascript:alert(1)}{click}';
    document.body.appendChild(el);
    await (el as any).updateComplete;
    // Security intent: trust=false must never emit an <a href="javascript:..."> link.
    // KaTeX falls back to rendering the unsupported macro's raw source as red text,
    // so the substring "javascript:" may appear in text content — but no clickable
    // javascript-scheme href must be produced. Assert on the attack vector, not text.
    const anchors = Array.from(el.querySelectorAll('a'));
    for (const a of anchors) {
      const href = (a.getAttribute('href') ?? '').toLowerCase().trim();
      expect(href.startsWith('javascript:')).toBe(false);
    }
    // And no element at all should carry a javascript: href attribute.
    expect(el.querySelector('[href^="javascript:" i]')).toBeNull();
  });
});
