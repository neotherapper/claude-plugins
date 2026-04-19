import { build } from 'esbuild';
import { mkdir, writeFile, readFile, copyFile, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const pkg = JSON.parse(await readFile('package.json', 'utf8'));
const version = pkg.version;

await mkdir('dist', { recursive: true });

// Static asset copy (theme.css + schemas).
await copyFile('src/components/theme.css', 'dist/theme.css');
const schemaDestDir = 'dist/schemas/surfaces';
await mkdir(schemaDestDir, { recursive: true });
const schemaFiles = await readdir('schemas/surfaces');
await Promise.all(
  schemaFiles
    .filter(f => f.endsWith('.json'))
    .map(f => copyFile(join('schemas/surfaces', f), join(schemaDestDir, f))),
);

// ── KaTeX CSS inliner plugin ─────────────────────────────────────────────
// Intercepts `import katexCss from 'katex/dist/katex.css'`, reads the file,
// strips non-woff2 src entries, rewrites url(./fonts/*.woff2) to data URLs,
// and returns the CSS as text.
const katexCssPath = require.resolve('katex/dist/katex.css');
const katexDir = dirname(katexCssPath);

function stripNonWoff2(css) {
  // In each `src: ...;` declaration, keep only the url(...) format('woff2') entries.
  return css.replace(/src\s*:\s*([^;]+);/g, (_m, body) => {
    const entries = body.split(',').map(e => e.trim());
    const woff2Only = entries.filter(e => /format\(['"]?woff2['"]?\)/.test(e));
    if (woff2Only.length === 0) {
      // Unexpected: KaTeX CSS src block has no woff2 entries — keeping original.
      // Investigate at next KaTeX version bump; this may indicate a format change
      // that would break the self-contained CSP font requirement.
      console.warn('[katex-css-inliner] stripNonWoff2: no woff2 entries found in src block — keeping original');
      return `src: ${body};`;
    }
    return `src: ${woff2Only.join(', ')};`;
  });
}

const katexCssInliner = {
  name: 'katex-css-inliner',
  setup(b) {
    b.onResolve({ filter: /katex\/dist\/katex\.css$/ }, (args) => ({
      path: katexCssPath,
      namespace: 'katex-css',
    }));
    b.onLoad({ filter: /.*/, namespace: 'katex-css' }, async () => {
      const raw = await readFile(katexCssPath, 'utf8');
      const stripped = stripNonWoff2(raw);
      const inlined = await inlineFontUrls(stripped, katexDir);
      return { contents: inlined, loader: 'text' };
    });
  },
};

async function inlineFontUrls(css, baseDir) {
  // Match url(fonts/…) and url(./fonts/…) — KaTeX ships the former.
  const pattern = /url\(["']?(\.?\/?fonts\/[^)"']+)["']?\)/g;
  // Dedupe by URL string so each font file is read once.
  const seen = new Map();
  for (const m of css.matchAll(pattern)) {
    if (!seen.has(m[0])) seen.set(m[0], m[1]);
  }
  let out = css;
  for (const [urlToken, rel] of seen) {
    const absPath = join(baseDir, rel);
    let bytes;
    try {
      bytes = await readFile(absPath);
    } catch {
      console.warn(`[katex-css-inliner] missing font file: ${rel} — leaving URL as-is`);
      continue;
    }
    const mime = rel.endsWith('.woff2') ? 'font/woff2'
              : rel.endsWith('.woff') ? 'font/woff'
              : rel.endsWith('.ttf') ? 'font/ttf'
              : 'application/octet-stream';
    const b64 = bytes.toString('base64');
    const dataUrl = `url(data:${mime};base64,${b64})`;
    // replaceAll replaces every occurrence of this URL token in one pass.
    out = out.replaceAll(urlToken, dataUrl);
  }
  // Invariant: no bare font URL should remain after inlining.
  if (/url\(["']?\.?\/?fonts\//.test(out)) {
    throw new Error('[katex-css-inliner] post-inline invariant failed: bare font URL remains in output');
  }
  return out;
}

// ── Browser bundles (one per component entry) ────────────────────────────
const browserBundles = [
  { name: 'core',  entry: 'src/components/index.ts', outfile: 'dist/core.js'  },
  { name: 'math',  entry: 'src/components/math.ts',  outfile: 'dist/math.js'  },
  { name: 'chart', entry: 'src/components/chart.ts', outfile: 'dist/chart.js' },
  { name: 'quiz',  entry: 'src/components/quiz.ts',  outfile: 'dist/quiz.js'  },
];

const sriByName = {};
for (const b of browserBundles) {
  await build({
    entryPoints: [b.entry],
    outfile: b.outfile,
    bundle: true,
    minify: true,
    format: 'esm',
    target: ['es2022'],
    sourcemap: false,
    platform: 'browser',
    loader: { '.css': 'text' },
    plugins: b.name === 'math' ? [katexCssInliner] : [],
    logLevel: 'info',
  });
  const bytes = await readFile(b.outfile);
  const sri = 'sha384-' + createHash('sha384').update(bytes).digest('base64');
  sriByName[b.name] = sri;
  await writeFile(`${b.outfile}.sri.txt`, sri);
}

// ── Shared define block for node-side bundles ────────────────────────────
const baseDefine = {
  __VK_VERSION__: JSON.stringify(version),
  __VK_CORE_SRI__:  JSON.stringify(sriByName.core),
  __VK_MATH_SRI__:  JSON.stringify(sriByName.math),
  __VK_CHART_SRI__: JSON.stringify(sriByName.chart),
  __VK_QUIZ_SRI__:  JSON.stringify(sriByName.quiz),
};

await build({
  entryPoints: ['src/cli/index.ts'],
  outfile: 'dist/cli.js',
  bundle: true, minify: false, platform: 'node', target: ['node20'],
  format: 'esm', packages: 'external',
  define: { ...baseDefine, __VK_ASSET_OFFSET__: JSON.stringify('') },
  logLevel: 'info',
});

await build({
  entryPoints: ['src/server/index.ts'],
  outfile: 'dist/server/index.js',
  bundle: true, minify: false, platform: 'node', target: ['node20'],
  format: 'esm', packages: 'external',
  define: { ...baseDefine, __VK_ASSET_OFFSET__: JSON.stringify('../') },
  logLevel: 'info',
});

console.log('visual-kit build complete. SRIs:', sriByName);
