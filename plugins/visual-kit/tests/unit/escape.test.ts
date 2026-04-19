import { describe, it, expect } from 'vitest';
import { unsafeJSON } from '../../src/render/escape.js';

describe('unsafeJSON', () => {
  it('round-trips plain JSON values', () => {
    const input = { a: 1, b: 'hello', c: [true, null, 2.5] };
    expect(JSON.parse(unsafeJSON(input))).toEqual(input);
  });

  it('escapes < to \\u003c (neutralizes </script> break)', () => {
    const out = unsafeJSON({ raw: '</script><img src=x onerror=alert(1)>' });
    expect(out).not.toContain('</script');
    expect(out).toContain('\\u003c/script');
  });

  it('escapes > to \\u003e (neutralizes --> transitions)', () => {
    const out = unsafeJSON({ raw: '-->' });
    expect(out).not.toContain('-->');
    expect(out).toContain('\\u003e');
  });

  it('escapes & to \\u0026 (neutralizes entity ambiguity)', () => {
    const out = unsafeJSON({ raw: '&amp;' });
    expect(out).toContain('\\u0026');
  });

  it('escapes U+2028 and U+2029 (JS line terminator hazards)', () => {
    const out = unsafeJSON({ raw: '\u2028\u2029' });
    expect(out).toContain('\\u2028');
    expect(out).toContain('\\u2029');
    expect(out).not.toMatch(/[\u2028\u2029]/);
  });

  it('does not double-escape safe characters', () => {
    const out = unsafeJSON({ n: 42, s: 'plain' });
    expect(out).toContain('"plain"');
    expect(out).toContain('42');
  });

  it('preserves unicode content that is not a hazard', () => {
    const out = unsafeJSON({ s: 'café — naïve — 日本語' });
    expect(JSON.parse(out).s).toBe('café — naïve — 日本語');
  });

  it('escapes the HTML comment start <!-- when present', () => {
    const out = unsafeJSON({ raw: '<!--' });
    expect(out).not.toContain('<!--');
    expect(out).toContain('\\u003c!--');
  });
});
