import { readFile, readdir } from 'node:fs/promises';
import { join, extname } from 'node:path';

const root = 'src/components';
const FORBIDDEN = [
  /\bfetch\s*\(/,
  /\bXMLHttpRequest\b/,
  /\blocalStorage\b/,
  /\bsessionStorage\b/,
  /\bindexedDB\b/,
  /\bnavigator\.serviceWorker\b/,
  /new\s+URL\s*\([^)]*document\.location/,
];

const files = [];
async function walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) await walk(full);
    else if (extname(entry.name) === '.ts') files.push(full);
  }
}
await walk(root);

const issues = [];
for (const f of files) {
  const text = await readFile(f, 'utf8');
  FORBIDDEN.forEach(re => {
    const m = text.match(re);
    if (m) issues.push(`${f}: forbidden pattern ${re}`);
  });
}

if (issues.length) {
  console.error('Pure-component rule violations:\n' + issues.join('\n'));
  process.exit(1);
}
console.log(`Pure-component lint passed (${files.length} files).`);
