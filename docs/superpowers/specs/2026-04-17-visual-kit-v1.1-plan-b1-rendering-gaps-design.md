# Visual-Kit v1.1 — Plan B1: Rendering Gaps

**Date:** 2026-04-17
**Status:** Approved
**Scope:** Fix all "not yet supported" section renderers in the current visual-kit `lesson` surface. Ship `<vk-math>`, `<vk-chart>`, `<vk-quiz>` as new bundles; upgrade `<vk-code>` with server-side syntax highlighting.

---

## 1. Context

Visual-kit `1.0.0` (Plan A) shipped the server, six SurfaceSpec types, and the core component bundle covering layout primitives (`<vk-section>`, `<vk-card>`, `<vk-gallery>`, `<vk-outline>`, `<vk-comparison>`, `<vk-feedback>`, `<vk-loader>`, `<vk-error>`, minimal `<vk-code>`). Paidagogos migrated away from its in-house server and now depends on visual-kit for all rendering.

Plan B1 mixes two kinds of work, both required to complete visual-kit's lesson surface.

**Regression fixes** — sections `paidagogos:micro` emits today that render incompletely:

- `code` — renders as plain `<pre>` + copy button; no syntax highlighting. Pre-visual-kit paidagogos had Prism output.
- `quiz` — fully emitted by `paidagogos:micro` (3 items: one each of `multiple_choice`, `fill_blank`, `explain`) but hits the surface renderer's `default` fallback: *"Section type 'quiz' not yet supported in the core bundle. Install Plan B for code, math, chart, quiz renderers."* Pre-visual-kit paidagogos had a working quiz UI.

**Capability enablement** — section types the schema marks "Future work — Plan B" in `paidagogos-micro/references/lesson-schema.md` that the skill does NOT emit today:

- `math` — LaTeX rendering
- `chart` — Chart.js rendering

These components ship in B1 so a subsequent skill update (not in B1 scope) can start generating them with confidence. Shipping the components alone produces no user-visible change; it sets the foundation that lets `paidagogos:micro` (and future consumers) emit these section types without a second visual-kit release.

**Infrastructure** — the fragment-scanning autoloader that the V1 design spec describes (§5.5) but Plan A deferred. Without it, `[coreBundle]` is hardcoded at `src/server/index.ts:200`, and no non-core bundle can load. Blocking for both the regression fixes (`<vk-quiz>` needs `quiz.js`) and the capability enablement (`<vk-math>` needs `math.js`, `<vk-chart>` needs `chart.js`).

**Roadmap position.** Plan B total (per ADR D-06) has three phases:
- **B1 (this spec):** rendering gaps — code, chart, math, quiz
- **B2 (later):** new consumer migrations — namesmith gallery, draftloom comparison
- **B3 (later, on demand):** geometry, sim-2d, pedagogy (progress/streak/hint), editable code via CodeMirror 6

Plan C (heavy bundles: Three.js, Pyodide, Sandpack) remains deferred to concrete consumer demand.

---

## 2. Goals

- **G-1** After B1, every section type `paidagogos:micro` emits today (`code`, `quiz`) renders fully. No `vk-error` fallback visible in generated lessons.
- **G-2** Ship `<vk-math>` and `<vk-chart>` components + `math.js` / `chart.js` bundles so `paidagogos:micro` (in a future skill update) and other consumers can emit math/chart section types without a second visual-kit release.
- **G-3** Ship three new component bundles — `math.js`, `chart.js`, `quiz.js` — served at `/vk/<bundle>.js` with SRI.
- **G-4** Upgrade `<vk-code>` to display syntax-highlighted source via server-side Prism. The component itself stays in `core.js` with no added runtime JS; only Prism theme CSS ships in the bundle.
- **G-5** Implement the fragment-scanning autoloader the visual-kit design spec (§5.5) describes but Plan A deferred. Lessons that use only some section types load only the bundles they need.
- **G-6** Maintain additive schema compatibility. No breaking changes. `GET /vk/capabilities` gains three bundle entries.
- **G-7** Paidagogos continues to work without a skill change. Bumping the `visual-kit` dependency from `~1.0.0` to `~1.1.0` is the only consumer-side edit.

### Non-goals

- **NG-1** No new section types in `lesson.v1.json` (geometry, sim-2d, hint, explain-as-section, audio) — all deferred to future plans.
- **NG-2** No editable code. Schema change (`code.editable: boolean`) and CodeMirror 6 bundle are B3 scope.
- **NG-3** No progress or streak components. `.paidagogos/prefs.json` schema design is a separate spec.
- **NG-4** No consumer migrations (namesmith, draftloom). B2 scope.
- **NG-5** No changes to `paidagogos:micro` or its reference files.

---

## 3. Architecture

### 3.1 Bundle layout after B1

```
plugins/visual-kit/dist/
├── core.js          ← Plan A + Prism theme CSS (small, ~3 KB addition)
├── chart.js         ← new — Chart.js 4.x + <vk-chart>
├── math.js          ← new — KaTeX + KaTeX CSS + KaTeX fonts (data-URL) + <vk-math>
└── quiz.js          ← new — <vk-quiz> (no external dep)
```

Bundle budget:
- `core.js` stays ≤ 40 KB gz (QR-1). Prism theme CSS is ~2 KB gz; current core headroom is ~5 KB.
- `math.js` is the heaviest new bundle (~110 KB gz — KaTeX core + fonts). Lazy-loaded only when a lesson contains a `math` section.
- `chart.js` is ~65 KB gz (Chart.js 4.x tree-shaken to only the chart types lessons use).
- `quiz.js` is ~4 KB gz (no external dep).

Server-side Prism (node dependency only) adds no browser bytes.

### 3.2 Fragment-scanning autoloader

Plan A hardcodes `bundles: [coreBundle]` in the server. B1 replaces this with a scan-then-resolve step.

New file `src/render/autoload.ts`:

```ts
import type { BundleRef } from './shell.js';

// Tag → bundle name (resolved to full BundleRef via capabilities at render time)
const TAG_TO_BUNDLE: Record<string, string> = {
  'vk-math':  'math',
  'vk-chart': 'chart',
  'vk-quiz':  'quiz',
  // core-bundle tags are NOT listed — core is always loaded
};

// Scan rendered HTML for <vk-*> opening tags in tag-name position only.
// Lookahead requires whitespace, '>', or '/' after the tag name —
// prevents false matches on attribute values or similar contexts.
const TAG_PATTERN = /<(vk-[a-z0-9-]+)(?=[\s/>])/g;

export function discoverRequiredBundles(fragmentHtml: string): string[] {
  const tags = new Set<string>();
  for (const match of fragmentHtml.matchAll(TAG_PATTERN)) {
    tags.add(match[1]!);
  }
  // Subset assertion: every discovered tag not in a known bundle registry
  // (neither TAG_TO_BUNDLE nor the core tag set) is a bug — fail loudly.
  const knownBundleTags = new Set(Object.keys(TAG_TO_BUNDLE));
  const knownCoreTags = new Set([
    'vk-section','vk-card','vk-gallery','vk-outline','vk-comparison',
    'vk-feedback','vk-loader','vk-error','vk-code',
  ]);
  for (const tag of tags) {
    if (!knownBundleTags.has(tag) && !knownCoreTags.has(tag)) {
      throw new Error(`Unknown <vk-*> tag in rendered fragment: ${tag}`);
    }
  }
  const bundles = new Set<string>();
  for (const tag of tags) {
    const name = TAG_TO_BUNDLE[tag];
    if (name) bundles.add(name);
  }
  return [...bundles];
}

export async function resolveBundleRefs(
  names: string[],
  capabilities: { bundles: Array<{ name: string; url: string; sri: string }> },
): Promise<BundleRef[]> {
  // Always prepend core. Then append each discovered bundle in declaration order.
  const refs: BundleRef[] = [];
  const core = capabilities.bundles.find(b => b.name === 'core');
  if (core) refs.push({ url: core.url, sri: core.sri });
  for (const name of names) {
    const found = capabilities.bundles.find(b => b.name === name);
    if (found) refs.push({ url: found.url, sri: found.sri });
  }
  return refs;
}
```

Server integration in `src/server/index.ts`:

```ts
// replacing the old: const coreBundle = await resolveCoreBundle(version); bundles: [coreBundle]
const fragment = renderFragment(renderSurface(spec as never));
const needed = discoverRequiredBundles(fragment);
const bundles = await resolveBundleRefs(needed, await buildCapabilities(version));
const { html, headers } = buildShell({ ..., bundles, fragment });
```

**Regex rationale.** Rendered fragments come from lit-html SSR, which escapes `<` in text and attribute-value contexts. The tag-position lookahead `(?=[\s/>])` further constrains matches to actual tag positions. The subset assertion ensures an unknown `<vk-*>` tag — which in a correct system is impossible — fails the render with a clear error rather than silently loading the wrong set of bundles.

**Tag map grows additively.** Adding a future component (`<vk-geometry>` in B3) = one line in `TAG_TO_BUNDLE` + one line in the `knownCoreTags` set if applicable.

### 3.2a Per-bundle SRI — build plumbing

Plan A's `scripts/build.mjs` hashes `dist/core.js` and writes the SRI into `dist/core.js.sri.txt`. The built core bundle is then produced with an `esbuild define` that inlines `__VK_CORE_SRI__` into `capabilities.ts`, which in turn returns the SRI to the server at runtime.

B1 generalizes this from a single bundle to a loop over every bundle:

```js
// scripts/build.mjs (sketch — ports the existing core.js flow to a per-entry loop)
const bundles = [
  { name: 'core',  entry: 'src/components/index.ts', outfile: 'dist/core.js'  },
  { name: 'math',  entry: 'src/components/math.ts',  outfile: 'dist/math.js'  },
  { name: 'chart', entry: 'src/components/chart.ts', outfile: 'dist/chart.js' },
  { name: 'quiz',  entry: 'src/components/quiz.ts',  outfile: 'dist/quiz.js'  },
];

const sriByName = {};
for (const b of bundles) {
  await build({ entryPoints: [b.entry], outfile: b.outfile, bundle: true, minify: true,
                format: 'esm', target: ['es2022'], platform: 'browser',
                loader: { '.css': 'text' } });
  const bytes = await readFile(b.outfile);
  sriByName[b.name] = 'sha384-' + createHash('sha384').update(bytes).digest('base64');
  await writeFile(`${b.outfile}.sri.txt`, sriByName[b.name]);
}

// Re-build capabilities with per-bundle defines inlined.
await build({
  entryPoints: ['src/server/capabilities.ts'],
  outfile: 'dist/capabilities.js',
  bundle: true, platform: 'node', format: 'esm',
  define: Object.fromEntries(
    Object.entries(sriByName).map(([n, sri]) => [`__VK_${n.toUpperCase()}_SRI__`, JSON.stringify(sri)]),
  ),
});
```

`src/server/capabilities.ts` reads the defines:

```ts
declare const __VK_CORE_SRI__: string;
declare const __VK_MATH_SRI__: string;
declare const __VK_CHART_SRI__: string;
declare const __VK_QUIZ_SRI__: string;

export async function buildCapabilities(version: string) {
  return {
    visual_kit_version: version,
    schema_version: 1,
    surfaces: { /* unchanged */ },
    components: [ /* unchanged + 'vk-math', 'vk-chart', 'vk-quiz' */ ],
    bundles: [
      { name: 'core',  url: '/vk/core.js',  sri: __VK_CORE_SRI__  },
      { name: 'math',  url: '/vk/math.js',  sri: __VK_MATH_SRI__  },
      { name: 'chart', url: '/vk/chart.js', sri: __VK_CHART_SRI__ },
      { name: 'quiz',  url: '/vk/quiz.js',  sri: __VK_QUIZ_SRI__  },
    ],
  };
}
```

No change to `src/server/index.ts`'s `/vk/*` handler — it already serves any file from `dist/` matching the path.

### 3.2b Scoped AR-8 exceptions

The visual-kit design spec AR-8 forbids string-concatenated HTML. B1 introduces exactly two scoped escape hatches, each tracked here with its invariant:

| Helper | Used in | Input provenance | Invariant |
|---|---|---|---|
| `unsafeHTML(highlightToHtml(lang, source))` | `lesson.ts` `code` case | `source` is author-supplied LLM output | Prism's `Prism.util.encode` HTML-escapes `&<>"` before tokenization; grammar emits only known-safe `<span class="token ...">` markup. Input size is capped at 100 KB (ReDoS guard). Unknown languages take the escape-only fallback. Tested via `escape.test.ts` with adversarial payloads including `</script>`, `<!--`, `<img onerror>`. |
| `unsafeJSON(config)` | `lesson.ts` `chart` / `quiz` cases | `config` is author-supplied structured JSON | Emitted inside `<script type="application/json">` — parsed as JSON at runtime, never executed as JS. Helper escapes `<`, `>`, `&`, `\u2028`, `\u2029` to `\u00XX` form (prevents `</script>` tag-break, HTML comment state transitions, and line-terminator JS parse hazards). Tested via `escape.test.ts` against all the same payloads plus the Unicode line terminators. |

No other `unsafeHTML` / `unsafeJSON` / string-concat HTML is permitted in B1. The `scripts/lint-pure-components.mjs` gate is extended to grep-ban `unsafeHTML(` outside `lesson.ts` and grep-ban `new Function(` / `eval(` anywhere under `plugins/visual-kit/src/`.

### 3.3 `<vk-code>` upgrade

**Strategy: server-side highlighting.** `lesson.ts` calls a new `highlightToHtml(language, source)` helper at render time. The result is pre-tokenized HTML (`<span class="token ...">...`) that gets slotted into `<vk-code>`:

```ts
case 'code': {
  const tokens = highlightToHtml(String(s.language ?? 'text'), String(s.source ?? ''));
  return html`<vk-section data-variant="code">
    <h2 slot="title">Example</h2>
    <vk-code language="${String(s.language ?? 'text')}">
      ${unsafeHTML(tokens)}
    </vk-code>
  </vk-section>`;
}
```

`unsafeHTML` from `lit/directives/unsafe-html.js` is acceptable here because `highlightToHtml` produces known-safe output: Prism's tokenizer HTML-escapes all source content before wrapping in `<span>` class markers. The helper also HTML-escapes input as its first step for defense in depth.

**Component shell** (unchanged pattern, CSS upgraded):

```ts
// src/components/code.ts
@customElement('vk-code')
export class VkCode extends LitElement {
  static styles = [
    css`
      :host { display: block; position: relative; }
      pre { background: var(--vk-code-bg); padding: 1rem; border-radius: 4px;
            overflow-x: auto; margin: 0; font-family: 'SF Mono', Consolas, monospace;
            font-size: 0.85rem; line-height: 1.5; }
      button { position: absolute; top: 0.5rem; right: 0.5rem; ... }
    `,
    prismThemeCss,  // Prism token classes; imported at build time
  ];
  @property() language = 'text';
  private async copy() { /* ... */ }
  render() {
    return html`
      <pre><code class="language-${this.language}"><slot></slot></code></pre>
      <button @click=${this.copy}>copy</button>`;
  }
}
```

**Prism theme.** Single CSS-variables theme authored against `theme.css`'s existing token palette (`--vk-text`, `--vk-accent`, `--vk-muted`, etc.). Rather than ship two Prism themes keyed off `prefers-color-scheme`, one theme with variable-driven colors inherits dark/light automatically from the page theme. This is consistent with QR-6 / RR-1 (single source of truth for color) and avoids ~1 KB of duplicated CSS. ~1 KB gz total.

**Helper** `src/render/highlight.ts`:

```ts
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

const KNOWN = new Set(['javascript','typescript','python','css','html','json','bash','markdown','sql']);
const MAX_INPUT_BYTES = 100_000;  // ReDoS guard against pathological Prism grammar input

function escapeHtml(s: string): string {
  return s.replace(/[&<>]/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;' })[c]!);
}

export function highlightToHtml(language: string, source: string): string {
  // Input cap — some Prism grammars (notably Markdown, Markup) have historically
  // exhibited ReDoS with crafted input. Any source over the cap is escape-only.
  if (source.length > MAX_INPUT_BYTES) return escapeHtml(source);
  const lang = KNOWN.has(language) ? language : null;
  if (lang === null) return escapeHtml(source);
  const grammar = Prism.languages[lang === 'html' ? 'markup' : lang]!;
  return Prism.highlight(source, grammar, lang);
}
```

### 3.4 `<vk-math>` (port + proper bundle)

Port source: `plugins/visual-kit/reference/edu-components/edu-math.js`. Port deltas per the `reference/README.md` delta list.

**Final shape** (`src/components/math.ts`, included in `math.js` bundle):

```ts
import { LitElement, html, css, unsafeCSS } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import katex from 'katex';
import katexCss from 'katex/dist/katex.css';

@customElement('vk-math')
export class VkMath extends LitElement {
  static styles = [
    unsafeCSS(katexCss),
    css`
      :host { display: block; margin: 0.5rem 0; font-size: 1.05rem; }
      .math-error { color: var(--vk-warning, #d29922); font-family: monospace; font-size: 0.85rem; }
    `,
  ];
  @property({ type: Boolean }) display = false;
  render() {
    const latex = this.textContent?.trim() ?? '';
    if (!latex) return html``;
    try {
      // Security-critical options — see notes below. Every flag here is
      // load-bearing: changing any of them without review expands attack surface.
      const rendered = katex.renderToString(latex, {
        displayMode: this.display,
        throwOnError: false,
        output: 'html',
        trust: false,           // blocks \href, \url, \htmlClass, \htmlId, \htmlData
        strict: 'warn',         // warn on non-standard commands; don't silently permit
        maxSize: 10,            // cap rendered-element size multiplier
        maxExpand: 1000,        // cap macro-expansion depth (DoS guard)
      });
      return html`<div .innerHTML=${rendered}></div>`;
    } catch (err) {
      return html`<div class="math-error">KaTeX error: ${err instanceof Error ? err.message : String(err)}</div>`;
    }
  }
}
```

**CSS inlining.** Esbuild is configured with `loader: { '.css': 'text' }` so `import katexCss from 'katex/dist/katex.css'` yields the CSS as a string, wrapped with Lit's `unsafeCSS`. The same mechanism applies to the Prism theme import in `core.js`.

**KaTeX fonts.** `katex/dist/katex.css` references ~20 font files via `@font-face`. Under strict `font-src 'self' data:` (already set in Plan A), they must be self-served or data-URL-embedded. Options:
1. Pre-process the CSS at build time to rewrite `url(./fonts/*.woff2)` to base64 data URLs — adds ~80 KB to `math.js` bundle (acceptable for lazy-loaded math bundle)
2. Copy `katex/dist/fonts/*.woff2` into `dist/static/fonts/` and serve at `/vk/static/fonts/*.woff2` — smaller bundle, new server route, needs CSS URL rewrite to absolute `/vk/static/fonts/...`

**Decision:** Option 1 (data URL embed). Keeps `math.js` self-contained; no static route work. Simple build step: `scripts/build.mjs` reads `katex.css`, walks `url(./fonts/*.woff2)` patterns, replaces with data URLs from the sibling font files, passes the result as the CSS string to the esbuild text loader.

**KaTeX version pinning.** `katex` is pinned to an exact version in `package.json` (not `^`), and added to the `npm audit --audit-level=high` CI gate. The version bump workflow requires running the `tests/security/katex-xss.test.ts` fixture before merging.

Schema for `math` section (additive):

```json
{ "type": "math", "latex": "a^2+b^2=c^2", "display": true }
```

`lesson.ts`:
```ts
case 'math':
  return html`<vk-section data-variant="math">
    <vk-math ?display=${s.display === true}>${String(s.latex ?? '')}</vk-math>
  </vk-section>`;
```

### 3.5 `<vk-chart>` (port + proper bundle)

Port source: `reference/edu-components/edu-chart.js`. Port deltas per the reference README.

**Config passes via sibling JSON script** (per spec AR-8 — never as an attribute):

```ts
import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';
import { Chart } from 'chart.js/auto';
import type { ChartConfiguration } from 'chart.js';

@customElement('vk-chart')
export class VkChart extends LitElement {
  static styles = css`
    :host { display: block; margin: 0.5rem 0; }
    .wrap { position: relative; width: 100%; max-width: 720px; }
    .error { color: var(--vk-warning, #d29922); font-family: monospace; font-size: 0.85rem; padding: 0.5rem; }
  `;
  @state() private error?: string;
  private chart?: Chart;
  firstUpdated() {
    const configScript = this.querySelector('script[type="application/json"]');
    if (!configScript?.textContent) {
      this.error = 'edu-chart: missing config script';
      return;
    }
    let config: ChartConfiguration;
    try {
      config = JSON.parse(configScript.textContent);
    } catch (err) {
      console.warn('vk-chart: config JSON parse failed', err);
      this.error = 'vk-chart: invalid config JSON';
      return;
    }
    // Reject function-coerced fields (defense in depth — schema also denies these).
    if (chartConfigContainsCallbackFields(config)) {
      this.error = 'vk-chart: config contains disallowed callback fields';
      return;
    }
    const canvas = this.renderRoot.querySelector('canvas');
    if (!canvas) return;
    try {
      this.chart = new Chart(canvas, config);
    } catch (err) {
      console.warn('vk-chart: Chart.js init failed', err);
      this.error = 'vk-chart: render failed';
    }
  }
  disconnectedCallback() {
    super.disconnectedCallback();
    this.chart?.destroy();
  }
  render() {
    if (this.error) return html`<div class="error">${this.error}</div>`;
    return html`<div class="wrap"><canvas></canvas></div><slot></slot>`;
  }
}
```

**Callback-field denylist.** Chart.js `options` accepts functions for several keys (`callback`, `onComplete`, `onClick`, `onHover`, `filter`, `sort`, `generateLabels`, `label`, etc.). JSON cannot carry functions, but the helper `chartConfigContainsCallbackFields` walks the config and rejects any of these keys whose value is a string (guards against a future feature accidentally `new Function`-coercing them). The schema also denies these via `not` clauses — two-layer defense.

Schema for `chart` section (tightened from the current `config: object`):

```json
{
  "type": "chart",
  "config": {
    "type": "bar",
    "data": { "labels": [...], "datasets": [...] },
    "options": { ... }
  }
}
```

`lesson.ts`:
```ts
case 'chart':
  return html`<vk-section data-variant="chart">
    <vk-chart>
      <script type="application/json">${unsafeJSON(s.config)}</script>
    </vk-chart>
  </vk-section>`;
```

Where `unsafeJSON` is defined in `src/render/escape.ts`:

```ts
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
```

Primary XSS guard is the `type="application/json"` attribute + page-level CSP. `unsafeJSON` is defense in depth.

**Chart.js theming.** Chart.js canvas defaults follow its built-in palette. Dark/light adaptation is out of scope for B1 — future work if demand surfaces. No `Chart.defaults` mutation in `chart.js` bundle; keeps the bundle side-effect-free on import.

### 3.6 `<vk-quiz>` (new)

Behavioral reference: the inline quiz JS in paidagogos's pre-visual-kit `lesson.html`. Re-implemented as a Lit component.

```ts
interface QuizItem {
  type: 'multiple_choice' | 'fill_blank' | 'explain';
  question: string;
  options?: string[];
  answer: string;
  explanation: string;
}

@customElement('vk-quiz')
export class VkQuiz extends LitElement {
  @state() private items: QuizItem[] = [];
  @state() private answered: Record<number, { chosen: string; correct: boolean }> = {};
  @state() private parseError = false;

  firstUpdated() {
    const json = this.querySelector('script[type="application/json"]')?.textContent;
    if (!json) { this.parseError = true; return; }
    try {
      const parsed = JSON.parse(json) as { items: QuizItem[] };
      if (!Array.isArray(parsed.items) || parsed.items.length === 0) {
        this.parseError = true; return;
      }
      this.items = parsed.items;
    } catch (err) {
      console.warn('vk-quiz: config JSON parse failed', err);
      this.parseError = true;
    }
  }

  private emit(index: number, item: QuizItem, chosen: string, correct: boolean) {
    // Cap chosen length at 1 KB — bounds event-log growth and matches server-side event-schema rule.
    const cappedChosen = chosen.length > 1024 ? chosen.slice(0, 1024) : chosen;
    this.answered = { ...this.answered, [index]: { chosen: cappedChosen, correct } };
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true, composed: true,
      detail: {
        type: 'quiz_answer',
        index,
        item_type: item.type,
        chosen: cappedChosen,
        correct,
        ts: new Date().toISOString(),
      },
    }));
  }

  render() {
    if (this.parseError) {
      return html`<vk-error><p slot="detail">vk-quiz: no valid items in config.</p></vk-error>`;
    }
    // Per-item render: type-discriminated switch → renderMultipleChoice / renderFillBlank / renderExplain.
    // Each per-item handler calls this.emit() on user interaction. The `explain` type is self-grading
    // (the user submits free text; the component reveals the reference answer and marks correct=true
    // to record participation; no automated comparison in B1).
    // Implementation detail lives in the plan, not the spec.
  }
}
```

**Failure mode.** Malformed `<script type="application/json">` content (parse error, non-array items, empty array) renders as `<vk-error>` in the quiz slot with a diagnostic message. This mirrors how `<vk-chart>` handles bad config — **silent failure is explicitly rejected**; a visible `<vk-error>` is the contract. Paidagogos's V2 verification uncovered that silent renderer failures are the single largest class of bugs to catch at the component boundary.

**Schema formalization** — `lesson.v1.json` `quiz` section gains a `oneOf` over item types:

```json
{
  "type": "object",
  "properties": {
    "type": { "const": "quiz" },
    "items": {
      "type": "array",
      "minItems": 1,
      "maxItems": 20,
      "items": {
        "oneOf": [
          { "properties": { "type": { "const": "multiple_choice" }, "question": { "type": "string" }, "options": { "type": "array", "items": { "type": "string" }, "minItems": 2, "maxItems": 6 }, "answer": { "type": "string" }, "explanation": { "type": "string" } }, "required": ["question", "options", "answer", "explanation"] },
          { "properties": { "type": { "const": "fill_blank"      }, "question": { "type": "string" }, "answer": { "type": "string" }, "explanation": { "type": "string" } }, "required": ["question", "answer", "explanation"] },
          { "properties": { "type": { "const": "explain"         }, "question": { "type": "string" }, "answer": { "type": "string" }, "explanation": { "type": "string" } }, "required": ["question", "answer", "explanation"] }
        ]
      }
    }
  },
  "required": ["type", "items"]
}
```

`lesson.ts`:
```ts
case 'quiz':
  return html`<vk-section data-variant="quiz">
    <h2 slot="title">Check yourself</h2>
    <vk-quiz>
      <script type="application/json">${unsafeJSON({ items: s.items })}</script>
    </vk-quiz>
  </vk-section>`;
```

### 3.7 Event flow (unchanged from spec §5.6)

`<vk-quiz>` emits `vk-event`. The page's existing event-dispatch script (already added by Plan A's `buildShell`) captures these, adds the CSRF token from `<meta name="vk-csrf">`, and POSTs to `/events`. Server appends to `.paidagogos/state/events`.

No server or shell changes needed for B1 — the existing event pipeline is fully reusable.

### 3.8 Schema summary

`plugins/visual-kit/schemas/surfaces/lesson.v1.json` updates:
- `code` section: no change (remains `{ type, language?, source }`)
- `chart` section: `config` tightened from `object` to `{ type: string, data: object, options?: object }`
- `math` section: adds `display?: boolean`
- `quiz` section: `items` goes from `array` to `array with per-item oneOf discriminator`

All changes are additive or tightening. A SurfaceSpec written against the Plan A schema remains valid (existing lessons ship without `display` and with loose chart config; the tighter chart schema accepts pre-existing content because Chart.js configs naturally have `type`/`data`).

Schema version stays at 1.

### 3.9 Security and CSP

No changes to CSP. All three new bundles are `'self'`-served and SRI-pinned. KaTeX fonts via data URLs pass `font-src 'self' data:` (already set in Plan A).

**AR-8 compliance.** Complex props pass via sibling `<script type="application/json">`, not attributes. The two scoped escape hatches (`unsafeHTML`, `unsafeJSON`) are inventoried in §3.2b with invariants; no other string-concat HTML anywhere.

**Pure components (RR-1/AR-7).** New components make zero `fetch`, read no `localStorage`, and access no document-level state outside their own DOM subtree. `scripts/lint-pure-components.mjs` passes.

**`free` surface allowlist (sanitize.ts).** The new components `<vk-math>`, `<vk-chart>`, `<vk-quiz>` are **intentionally NOT added** to `ALLOWED_TAGS` in `src/render/sanitize.ts`. Consequence: a `free` surface cannot embed any of them. Rationale: the three components rely on sibling `<script type="application/json">` for config; `free` surface content is HTML-only (script tags are stripped by DOMPurify). Without the config-script, the components render as `<vk-error>` anyway, so allowing the tags would be misleading. Consumers that need interactive charts/math/quiz must use the `lesson` surface's typed section types.

**Event schema extension.** `POST /events` in Plan A validates an event schema. B1 extends that schema with a `quiz_answer` event:

```json
{
  "oneOf": [
    /* existing event types */,
    {
      "type": "object",
      "properties": {
        "type":      { "const": "quiz_answer" },
        "index":     { "type": "integer", "minimum": 0, "maximum": 99 },
        "item_type": { "enum": ["multiple_choice", "fill_blank", "explain"] },
        "chosen":    { "type": "string", "maxLength": 1024 },
        "correct":   { "type": "boolean" },
        "ts":        { "type": "string", "format": "date-time" }
      },
      "required": ["type", "index", "item_type", "chosen", "correct", "ts"]
    }
  ]
}
```

`chosen` is capped at 1 KB server-side (matches the client-side cap in `<vk-quiz>.emit`). Events that exceed the cap are rejected with `413 Payload Too Large` (already part of Plan A's `SR-8` behavior).

**Supply-chain.** `prismjs`, `katex`, `chart.js` pinned to exact versions in `package.json` (no `^`, no `~`). CI runs `npm audit --audit-level=high` against these three. A grammar-level XSS fuzz suite (`tests/security/prism-xss.test.ts`, `tests/security/katex-xss.test.ts`, `tests/security/chart-callbacks.test.ts`) runs the adversarial payload matrix from §3.2b.

---

## 4. Testing

V2 regression work exposed a class of bugs — shadow-DOM CSS isolation, default-export assumptions, silent renderer failures — that can only surface in a real browser. The spec's test plan promotes those to automated coverage rather than leaving them to manual verification.

### 4.1 Unit (vitest, node / happy-dom)

Unit tests run under node + happy-dom. They are sufficient for pure logic and DOM-structure assertions but **cannot verify** shadow-DOM CSS cascade, real font loading, or canvas pixel output. Coverage:

- `escape.test.ts` — `unsafeJSON` neutralizes `</script>`, `<!--`, `-->`, `&`, `\u2028`, `\u2029`; round-trips arbitrary JSON; unicode content preserved; no double-escaping.
- `highlight.test.ts` — `highlightToHtml` tokenizes each registered language; unknown language escape-only; source over 100 KB escape-only; input `</script><img src=x onerror=alert(1)>` produces output with no raw `<`/`>`.
- `math.test.ts` — `<vk-math>` emits KaTeX span tree in light DOM (via `renderRoot`); `display` attribute flips `displayMode`; invalid LaTeX triggers `.math-error`; `\href{javascript:alert(1)}{x}` does NOT produce a `javascript:` href (KaTeX `trust: false`).
- `chart.test.ts` — `<vk-chart>` creates a `Chart` instance in happy-dom (jsdom canvas 2D is stubbed but instance construction is verifiable); absent script tag renders `<vk-error>`; malformed JSON renders `<vk-error>`; config containing `options.plugins.tooltip.callbacks.label: "..."` (string callback) renders `<vk-error>`.
- `quiz.test.ts` — renders per-item UI for all three types; click/submit emits `vk-event` with correct detail shape and 1 KB `chosen` cap enforced; empty items and malformed JSON render `<vk-error>`.
- `autoload.test.ts` — tag-position regex matches `<vk-math>` and `<vk-math />` (self-closing) but NOT `<vk-math-like="bad">` or text content `"<vk-math>"` (escaped as `&lt;vk-math&gt;`); dedupe across multiple occurrences; core-tag filtering; unknown tag throws.

### 4.2 Integration (vitest, real HTTP roundtrip)

New fixtures at `tests/integration/fixtures/*.json` and tests:

- `lesson-code.test.ts` — code-section SurfaceSpec → GET rendered page → assert `<vk-code>` with tokenized slot content, core bundle preload only, CSP header intact.
- `lesson-math.test.ts` — math section → `<vk-math>` present, `math.js` in preload with SRI.
- `lesson-chart.test.ts` — chart section → `<vk-chart>` present, sibling JSON parses, `chart.js` preloaded.
- `lesson-quiz.test.ts` — quiz section → `<vk-quiz>` present, JSON round-trips with `unsafeJSON` applied, `quiz.js` preloaded.
- `lesson-multi.test.ts` — dedup integration: lesson with two `math` sections AND one `chart` AND one `quiz` preloads each bundle exactly once.
- `malformed-chart.test.ts` — chart section with garbled JSON → page renders, fragment contains `<vk-error>` under the chart's section slot.
- `schema-regression.test.ts` — a Plan A lesson fixture (no math/chart/quiz sections, loose schema) validates cleanly against the 1.1 schema.
- `event-quiz.test.ts` — end-to-end: simulate a quiz answer POST with CSRF token, assert `.test-workspace/.test-plugin/state/events` contains a valid `quiz_answer` entry with all fields.

### 4.3 Browser regression (Playwright, real Chromium)

New directory `tests/browser/regression.test.ts` runs in a real Chromium under Playwright (or the project's Chrome DevTools MCP harness if preferred — same assertion shape). These are the V2-regression-class bugs promoted from manual checklist to automated gates:

- `katex-renders-styled.spec` — load a math-only lesson, wait for `<vk-math>` to render, assert `.katex .base` computed `font-family` starts with `KaTeX_Main` (proves shadow-DOM CSS cascade reaches KaTeX output).
- `katex-fonts-load.spec` — after `document.fonts.ready`, assert at least one KaTeX font family is in `document.fonts` (proves data-URL `@font-face` actually loaded).
- `chart-renders-pixels.spec` — load a chart lesson, wait for `firstUpdated` → assert canvas has non-empty pixel samples at expected bar positions (proves Chart.js actually drew, not just instantiated).
- `prism-tokens-visible.spec` — load a code lesson, assert `<span class="token keyword">` inside `<vk-code>` and computed color differs from the surrounding text color (proves Prism theme CSS is in effect).
- `sri-modulepreload.spec` — assert `<link rel="modulepreload" integrity="sha384-...">` tags resolve (no `net::ERR_BLOCKED_BY_CSP`, `integrity` attribute matches).
- `quiz-a11y.spec` — assert `<vk-quiz>` multiple-choice options are keyboard-navigable (Tab / arrow-key focus), options have `role="radio"` or equivalent semantics, focus is visible, tap targets ≥ 24×24 px, WCAG AA contrast met (QR-3).
- `csp-no-inline-script.spec` — load any lesson, inject `<script>alert(1)</script>` via DevTools and confirm CSP blocks it.

### 4.4 Schema validation (ajv)

Covered inline in `validate.test.ts` (existing file extended) — specific cases:
- Chart config missing `type` fails
- Chart config containing a string-typed `options.plugins.tooltip.callbacks.label` fails (denylist)
- Quiz item with unknown `type` fails
- Quiz item missing `answer` fails
- Math without `latex` fails
- A Plan A lesson JSON (checked in as fixture) passes the 1.1 schema
- Items within the lesson `sections` beyond 40 fail `maxItems`

### 4.5 Gherkin acceptance

Appended scenarios to existing `docs/plugins/visual-kit/specs/surface-rendering.feature`:
- Scenario: `lesson surface renders code with Prism syntax highlighting`
- Scenario: `lesson surface renders math via <vk-math> with math.js preloaded`
- Scenario: `lesson surface renders chart via <vk-chart> with chart.js preloaded`
- Scenario: `lesson surface renders quiz via <vk-quiz> with quiz.js preloaded`
- Scenario: `autoloader deduplicates repeated section bundles`
- Scenario: `malformed section config renders visible <vk-error>`
- Scenario: `quiz answer event is persisted to the plugin's events log`

### 4.6 CI gates

| Gate | Threshold | Policy |
|------|-----------|--------|
| Bundle size: `core.js` | ≤ 40 KB gz (production minified + gzipped) | Fail hard |
| Bundle size: `quiz.js` | ≤ 10 KB gz | Fail hard |
| Bundle size: `chart.js` | Measured at build + 10% headroom | Fail hard |
| Bundle size: `math.js` | Measured at build + 10% headroom | Fail hard |
| Pure-component lint | zero violations | Fail hard |
| `unsafeHTML`/`unsafeJSON` grep-ban outside `lesson.ts` + `escape.ts` | zero violations | Fail hard |
| `new Function(` / `eval(` grep-ban under `plugins/visual-kit/src/` | zero violations | Fail hard |
| `npm audit --audit-level=high` for pinned deps | zero advisories | Fail hard |
| Capabilities endpoint integration test | all bundles listed with SRI | Fail hard |
| First-paint latency (Playwright trace, median of 5 runs) | ≤ 500 ms (QR-4) | Warn, not fail |

**Bundle size methodology.** Measured on the minified, gzipped output in `dist/`. The `chart.js` and `math.js` gates are set empirically at build time (first green build + 10% headroom) rather than pre-specified — this avoids the "relax the gate when the bundle grows" anti-pattern the security reviewer flagged. If a bundle exceeds its established gate, the project decides between splitting the bundle or revisiting the feature — never silently raise the threshold.

---

## 5. File structure

### New files

```
plugins/visual-kit/
├── src/
│   ├── components/
│   │   ├── chart.ts                   ← new — build entry for chart.js bundle
│   │   ├── math.ts                    ← new — build entry for math.js bundle
│   │   └── quiz.ts                    ← new — build entry for quiz.js bundle
│   └── render/
│       ├── highlight.ts               ← new (server-side Prism)
│       └── autoload.ts                ← new (fragment-scanning autoloader)
├── schemas/surfaces/
│   └── lesson.v1.json                 ← updated (additive + tighter quiz/chart)
├── tests/
│   ├── unit/
│   │   ├── code.test.ts               ← new (extends existing code coverage)
│   │   ├── math.test.ts               ← new
│   │   ├── chart.test.ts              ← new
│   │   ├── quiz.test.ts               ← new
│   │   └── autoload.test.ts           ← new
│   └── integration/
│       ├── lesson-code.test.ts        ← new
│       ├── lesson-math.test.ts        ← new
│       ├── lesson-chart.test.ts       ← new
│       ├── lesson-quiz.test.ts        ← new
│       └── lesson-multi.test.ts       ← new
```

### Modified files

```
plugins/visual-kit/
├── src/
│   ├── components/
│   │   ├── code.ts                    ← Prism theme CSS imported into styles
│   │   └── index.ts                   ← barrel unchanged (code only)
│   ├── server/
│   │   ├── capabilities.ts            ← add math/chart/quiz bundles with SRI
│   │   └── index.ts                   ← replace hardcoded [coreBundle] with discoverRequiredBundles + resolveBundleRefs
│   └── surfaces/
│       └── lesson.ts                  ← implement code/chart/math/quiz section cases
├── scripts/
│   └── build.mjs                      ← add entries for chart/math/quiz bundles
├── package.json                       ← add prismjs, chart.js, katex deps
├── CHANGELOG.md                       ← 1.1.0 entry
└── .claude-plugin/
    └── plugin.json                    ← version bump to 1.1.0
```

### Paidagogos-side

```
plugins/paidagogos/
└── .claude-plugin/plugin.json         ← dependency bump: visual-kit ~1.0.0 → ~1.1.0
```

---

## 6. Rollout

1. Branch `feat/visual-kit-v1.1-plan-b1` off main.
2. Implement per the plan (Plan B1 task breakdown — separate document).
3. All automated tests pass: unit, integration, browser regression (§4.3), schema, bundle size, pure-component lint, `npm audit`, grep-bans.
4. Gherkin scenarios (§4.5) added to `docs/plugins/visual-kit/specs/surface-rendering.feature` and run via the existing feature harness.
5. Manual spot-check on one real paidagogos lesson in the dev browser — optional, since the browser regression suite covers the automated surface. Exists as a final eyeball step, not as coverage.
6. Tag `visual-kit--v1.1.0` in the marketplace.
7. Bump paidagogos dependency to `~1.1.0`. Commit + PR.
8. Once merged, the `code` and `quiz` rendering regressions disappear from generated paidagogos lessons. `math` and `chart` components stand ready for a future `paidagogos:micro` update that starts emitting those section types.

Forward compatibility: a consumer pinned to `~1.0.0` that receives a `1.1.0` install still works — schema is additive.

---

## 7. Deferred

- **Editable code (CodeMirror 6)** — B3. Adds `code.editable?: boolean` to schema, needs `@codemirror/state` import-map or bundled dep; client-side JS path diverges from B1's server-side highlighting path.
- **`<vk-geometry>` / `<vk-sim-2d>` ports** — future plan on demand. Reference components remain in `plugins/visual-kit/reference/edu-components/` until then.
- **`<vk-progress>` / `<vk-streak>`** — needs `.paidagogos/prefs.json` schema design; separate spec.
- **`<vk-hint>` / standalone `<vk-explain>`** — new pedagogy UX, not regression fixes.
- **`<vk-audio>`** — no consumer demand.

---

## 8. Open questions

Decisions deferred to real measurement during implementation:

1. **Chart.js tree-shaking.** `chart.js/auto` is the starting position. If the measured `chart.js` bundle size comes in above ~90 KB gz, switch to explicit controller registration (`bar`, `line`, `scatter`, `pie` only). Decision waits on the first green build.
2. **KaTeX math.js bundle size.** The data-URL font embed is expected to push `math.js` to ~180–220 KB gz. If it's above ~250 KB gz, reconsider Option 2 from §3.4 (static fonts route). Again — gate set empirically at first green build + 10% headroom per §4.6.

---

## 9. References

- Visual-kit design spec: `docs/superpowers/specs/2026-04-17-visual-kit-design.md`
- Visual-kit ADR: `docs/plugins/visual-kit/DECISIONS.md` (D-01 through D-06)
- Reference components: `plugins/visual-kit/reference/edu-components/`
- Reference fixtures: `plugins/visual-kit/reference/fixtures/`
- Prior art (closed): PR #8 — paidagogos in-house V2 renderers, superseded by visual-kit
