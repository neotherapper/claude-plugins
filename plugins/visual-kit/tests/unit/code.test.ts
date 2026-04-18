import { describe, it, expect } from 'vitest';
import { html } from 'lit';
import { renderFragment } from '../../src/render/ssr.js';
import '../../src/components/code.js';

describe('vk-code (upgraded)', () => {
  it('renders with language attribute and slotted content', () => {
    const out = renderFragment(html`<vk-code language="javascript"><span class="token keyword">const</span> x;</vk-code>`);
    expect(out).toContain('vk-code');
    expect(out).toContain('language="javascript"');
    expect(out).toContain('token keyword');
  });

  it('exposes a copy button in its shadow DOM via declarative shadow DOM', () => {
    const out = renderFragment(html`<vk-code language="python">print(1)</vk-code>`);
    expect(out).toMatch(/<template shadowroot(?:mode)?="open"/);
    expect(out).toContain('<button');
    expect(out).toContain('copy');
  });

  it('injects Prism theme styles into shadow DOM', () => {
    const out = renderFragment(html`<vk-code language="json">{"a":1}</vk-code>`);
    expect(out).toContain('.token.keyword');
  });
});
