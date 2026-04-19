// @vitest-environment jsdom
// Separate file so vi.mock hoisting doesn't affect math.test.ts (which tests
// real KaTeX rendering). Mocks katex to always throw, exercising the catch branch.
import { describe, it, expect, vi } from 'vitest';

vi.mock('katex', () => ({
  default: {
    renderToString: vi.fn((): never => {
      throw new Error('katex internal error (mocked)');
    }),
  },
}));

import '../../src/components/math.js';

describe('<vk-math> error state — catch path', () => {
  it('error element uses CSS class, not inline style (CSP compliance)', async () => {
    const el = document.createElement('vk-math') as any;
    el.textContent = 'x';
    document.body.appendChild(el);
    await el.updateComplete;
    const errorEl = el.querySelector('.vk-component-error');
    expect(errorEl).not.toBeNull();
    expect(errorEl?.hasAttribute('style')).toBe(false);
    document.body.innerHTML = '';
  });
});
