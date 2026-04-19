import { readFile, readdir } from 'node:fs/promises';
import { join, extname, relative } from 'node:path';

const COMPONENTS_ROOT = 'src/components';
const SRC_ROOT = 'src';

// Forbidden in components — pure-component rule (RR-1 / AR-7).
const COMPONENT_FORBIDDEN = [
  /\bfetch\s*\(/,
  /\bXMLHttpRequest\b/,
  /\blocalStorage\b/,
  /\bsessionStorage\b/,
  /\bindexedDB\b/,
  /\bnavigator\.serviceWorker\b/,
  /new\s+URL\s*\([^)]*document\.location/,
];

// Forbidden anywhere under src/ — AR-8 (no string-concat HTML) and no eval.
const SRC_FORBIDDEN_ALL = [
  { pattern: /\bnew\s+Function\s*\(/, message: 'new Function() is forbidden' },
  { pattern: /\beval\s*\(/,           message: 'eval() is forbidden' },
];

// unsafeHTML import is allowed only in src/surfaces/lesson.ts.
// unsafeJSON import is allowed only in src/surfaces/lesson.ts and src/render/escape.ts.
const UNSAFE_HTML_RE = /\bunsafeHTML\b/;
const UNSAFE_JSON_RE = /\bunsafeJSON\b/;
const UNSAFE_HTML_ALLOWED = new Set(['src/surfaces/lesson.ts']);
const UNSAFE_JSON_ALLOWED = new Set(['src/surfaces/lesson.ts', 'src/render/escape.ts']);

async function walk(dir, acc = []) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) await walk(full, acc);
    else if (extname(entry.name) === '.ts') acc.push(full);
  }
  return acc;
}

const componentFiles = await walk(COMPONENTS_ROOT);
const srcFiles = await walk(SRC_ROOT);
const issues = [];

for (const f of componentFiles) {
  const text = await readFile(f, 'utf8');
  COMPONENT_FORBIDDEN.forEach(re => {
    if (re.test(text)) issues.push(`${f}: forbidden pattern ${re}`);
  });
}

for (const f of srcFiles) {
  const text = await readFile(f, 'utf8');
  const rel = relative('.', f).replace(/\\/g, '/');
  for (const { pattern, message } of SRC_FORBIDDEN_ALL) {
    if (pattern.test(text)) issues.push(`${rel}: ${message}`);
  }
  if (UNSAFE_HTML_RE.test(text) && !UNSAFE_HTML_ALLOWED.has(rel)) {
    issues.push(`${rel}: unsafeHTML used outside allowlist (allowed: ${[...UNSAFE_HTML_ALLOWED].join(', ')})`);
  }
  if (UNSAFE_JSON_RE.test(text) && !UNSAFE_JSON_ALLOWED.has(rel)) {
    issues.push(`${rel}: unsafeJSON used outside allowlist (allowed: ${[...UNSAFE_JSON_ALLOWED].join(', ')})`);
  }
}

if (issues.length) {
  console.error('lint-pure-components violations:\n' + issues.join('\n'));
  process.exit(1);
}
console.log(`lint-pure-components passed (${componentFiles.length} component files, ${srcFiles.length} total src files).`);
