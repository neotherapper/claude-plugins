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
