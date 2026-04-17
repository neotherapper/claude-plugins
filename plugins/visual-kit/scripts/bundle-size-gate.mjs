import { readFile } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';

const BUDGETS = {
  'dist/core.js': 40_000, // 40 KB gz max per spec QR-1
};

let failed = false;
for (const [path, max] of Object.entries(BUDGETS)) {
  const body = await readFile(path);
  const gz = gzipSync(body).length;
  const ok = gz <= max;
  console.log(`${path}: ${gz} bytes gz${ok ? '' : ` — exceeds ${max}`}`);
  if (!ok) failed = true;
}
process.exit(failed ? 1 : 0);
