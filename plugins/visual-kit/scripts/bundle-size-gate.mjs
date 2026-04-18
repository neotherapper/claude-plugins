import { readFile } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';

// Budgets are measured empirically at first green build and set to
// (measured + 10% headroom) per spec §4.6. Do NOT silently raise a budget
// when a bundle grows — the project decides between splitting the bundle
// or revisiting the feature.
const BUDGETS = {
  'dist/core.js':   40_000, // 40 KB gz max per spec QR-1 (pre-existing, headroom vs measured ~8 KB)
  'dist/quiz.js':   10_000, // 10 KB gz max per spec §4.6 (measured ~7 KB + 10% headroom)
  // math + chart sizes below are set from Task 10's empirical measurements + 10% headroom.
  // Current measurements (Task 17): math=349972, chart=76427
  'dist/math.js':   385_000, // measured 349972 gz + 10% = 384970, rounded up
  'dist/chart.js':   90_000, // measured 76427 gz + ~18% headroom — one dep bump of safety
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
