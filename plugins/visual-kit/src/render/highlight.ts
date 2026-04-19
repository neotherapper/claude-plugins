import Prism from 'prismjs';
// Explicit language registration — avoids loading every language Prism supports.
import 'prismjs/components/prism-javascript.js';
import 'prismjs/components/prism-typescript.js';
import 'prismjs/components/prism-python.js';
import 'prismjs/components/prism-css.js';
import 'prismjs/components/prism-markup.js';  // html
import 'prismjs/components/prism-json.js';
import 'prismjs/components/prism-bash.js';
import 'prismjs/components/prism-markdown.js';
import 'prismjs/components/prism-sql.js';

const KNOWN = new Set([
  'javascript', 'typescript', 'python', 'css',
  'html', 'json', 'bash', 'markdown', 'sql',
]);

// Input cap — some Prism grammars (notably Markdown, Markup) have historically
// exhibited ReDoS with crafted input. Any source over the cap is escape-only.
// Named CHARS because String.length counts UTF-16 code units, not bytes.
const MAX_INPUT_CHARS = 100_000;

function escapeHtml(s: string): string {
  return s.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]!));
}

export function highlightToHtml(language: string, source: string): string {
  if (source.length > MAX_INPUT_CHARS) return escapeHtml(source);
  if (!KNOWN.has(language)) return escapeHtml(source);
  // 'html' maps to Prism's 'markup' grammar.
  const grammarKey = language === 'html' ? 'markup' : language;
  const grammar = Prism.languages[grammarKey];
  if (!grammar) return escapeHtml(source);
  return Prism.highlight(source, grammar, language);
}
