// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock Chart.js BEFORE importing the component (module-scope imports happen in order).
vi.mock('chart.js/auto', () => ({
  Chart: class {
    constructor() { /* stub */ }
    destroy() { /* stub */ }
  },
}));

import '../../src/components/chart.js';

describe('<vk-chart>', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('renders error when no config script is present', async () => {
    const el = document.createElement('vk-chart');
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('missing config script');
  });

  it('error element uses CSS class, not inline style (CSP compliance)', async () => {
    const el = document.createElement('vk-chart');
    document.body.appendChild(el);
    await (el as any).updateComplete;
    const errorEl = el.querySelector('.vk-component-error');
    expect(errorEl).not.toBeNull();
    expect(errorEl?.hasAttribute('style')).toBe(false);
  });

  it('renders error for invalid JSON', async () => {
    const el = document.createElement('vk-chart');
    const sc = document.createElement('script');
    sc.type = 'application/json';
    sc.textContent = '{not valid json';
    el.appendChild(sc);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('invalid config JSON');
  });

  it('renders error when config contains disallowed callback fields', async () => {
    const el = document.createElement('vk-chart');
    const sc = document.createElement('script');
    sc.type = 'application/json';
    sc.textContent = JSON.stringify({
      type: 'bar',
      data: { datasets: [] },
      options: { onClick: 'alert(1)' },
    });
    el.appendChild(sc);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.innerHTML).toContain('disallowed callback fields');
  });

  it('creates a canvas for a valid config', async () => {
    const el = document.createElement('vk-chart');
    const sc = document.createElement('script');
    sc.type = 'application/json';
    sc.textContent = JSON.stringify({ type: 'bar', data: { labels: ['a'], datasets: [{ data: [1] }] } });
    el.appendChild(sc);
    document.body.appendChild(el);
    await (el as any).updateComplete;
    expect(el.querySelector('canvas')).not.toBeNull();
  });
});
