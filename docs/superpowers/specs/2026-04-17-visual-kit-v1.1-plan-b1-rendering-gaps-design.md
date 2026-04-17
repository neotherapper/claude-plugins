# Visual-Kit v1.1 — Plan B1: Rendering Gaps

**Date:** 2026-04-17
**Status:** Approved
**Scope:** Fix all "not yet supported" section renderers in the current visual-kit `lesson` surface. Ship `<vk-math>`, `<vk-chart>`, `<vk-quiz>` as new bundles; upgrade `<vk-code>` with server-side syntax highlighting.

---

## 1. Context

Visual-kit `1.0.0` (Plan A) shipped the server, six SurfaceSpec types, and the core component bundle covering layout primitives (`<vk-section>`, `<vk-card>`, `<vk-gallery>`, `<vk-outline>`, `<vk-comparison>`, `<vk-feedback>`, `<vk-loader>`, `<vk-error>`, minimal `<vk-code>`). Paidagogos migrated away from its in-house server and now depends on visual-kit for all rendering.

Four section types that `paidagogos:micro` emits today — `code` (present but no syntax highlighting), `chart`, `math`, `quiz` — currently hit this branch in `src/surfaces/lesson.ts`:

```ts
default: return html`<vk-section data-variant="${s.type}">
  <p>Section type "${s.type}" not yet supported in the core bundle. Install Plan B for code, math, chart, quiz renderers.</p>
</vk-section>`;
```

This is a visible regression from paidagogos's pre-migration V1 behavior. Plan B1 closes the gap.

**Roadmap position.** Plan B total (per ADR D-06) has three phases:
- **B1 (this spec):** rendering gaps — code, chart, math, quiz
- **B2 (later):** new consumer migrations — namesmith gallery, draftloom comparison
- **B3 (later, on demand):** geometry, sim-2d, pedagogy (progress/streak/hint), editable code via CodeMirror 6

Plan C (heavy bundles: Three.js, Pyodide, Sandpack) remains deferred to concrete consumer demand.

---

## 2. Goals

- **G-1** After B1, every `sections[].type` that `paidagogos:micro` generates renders fully. No `vk-error` fallback, no "not yet supported" placeholder.
- **G-2** Ship three new component bundles — `math.js`, `chart.js`, `quiz.js` — served at `/vk/<bundle>.js` with SRI.
- **G-3** Upgrade `<vk-code>` to display syntax-highlighted source via server-side Prism. The component itself stays in `core.js` with no added runtime JS; only Prism theme CSS ships in the bundle.
- **G-4** Implement the fragment-scanning autoloader that visual-kit §5.5 describes but Plan A deferred. Lessons that use only some section types load only the bundles they need.
- **G-5** Maintain additive schema compatibility. No breaking changes. `GET /vk/capabilities` gains three bundle entries.
- **G-6** Paidagogos continues to work without a single skill change. Bumping the `visual-kit` dependency from `~1.0.0` to `~1.1.0` is the only consumer-side edit.

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

export function discoverRequiredBundles(fragmentHtml: string): string[] {
  // Scan the rendered HTML for <vk-*> opening tags.
  // Deduplicate. Look up non-core mappings. Return bundle names (without 'core').
  const tags = new Set<string>();
  for (const match of fragmentHtml.matchAll(/<(vk-[a-z0-9-]+)\b/g)) {
    tags.add(match[1]!);
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

**Regex rationale.** Rendered fragments are lit-html SSR output — well-formed HTML with known escape semantics. A regex over `<vk-[a-z0-9-]+\b` is sufficient. We do not match closing tags or text content. A tag that appears only inside a comment or text string would not reach this point (lit-html escapes text); but if it did, the worst outcome is a bundle loads unnecessarily — no correctness or security impact.

**Tag map grows additively.** Adding a future component (`<vk-geometry>` in B3) = one line in `TAG_TO_BUNDLE`.

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

**Prism theme.** Two themes are bundled — a dark variant (`prism-tomorrow`) and a light variant (`prism-solarized-light`), each ~1 KB gz. They key off `@media (prefers-color-scheme)`. Alternative (pick during implementation): single theme that uses CSS variables from `theme.css`.

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

export function highlightToHtml(language: string, source: string): string {
  const lang = KNOWN.has(language) ? language : null;
  if (lang === null) {
    // Graceful fallback: HTML-escape and wrap plain
    return source.replace(/[&<>]/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;' })[c]!);
  }
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
      const rendered = katex.renderToString(latex, {
        displayMode: this.display,
        throwOnError: false,
        output: 'html',
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
  `;
  private chart?: Chart;
  firstUpdated() {
    const configScript = this.querySelector('script[type="application/json"]');
    if (!configScript?.textContent) return;
    let config: ChartConfiguration;
    try { config = JSON.parse(configScript.textContent); } catch { return; }
    const canvas = this.renderRoot.querySelector('canvas');
    if (canvas) this.chart = new Chart(canvas, config);
  }
  disconnectedCallback() {
    super.disconnectedCallback();
    this.chart?.destroy();
  }
  render() {
    return html`<div class="wrap"><canvas></canvas></div><slot></slot>`;
  }
}
```

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

Where `unsafeJSON` is a small helper: `JSON.stringify(v).replace(/</g, '\\u003c')` — the replacement prevents any `</script>` sequence in serialized chart config from terminating the script tag early. The content is interpreted as JSON at runtime, not as JS, so XSS via this path is already prevented by the `type="application/json"` attribute and the CSP.

**Dark-mode color defaults.** Chart.js defaults text/grid to near-black. The `chart.js` bundle runs this once on import:

```ts
if (matchMedia('(prefers-color-scheme: dark)').matches) {
  Chart.defaults.color = '#c9d1d9';
  Chart.defaults.borderColor = 'rgba(201, 209, 217, 0.15)';
}
```

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

  firstUpdated() {
    const json = this.querySelector('script[type="application/json"]')?.textContent;
    if (!json) return;
    try {
      const parsed = JSON.parse(json) as { items: QuizItem[] };
      this.items = Array.isArray(parsed.items) ? parsed.items : [];
    } catch { this.items = []; }
  }

  private emit(index: number, item: QuizItem, chosen: string, correct: boolean) {
    this.answered = { ...this.answered, [index]: { chosen, correct } };
    this.dispatchEvent(new CustomEvent('vk-event', {
      bubbles: true, composed: true,
      detail: {
        type: 'quiz_answer',
        index,
        item_type: item.type,
        chosen,
        correct,
        ts: new Date().toISOString(),
      },
    }));
  }

  // Per-item render methods: renderMultipleChoice, renderFillBlank, renderExplain
  // Each calls emit() on user interaction; explain always marks correct=true (self-grading)
  // ...
}
```

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

**AR-8 compliance.** All three new components pass complex props via sibling `<script type="application/json">`, not attributes. No string-concatenated HTML anywhere. `unsafeHTML` is used only for server-side Prism output, whose escape semantics are known and tested.

**Pure components (RR-1/AR-7).** The new components make zero `fetch`, read no `localStorage`, and access no document-level state outside their own DOM subtree. `scripts/lint-pure-components.mjs` passes.

---

## 4. Testing

### 4.1 Unit (vitest)

One test file per new component plus the code upgrade, under `tests/unit/`:

- `code.test.ts` — cover `highlightToHtml` (known languages tokenize; unknown language escapes; unicode preserved). Cover `<vk-code>` DOM (language prop propagates to `<code class>`, slot content appears, copy button present).
- `math.test.ts` — `<vk-math>` renders KaTeX span tree for valid LaTeX; `display` attribute flips `displayMode`; invalid LaTeX triggers `.math-error`.
- `chart.test.ts` — `<vk-chart>` creates a Chart instance with parsed config; absent script tag is a no-op; malformed JSON is a no-op; dark-mode color default runs once.
- `quiz.test.ts` — renders per-item UI for all three types; click/submit emits `vk-event` with correct detail shape; renders empty on malformed JSON.
- `autoload.test.ts` — `discoverRequiredBundles` finds tags, dedupes, ignores core tags; `resolveBundleRefs` prepends core and appends in order.

### 4.2 Integration

Under `tests/integration/`, new fixtures and tests:

- `lesson-code.test.ts` — write a code-section SurfaceSpec, GET the rendered page, assert `<vk-code>` element present, `<span class="token ...">` in the slotted HTML, core bundle preload only (no math/chart/quiz).
- `lesson-math.test.ts` — math section → rendered page includes `<vk-math>`, bundle preload includes `math.js` (with SRI attr).
- `lesson-chart.test.ts` — chart section → rendered page includes `<vk-chart>`, the sibling `<script type="application/json">` parses to the original config, bundle preload includes `chart.js`.
- `lesson-quiz.test.ts` — quiz section → rendered page includes `<vk-quiz>`, sibling script JSON round-trips, bundle preload includes `quiz.js`.
- `lesson-multi.test.ts` — SurfaceSpec containing code+math+chart+quiz sections → rendered page preloads all four bundles (core, math, chart, quiz — no duplicates), each with its SRI hash.

### 4.3 Schema validation

Existing `tests/unit/validate.test.ts` (if present; else new) — cover the tightened schemas:
- Chart config missing `type` fails validation
- Quiz item with unknown `type` fails validation
- Quiz item with missing `answer` fails validation
- Math without `latex` fails validation
- Pre-B1 chart config (minimal `type`, `data`) still passes

### 4.4 CI gates

- Bundle size gate extended: `chart.js ≤ 90 KB gz`, `math.js ≤ 150 KB gz`, `quiz.js ≤ 10 KB gz`, `core.js` gate unchanged at `≤ 40 KB gz`
- Pure-component lint passes for all new component files
- Capabilities endpoint integration test asserts all four bundles listed with SRI

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
3. All tests pass (unit, integration, schema, bundle size, pure-components).
4. Manual browser verification via Chrome DevTools MCP using each fixture — takes the place of the missing automated visual regression harness. Explicitly verify the V2-bug regression list: modulepreload + SRI work under CSP; KaTeX fonts load from data URLs; Chart.js dark mode defaults apply; Prism tokens render correctly.
5. Tag `visual-kit--v1.1.0` in the marketplace.
6. Bump paidagogos dependency to `~1.1.0`. Commit + PR.
7. Once merged, "section type not yet supported" disappears from every paidagogos lesson.

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

All minor; decide during implementation:

1. **Prism theme strategy.** Two bundled themes keyed off `prefers-color-scheme`, or one theme using CSS custom properties from `theme.css`? Lean toward option 2 — smaller, theme-engine-consistent.
2. **KaTeX font delivery.** Data-URL embed (Option 1) vs `/vk/static/fonts/` route (Option 2). Data-URL keeps bundle self-contained — starting position.
3. **Chart.js tree-shaking.** `chart.js/auto` imports every controller. Plan A lessons only need `bar`, `line`, `scatter`, possibly `pie`. Consider explicit registration to cut bundle to ~35 KB gz — but only if the auto path pushes past the 90 KB gate.
4. **`unsafeJSON` helper location.** New file `src/render/escape.ts`? Or inline in `lesson.ts`? Lives at a natural home (escape utilities module).

---

## 9. References

- Visual-kit design spec: `docs/superpowers/specs/2026-04-17-visual-kit-design.md`
- Visual-kit ADR: `docs/plugins/visual-kit/DECISIONS.md` (D-01 through D-06)
- Reference components: `plugins/visual-kit/reference/edu-components/`
- Reference fixtures: `plugins/visual-kit/reference/fixtures/`
- Prior art (closed): PR #8 — paidagogos in-house V2 renderers, superseded by visual-kit
