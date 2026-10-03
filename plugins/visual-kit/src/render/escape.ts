// Escape JSON for safe embedding inside <script type="application/json">.
// Neutralizes HTML parser state transitions (</script, <!--, -->) and JS
// parser hazards (line-terminator bytes) in case the content is ever
// inadvertently routed through JSON.parse-after-read or eval-like paths.
const ESCAPES: Record<string, string> = {
  '<':      '\\u003c',
  '>':      '\\u003e',
  '&':      '\\u0026',
  '\u2028': '\\u2028',
  '\u2029': '\\u2029',
};

export function unsafeJSON(value: unknown): string {
  return JSON.stringify(value).replace(/[<>&\u2028\u2029]/g, c => ESCAPES[c]!);
}

/**
 * Vets a spec-supplied URL before it reaches an href.
 *
 * SurfaceSpecs are AI-authored, so a URL in one is untrusted input. The strict
 * CSP blocks `javascript:` from executing, but the free-interactive surface
 * ships without CSP by design, so the scheme check cannot be delegated to it.
 *
 * Control characters are stripped first: browsers ignore them when parsing the
 * scheme, so `java\nscript:` reaches the parser as `javascript:` and a check
 * that only trims whitespace lets it through.
 */
const ALLOWED_TARGET = /^(?:https?:\/\/|\/(?!\/)|#)/i;

export function safeUrl(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  // Strip C0/C1 controls *and* spaces before reading the scheme, so both
  // `java\nscript:` and `java script:` collapse to a form the test rejects.
  const cleaned = raw.replace(/[\u0000-\u0020\u007F-\u00A0]/g, '');
  if (!cleaned) return undefined;
  return ALLOWED_TARGET.test(cleaned) ? raw.trim() : undefined;
}
