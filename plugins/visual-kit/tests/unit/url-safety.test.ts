import { describe, it, expect } from 'vitest';
import { safeUrl } from '../../src/render/escape.js';

describe('safeUrl', () => {
  it('passes absolute http(s) URLs through unchanged', () => {
    expect(safeUrl('https://example.com/a?b=c#d')).toBe('https://example.com/a?b=c#d');
    expect(safeUrl('http://example.com')).toBe('http://example.com');
  });

  it('passes site-relative and fragment targets', () => {
    expect(safeUrl('/p/paidagogos/ai-engineering')).toBe('/p/paidagogos/ai-engineering');
    expect(safeUrl('#section')).toBe('#section');
  });

  it('rejects the script-bearing schemes', () => {
    expect(safeUrl('javascript:alert(1)')).toBeUndefined();
    expect(safeUrl('JavaScript:alert(1)')).toBeUndefined();
    expect(safeUrl('data:text/html;base64,PHNjcmlwdD4=')).toBeUndefined();
    expect(safeUrl('vbscript:msgbox(1)')).toBeUndefined();
  });

  // Browsers strip control characters before parsing the scheme, so a check
  // that only trims whitespace is bypassed by embedding one.
  it('rejects a scheme smuggled past the check with control characters', () => {
    expect(safeUrl('java\nscript:alert(1)')).toBeUndefined();
    expect(safeUrl('java\tscript:alert(1)')).toBeUndefined();
    expect(safeUrl('  javascript:alert(1)')).toBeUndefined();
    expect(safeUrl('java script:alert(1)')).toBeUndefined();
    expect(safeUrl('java\u0000script:alert(1)')).toBeUndefined();
  });

  // `//evil.com` inherits the current scheme and leaves the origin.
  it('rejects protocol-relative URLs', () => {
    expect(safeUrl('//evil.com/x')).toBeUndefined();
  });

  it('returns undefined for anything that is not a usable string', () => {
    expect(safeUrl(undefined)).toBeUndefined();
    expect(safeUrl(null)).toBeUndefined();
    expect(safeUrl(42)).toBeUndefined();
    expect(safeUrl('')).toBeUndefined();
    expect(safeUrl('   ')).toBeUndefined();
  });
});
