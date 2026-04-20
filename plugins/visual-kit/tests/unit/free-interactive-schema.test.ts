import { describe, it, expect, beforeAll } from 'vitest';
import { loadSchemas, validateSpec } from '../../src/render/validate.js';

describe('free-interactive schema validation', () => {
  beforeAll(async () => {
    await loadSchemas();
  });

  it('accepts a minimal valid spec', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: '<!DOCTYPE html><html><body>hi</body></html>',
    };
    const res = validateSpec(spec);
    expect(res).toEqual({ ok: true, kind: 'free-interactive' });
  });

  it('accepts a spec with optional title', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      title: 'Parabola',
      html: '<div>inline</div>',
    };
    expect(validateSpec(spec).ok).toBe(true);
  });

  it('rejects missing html', () => {
    const spec = { surface: 'free-interactive', version: 1 };
    const res = validateSpec(spec);
    expect(res.ok).toBe(false);
  });

  it('rejects wrong surface value', () => {
    const spec = { surface: 'free-interactive-bogus', version: 1, html: 'x' };
    expect(validateSpec(spec).ok).toBe(false);
  });

  it('rejects wrong version', () => {
    const spec = { surface: 'free-interactive', version: 2, html: 'x' };
    expect(validateSpec(spec).ok).toBe(false);
  });

  it('rejects html over the 500 KB ceiling', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: 'x'.repeat(500_001),
    };
    const res = validateSpec(spec);
    expect(res.ok).toBe(false);
  });

  it('rejects extra properties', () => {
    const spec = {
      surface: 'free-interactive',
      version: 1,
      html: 'ok',
      rogue: 'nope',
    };
    expect(validateSpec(spec).ok).toBe(false);
  });
});
