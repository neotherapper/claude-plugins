import { describe, it, expect, beforeEach } from 'vitest';
import { html } from 'lit';
import { registerSurface, renderSurface } from '../../src/render/dispatcher.js';
import { renderFragment } from '../../src/render/ssr.js';

describe('renderSurface', () => {
  beforeEach(() => {
    registerSurface('lesson', (spec: { topic: string }) => html`<vk-section>${spec.topic}</vk-section>`);
  });

  it('renders a registered surface', () => {
    const tr = renderSurface({ surface: 'lesson', version: 1, topic: 'Hello' });
    const out = renderFragment(tr);
    expect(out).toContain('vk-section');
    expect(out).toContain('Hello');
  });

  it('returns vk-error for unknown surface', () => {
    const tr = renderSurface({ surface: 'unknown', version: 1 });
    const out = renderFragment(tr);
    expect(out).toContain('vk-error');
    expect(out).toContain('Unknown surface');
  });

  it('returns vk-error on malformed input', () => {
    const tr = renderSurface({} as never);
    const out = renderFragment(tr);
    expect(out).toContain('Invalid SurfaceSpec');
  });
});
