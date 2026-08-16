import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';
import { renderGallery } from '../../src/surfaces/gallery.js';
import { renderFragment } from '../../src/render/ssr.js';

beforeAll(async () => { await loadSchemas(); });

const spec = (items: unknown[]) => ({ surface: 'gallery', version: 1, items });

describe('gallery.v1.json href', () => {
  it('accepts an absolute and a site-relative href', () => {
    expect(validateSpec(spec([{ id: 'a', title: 'A', href: 'https://example.com' }])).ok).toBe(true);
    expect(validateSpec(spec([{ id: 'b', title: 'B', href: '/p/paidagogos/x' }])).ok).toBe(true);
  });

  it('still accepts an item with no href at all', () => {
    expect(validateSpec(spec([{ id: 'c', title: 'C' }])).ok).toBe(true);
  });

  it('rejects a javascript: or protocol-relative href', () => {
    expect(validateSpec(spec([{ id: 'd', title: 'D', href: 'javascript:alert(1)' }])).ok).toBe(false);
    expect(validateSpec(spec([{ id: 'e', title: 'E', href: '//evil.com' }])).ok).toBe(false);
  });
});

describe('renderGallery', () => {
  it('emits data-href on a card that carries one', () => {
    const out = renderFragment(renderGallery({ items: [
      { id: 'a', title: 'AI Engineering', href: '/p/paidagogos/ai-engineering' },
    ] }));
    expect(out).toContain('data-href="/p/paidagogos/ai-engineering"');
  });

  it('omits the attribute entirely when there is no href', () => {
    const out = renderFragment(renderGallery({ items: [{ id: 'a', title: 'A' }] }));
    expect(out).not.toContain('data-href');
  });

  // Defence in depth: the dispatcher can call a renderer on an unvalidated spec.
  it('drops a hostile href even if it reached the renderer unvalidated', () => {
    const out = renderFragment(renderGallery({ items: [
      { id: 'a', title: 'A', href: 'javascript:alert(1)' },
    ] }));
    expect(out).not.toContain('javascript:alert(1)');
    expect(out).not.toContain('data-href');
  });
});
