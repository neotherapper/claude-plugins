# Paidagogos V2 — Core Renderer System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend paidagogos lessons with a modular renderer system so lessons can include interactive math, charts, geometry, live code, and physics simulations — not just static code blocks.

**Architecture:** Two-layer web component model: `<edu-[name]>` renderers (portable, subject-domain) and `<learn-[name]>` pedagogy components (plugin-scoped). Lesson JSON gains a `renderers[]` array. `lesson.html` reads this array and lazy-imports only the needed components via ES modules from CDN. Lit 3 is the web component framework (5 KB, no build step). Web Awesome provides UI chrome via its CDN autoloader.

**Tech Stack:**
- Lit 3.x (web components, CDN ESM)
- KaTeX (math), CodeMirror 6 (code), Chart.js (charts), JSXGraph (geometry), Matter.js (2D physics)
- Web Awesome 3.x (UI chrome via CDN loader)
- Existing: Node.js HTTP server, SSE auto-reload, Prism.js (kept as fallback)
- Browser testing via Chrome DevTools MCP

**Naming reminders:**
- Plugin directory: `plugins/paidagogos/`
- Skills: `paidagogos`, `paidagogos:micro`
- Component prefix `<edu-[name]>` is for portable renderers; `<learn-[name]>` is for pedagogy (used in later plans)

---

## File Structure

### Modified files
```
plugins/paidagogos/server/templates/lesson.html
plugins/paidagogos/server/server.js
plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md
plugins/paidagogos/skills/paidagogos-micro/SKILL.md
plugins/paidagogos/CHANGELOG.md
docs/superpowers/specs/2026-04-15-learn-v2-design.md
docs/plugins/learn/DECISIONS.md
```

### New files
```
plugins/paidagogos/server/components/renderers/edu-math.js
plugins/paidagogos/server/components/renderers/edu-code.js
plugins/paidagogos/server/components/renderers/edu-chart.js
plugins/paidagogos/server/components/renderers/edu-geometry.js
plugins/paidagogos/server/components/renderers/edu-sim-2d.js
plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md
plugins/paidagogos/server/test-fixtures/math-lesson.json
plugins/paidagogos/server/test-fixtures/code-lesson.json
plugins/paidagogos/server/test-fixtures/chart-lesson.json
plugins/paidagogos/server/test-fixtures/geometry-lesson.json
plugins/paidagogos/server/test-fixtures/sim-2d-lesson.json
```

### File responsibilities
- `lesson.html`: Shell template. Reads `renderers[]` from embedded JSON, dynamically imports `<edu-[name]>` modules, bootstraps Lit, mounts Web Awesome loader.
- `server.js`: Additionally serves `/components/**` as static ES modules.
- `lesson-schema.md`: Adds `renderers[]` and extends `example` to support renderer-driven config.
- `paidagogos-micro/SKILL.md`: Gains a classification step — read `renderer-map.md`, populate `renderers[]`.
- `renderer-map.md`: Lookup table from topic keywords to renderer keys.
- Component files: One per renderer. Each is a self-contained Lit element that CDN-imports its library.
- Test fixtures: Valid Lesson JSON files covering each renderer for manual browser verification.

---

## Task 0: Patch spec paths (consistency fix)

**Files:**
- Modify: `docs/superpowers/specs/2026-04-15-learn-v2-design.md`

- [ ] **Step 1: Replace `plugins/learn/` with `plugins/paidagogos/`**

Find every occurrence of `plugins/learn/` in the spec and replace with `plugins/paidagogos/`. Also rename any `learn-micro` skill directory references to `paidagogos-micro`. Skill name `learn:micro` should become `paidagogos:micro`; `learn:explain`, `learn:recall`, `learn:path` should become `paidagogos:explain`, `paidagogos:recall`, `paidagogos:path`. Pedagogy file paths `pedagogy/learn-*.js` stay as-is (the `learn-` prefix is the component namespace, not the plugin name).

Use Edit with `replace_all: true` for each distinct string.

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-04-15-learn-v2-design.md
git commit -m "docs(paidagogos): sync V2 spec paths after plugin rename"
```

---

## Task 1: Extend Lesson JSON schema with `renderers[]`

**Files:**
- Modify: `plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md`

- [ ] **Step 1: Update the TypeScript interface**

Replace the `Lesson` interface block in `lesson-schema.md` (lines 7–40) with:

```typescript
interface Lesson {
  topic: string;
  level: "beginner" | "intermediate" | "advanced";
  concept: string;
  why: string;

  renderers: RendererKey[];      // V2: required. [] if plain code/text only.

  example: {
    code?: string;
    prose?: string;
    language?: string;
    renderer?: RendererKey;      // V2: if set, use this edu-[name] for the example
    config?: Record<string, unknown>;  // V2: renderer-specific config object
  };
  common_mistakes: string[];
  generate_task: string;
  quiz: QuizQuestion[];
  resources: Resource[];
  next: string;
  estimated_minutes: number;
}

type RendererKey =
  | "math" | "code" | "chart" | "geometry" | "sim-2d";

interface QuizQuestion {
  type: "multiple_choice" | "fill_blank" | "explain";
  question: string;
  options?: string[];
  answer: string;
  explanation: string;
}

interface Resource {
  title: string;
  url: string;
  type: "docs" | "tutorial" | "video" | "interactive";
  source: "vault" | "ai-suggested";
}
```

- [ ] **Step 2: Add validation rule for `renderers[]`**

In the "## Rules" section, after the `estimated_minutes` rule, add:

```markdown
- `renderers` MUST always be present. Empty array `[]` is valid for lessons with no subject-domain rendering (e.g., pure text concepts).
- `renderers` values MUST come from the `RendererKey` union. `example.renderer` must also be listed in `renderers[]` (if set).
- V2 renderer keys: `math`, `code`, `chart`, `geometry`, `sim-2d`.
```

- [ ] **Step 3: Update the example at end of file**

In the Flexbox example JSON (around lines 53–106), add a `"renderers"` field after `"level"`:

```json
  "level": "beginner",
  "renderers": ["code"],
```

And update the `example` object to include `"renderer": "code"`:

```json
  "example": {
    "code": ".container {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n\n.item {\n  flex: 1;\n}",
    "language": "css",
    "renderer": "code"
  },
```

- [ ] **Step 4: Verify by reading the file**

Re-read the full file with Read and check: interface has `renderers: RendererKey[]`, rules section mentions V2 renderer keys, example JSON has `"renderers": ["code"]`.

- [ ] **Step 5: Commit**

```bash
git add plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md
git commit -m "feat(paidagogos): add renderers[] field to Lesson JSON schema"
```

---

## Task 2: Create `renderer-map.md` reference file

**Files:**
- Create: `plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md`

- [ ] **Step 1: Write the file**

Create `plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md`:

````markdown
# Renderer Map

Topic → renderer classification lookup for `paidagogos:micro`. Populates the `renderers[]` array in Lesson JSON.

## How to use

1. Classify the topic against the keyword table below.
2. Select all renderers whose keywords match.
3. If no match, default to `["code"]` for technical topics, `[]` for non-technical.
4. The `example.renderer` field must be one of the values in `renderers[]`.

## Keyword → Renderer table

| Renderer key | Trigger keywords (case-insensitive substring match) |
|--------------|---------------------------------------------------|
| `math`       | trigonometr, algebra, calculus, equation, derivative, integral, matrix, vector, fourier, probability, statist, exponent, logarithm, complex number |
| `code`       | (always included for programming languages, APIs, frameworks — JavaScript, TypeScript, Python, CSS, HTML, React, SQL, Git, shell, etc.) |
| `chart`      | histogram, distribution, time series, plot, graph (as in chart), correlation, regression, bar chart, line chart, scatter, data viz |
| `geometry`   | geometry, geometric, triangle, circle, polygon, angle, euclidean, coordinate, analytical geometry |
| `sim-2d`     | physics, gravity, collision, momentum, spring, pendulum, Newton, projectile, friction, kinetic |

## Mapping examples

| Topic | renderers[] | example.renderer |
|-------|-------------|------------------|
| CSS Flexbox | `["code"]` | `"code"` |
| Trigonometry basics | `["math", "geometry"]` | `"geometry"` |
| Fourier Series | `["math", "chart"]` | `"chart"` |
| Histograms in statistics | `["chart", "math"]` | `"chart"` |
| Newton's second law | `["sim-2d", "math"]` | `"sim-2d"` |
| Python list comprehensions | `["code"]` | `"code"` |
| The Pythagorean theorem | `["math", "geometry"]` | `"geometry"` |
| Projectile motion | `["sim-2d", "chart"]` | `"sim-2d"` |
| Binary search | `["code"]` | `"code"` |
| What is entropy (concept) | `[]` | _omit renderer_ |

## Defaults

- Topic mentions a programming language or CSS/HTML → always include `"code"`.
- Topic mentions mathematics → include `"math"` for display, add `"geometry"` or `"chart"` if visualisation applies.
- Topic is purely conceptual with no code/math/visual → `renderers: []` and `example.renderer` omitted.

## Out of scope for V2

These renderers are NOT yet available. If a topic would benefit from them, leave the lesson renderer-empty and note it in the concept text; do NOT hallucinate renderer keys:

- `python` (Pyodide) — V2.1
- `sandbox` (Sandpack) — V2.1
- `scene-3d` (Three.js) — V2.1
- `canvas` (p5.js) — V2.1
- `audio` (Tone.js) — V2.2
- `animate` (GSAP) — V2.2
````

- [ ] **Step 2: Commit**

```bash
git add plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md
git commit -m "feat(paidagogos): add renderer-map.md classification reference"
```

---

## Task 3: Extend `paidagogos:micro` SKILL.md with renderer classification step

**Files:**
- Modify: `plugins/paidagogos/skills/paidagogos-micro/SKILL.md`

- [ ] **Step 1: Read current SKILL.md to find the right insertion point**

```bash
Read plugins/paidagogos/skills/paidagogos-micro/SKILL.md
```

Identify the step in the pipeline where the skill composes the Lesson JSON (typically after vault lookup, before writing the JSON file).

- [ ] **Step 2: Add a "Renderer classification" step**

Insert the following step in the pipeline section (after vault lookup, before JSON assembly). If the existing SKILL.md uses numbered steps, insert as a new numbered step; adjust downstream numbering.

```markdown
### Step N: Classify renderers

1. Read `references/renderer-map.md`.
2. Apply the keyword → renderer table to the topic.
3. Collect all matching renderer keys into `renderers[]`.
4. If the lesson has a visual example, pick the single most appropriate renderer from `renderers[]` and set `example.renderer`.
5. If no keywords match and the topic is not a programming language, set `renderers: []` and omit `example.renderer`.
6. Do NOT invent renderer keys not listed in `renderer-map.md` as "available V2 renderer keys" — keep to the V2 set (`math`, `code`, `chart`, `geometry`, `sim-2d`).
```

- [ ] **Step 3: Update the JSON assembly step to include `renderers`**

Wherever the skill currently shows the JSON structure being composed, add the `renderers` field. If there's an inline JSON template in the skill, update it to match the schema from Task 1.

- [ ] **Step 4: Verify**

Re-read the SKILL.md and confirm:
- A classification step references `renderer-map.md`
- The JSON output step includes `renderers`
- The skill explicitly rejects renderer keys outside the V2 set

- [ ] **Step 5: Commit**

```bash
git add plugins/paidagogos/skills/paidagogos-micro/SKILL.md
git commit -m "feat(paidagogos): add renderer classification step to micro skill"
```

---

## Task 4: Update server.js to serve component files

**Files:**
- Modify: `plugins/paidagogos/server/server.js`

- [ ] **Step 1: Read server.js to understand the current routing**

```bash
Read plugins/paidagogos/server/server.js
```

Identify the static-file handler (likely serves lesson.html and any assets).

- [ ] **Step 2: Add `/components/**` static route**

Before the fallback handler, add a route that serves files from `server/components/` (relative to `__dirname` or the server module path). Reject any path containing `..` to prevent traversal. Set `Content-Type: text/javascript` for `.js` files.

Example addition (adjust to the existing routing style):

```javascript
const path = require('path');
const fs = require('fs');

// /components/renderers/edu-math.js → server/components/renderers/edu-math.js
if (req.url.startsWith('/components/')) {
  const safe = req.url.replace(/\.\.+/g, '');
  const filePath = path.join(__dirname, safe);
  if (!filePath.startsWith(path.join(__dirname, 'components'))) {
    res.writeHead(403); res.end('Forbidden'); return;
  }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, {
      'Content-Type': 'text/javascript; charset=utf-8',
      'Cache-Control': 'no-cache'
    });
    res.end(data);
  });
  return;
}
```

Match the existing code style (callback vs async, response helpers).

- [ ] **Step 3: Create the components directory**

```bash
mkdir -p plugins/paidagogos/server/components/renderers
```

Add a `.gitkeep` so git tracks the empty directory until the component tasks fill it:

```bash
touch plugins/paidagogos/server/components/renderers/.gitkeep
```

- [ ] **Step 4: Restart the server and verify the route**

If the server is already running, kill and relaunch via `start-server.sh`. Then:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:PORT/components/renderers/.gitkeep
```

Expected: `200`

Also verify directory traversal is blocked:

```bash
curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:PORT/components/../../../etc/passwd"
```

Expected: `403` or `404` (never `200`).

- [ ] **Step 5: Commit**

```bash
git add plugins/paidagogos/server/server.js plugins/paidagogos/server/components/renderers/.gitkeep
git commit -m "feat(paidagogos): serve /components/** static modules from server.js"
```

---

## Task 5: Refactor lesson.html — add Lit, Web Awesome, dynamic renderer imports

**Files:**
- Modify: `plugins/paidagogos/server/templates/lesson.html`

- [ ] **Step 1: Read the current lesson.html in full**

```bash
Read plugins/paidagogos/server/templates/lesson.html
```

Locate: (a) the `<script id="lesson-data">` JSON block, (b) the main render function that parses this JSON and builds the DOM, (c) the existing Prism.js include if any.

- [ ] **Step 2: Add Lit runtime and Web Awesome loader to `<head>`**

Immediately after the existing `<style>` block (before `</head>`), add:

```html
<!-- Lit 3 runtime — drives <edu-[name]> and <learn-[name]> components -->
<script type="module">
  import { LitElement, html, css } from 'https://cdn.jsdelivr.net/npm/lit@3/index.js';
  window.__lit = { LitElement, html, css };
</script>

<!-- Web Awesome — UI chrome autoloader -->
<script type="module"
  src="https://ka-f.webawesome.com/webawesome@3.5.0/webawesome.loader.js"></script>
```

- [ ] **Step 3: Add the renderer module registry**

Inside the existing `<script>` block (just after the SSE/post helpers), insert:

```javascript
// Map of renderer key → URL of its component module.
// Served from server.js /components/renderers/ route.
const RENDERER_MODULES = {
  'math':     '/components/renderers/edu-math.js',
  'code':     '/components/renderers/edu-code.js',
  'chart':    '/components/renderers/edu-chart.js',
  'geometry': '/components/renderers/edu-geometry.js',
  'sim-2d':   '/components/renderers/edu-sim-2d.js',
};

const loadedRenderers = new Set();

async function loadRenderers(keys) {
  const unique = [...new Set(keys || [])];
  const toLoad = unique.filter(k => !loadedRenderers.has(k) && RENDERER_MODULES[k]);
  await Promise.all(toLoad.map(k =>
    import(RENDERER_MODULES[k])
      .then(() => loadedRenderers.add(k))
      .catch(err => console.error(`Failed to load renderer "${k}":`, err))
  ));
}
```

- [ ] **Step 4: Call `loadRenderers()` before rendering the example**

Locate the existing `render()` (or equivalent) function that builds the DOM from the parsed `lesson` JSON. Immediately before the example is inserted into the DOM, add:

```javascript
await loadRenderers(lesson.renderers);
```

The calling function must be `async`. If it isn't, convert it.

- [ ] **Step 5: Route the `example` render through `<edu-[name]>` when `renderer` is set**

Locate the existing code block that renders the example (currently produces a `<pre class="code-block">` via Prism or plain text). Wrap it with a conditional:

```javascript
function renderExample(example) {
  if (example.renderer && example.config) {
    // V2: use web component renderer
    const el = document.createElement(`edu-${example.renderer}`);
    el.config = example.config;
    return el;
  }
  if (example.code) {
    // V1 fallback: plain code block (Prism-highlighted)
    return legacyCodeBlock(example.code, example.language);
  }
  if (example.prose) {
    const p = document.createElement('p');
    p.textContent = example.prose;
    return p;
  }
  return document.createTextNode('');
}
```

Replace the existing example-rendering inline code with a call to `renderExample(lesson.example)` and append the returned node.

- [ ] **Step 6: Verify the existing V1 code path still works**

Copy a pre-V2 lesson JSON (no `renderers` field) into the screen_dir (use any existing lesson or the Flexbox example). Open the browser.

Expected: Lesson renders identically to V1 — concept, why, code block with syntax highlighting, quiz, resources. No errors in the console. Network tab shows no requests to `/components/renderers/**`.

Take a screenshot via Chrome DevTools MCP for the record.

- [ ] **Step 7: Commit**

```bash
git add plugins/paidagogos/server/templates/lesson.html
git commit -m "feat(paidagogos): add Lit runtime, Web Awesome loader, and dynamic renderer imports to lesson.html"
```

---

## Task 6: Create `<edu-math>` component (KaTeX)

**Files:**
- Create: `plugins/paidagogos/server/components/renderers/edu-math.js`
- Create: `plugins/paidagogos/server/test-fixtures/math-lesson.json`

- [ ] **Step 1: Write the test fixture**

Create `plugins/paidagogos/server/test-fixtures/math-lesson.json`:

```json
{
  "topic": "Pythagorean Theorem",
  "level": "beginner",
  "renderers": ["math"],
  "concept": "In any right-angled triangle, the square of the hypotenuse equals the sum of the squares of the other two sides.",
  "why": "You'll use this whenever you need to compute diagonal distance — from screen coordinates to physics to 3D graphics.",
  "example": {
    "renderer": "math",
    "config": {
      "latex": "a^2 + b^2 = c^2",
      "display": true
    }
  },
  "common_mistakes": [
    "Applying the theorem to non-right triangles — it only works when one angle is exactly 90°.",
    "Forgetting to square-root the sum when solving for c."
  ],
  "generate_task": "Compute the hypotenuse of a triangle with legs 3 and 4.",
  "quiz": [
    {"type": "multiple_choice", "question": "If a=6 and b=8, what is c?", "options": ["10", "14", "12", "7"], "answer": "10", "explanation": "6² + 8² = 100, √100 = 10."},
    {"type": "fill_blank", "question": "The side opposite the right angle is called the ___.", "answer": "hypotenuse", "explanation": "The hypotenuse is always the longest side and opposite the 90° angle."},
    {"type": "explain", "question": "Why does the theorem not apply to obtuse triangles?", "answer": "because it assumes a right angle", "explanation": "The derivation depends on the 90° angle — for other angles use the law of cosines."}
  ],
  "resources": [{"title": "Pythagorean Theorem — MDN/Wikipedia", "url": "https://en.wikipedia.org/wiki/Pythagorean_theorem", "type": "docs", "source": "ai-suggested"}],
  "next": "Law of cosines — the generalisation to non-right triangles",
  "estimated_minutes": 8
}
```

- [ ] **Step 2: Write the `<edu-math>` component**

Create `plugins/paidagogos/server/components/renderers/edu-math.js`:

```javascript
// <edu-math config="{...}"> — renders LaTeX via KaTeX.
// Config: { latex: string, display: boolean }
import 'https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.js';
import 'https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.css' assert { type: 'css' };

const { LitElement, html, css } = window.__lit;

class EduMath extends LitElement {
  static properties = {
    config: { type: Object },
  };

  static styles = css`
    :host { display: block; margin: 1rem 0; font-size: 1.1rem; }
    .math-block { overflow-x: auto; padding: 0.5rem; }
    .math-error { color: var(--warning, #d29922); font-family: monospace; font-size: 0.85rem; }
  `;

  render() {
    if (!this.config || !this.config.latex) {
      return html`<div class="math-error">edu-math: missing config.latex</div>`;
    }
    try {
      const rendered = window.katex.renderToString(this.config.latex, {
        displayMode: this.config.display === true,
        throwOnError: false,
        output: 'html',
      });
      return html`<div class="math-block" .innerHTML=${rendered}></div>`;
    } catch (err) {
      return html`<div class="math-error">KaTeX error: ${err.message}</div>`;
    }
  }
}

customElements.define('edu-math', EduMath);
```

Note on CSS import: if the `assert { type: 'css' }` syntax fails in the target browser, fall back to a `<link rel="stylesheet">` injected once on first import. The first task of the test step will catch this.

- [ ] **Step 3: Verify via browser**

Copy the fixture into the screen_dir the server watches. Open the browser (use chrome-devtools-mcp `navigate_page` to the server URL). Wait for SSE reload.

Expected:
- `a² + b² = c²` displays as properly rendered math (superscript glyphs, italic variables).
- Network tab shows KaTeX JS + CSS loaded once from cdn.jsdelivr.net.
- No console errors.
- Network tab shows `/components/renderers/edu-math.js` loaded; NO load of edu-chart/geometry/sim-2d/code.

If you observe `Failed to load stylesheet` for the CSS import, switch to a `<link>` injection:

```javascript
if (!document.querySelector('link[data-katex]')) {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.css';
  link.dataset.katex = 'true';
  document.head.appendChild(link);
}
```

Add this near the top of the component file, remove the CSS import line, and retest.

- [ ] **Step 4: Commit**

```bash
git add plugins/paidagogos/server/components/renderers/edu-math.js plugins/paidagogos/server/test-fixtures/math-lesson.json
git commit -m "feat(paidagogos): add <edu-math> renderer (KaTeX)"
```

---

## Task 7: Create `<edu-code>` component (CodeMirror 6)

**Files:**
- Create: `plugins/paidagogos/server/components/renderers/edu-code.js`
- Create: `plugins/paidagogos/server/test-fixtures/code-lesson.json`

- [ ] **Step 1: Write the test fixture**

Create `plugins/paidagogos/server/test-fixtures/code-lesson.json`:

```json
{
  "topic": "JavaScript array.map",
  "level": "beginner",
  "renderers": ["code"],
  "concept": "map() returns a new array with each element transformed by the callback.",
  "why": "You'll use this whenever you need to convert a list of one kind of thing into another — e.g. user IDs into user objects.",
  "example": {
    "renderer": "code",
    "config": {
      "language": "javascript",
      "code": "const doubled = [1, 2, 3].map(n => n * 2);\n// doubled: [2, 4, 6]",
      "editable": false
    }
  },
  "common_mistakes": [
    "Confusing map with forEach — forEach returns undefined, map returns a new array.",
    "Forgetting that map does NOT modify the original array."
  ],
  "generate_task": "Use map to turn ['alice', 'bob'] into ['Alice', 'Bob'].",
  "quiz": [
    {"type": "multiple_choice", "question": "What does [1,2,3].map(n => n+1) return?", "options": ["[2,3,4]", "[1,2,3]", "undefined", "6"], "answer": "[2,3,4]", "explanation": "map produces a new array with each element + 1."},
    {"type": "fill_blank", "question": "Unlike forEach, map returns a new ___.", "answer": "array", "explanation": "forEach returns undefined; map returns a transformed array."},
    {"type": "explain", "question": "Why prefer map over a for-loop when transforming an array?", "answer": "it's declarative and returns a new array without mutation", "explanation": "map expresses intent clearly and avoids mutating the original data."}
  ],
  "resources": [{"title": "Array.prototype.map — MDN", "url": "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map", "type": "docs", "source": "ai-suggested"}],
  "next": "Array.prototype.filter — selecting elements by predicate",
  "estimated_minutes": 10
}
```

- [ ] **Step 2: Write the `<edu-code>` component**

Create `plugins/paidagogos/server/components/renderers/edu-code.js`:

```javascript
// <edu-code config="{...}"> — syntax-highlighted code, optionally editable.
// Config: { language: string, code: string, editable?: boolean }
// Uses CodeMirror 6 from esm.sh to keep ESM-native CDN imports working.

const { LitElement, html, css } = window.__lit;

const CM_URL = 'https://esm.sh/codemirror@6.0.1?bundle';
const LANG_URLS = {
  'javascript': 'https://esm.sh/@codemirror/lang-javascript@6.2.2?bundle',
  'typescript': 'https://esm.sh/@codemirror/lang-javascript@6.2.2?bundle',
  'python':     'https://esm.sh/@codemirror/lang-python@6.1.6?bundle',
  'css':        'https://esm.sh/@codemirror/lang-css@6.3.0?bundle',
  'html':       'https://esm.sh/@codemirror/lang-html@6.4.9?bundle',
  'json':       'https://esm.sh/@codemirror/lang-json@6.0.1?bundle',
};

async function loadLang(language) {
  const url = LANG_URLS[language];
  if (!url) return null;
  const mod = await import(url);
  const factoryName = Object.keys(mod).find(k => typeof mod[k] === 'function');
  return factoryName ? mod[factoryName]() : null;
}

class EduCode extends LitElement {
  static properties = {
    config: { type: Object },
  };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { border: 1px solid var(--border, #e9ecef); border-radius: 8px; overflow: hidden; }
    .cm-editor { font-family: "SF Mono", Consolas, monospace; font-size: 0.9rem; }
  `;

  async firstUpdated() {
    if (!this.config?.code) return;
    const [{ EditorView, basicSetup }, { EditorState }] = await Promise.all([
      import(CM_URL),
      import('https://esm.sh/@codemirror/state@6.4.1?bundle'),
    ]);
    const langExt = await loadLang(this.config.language);
    const container = this.renderRoot.querySelector('.wrap');
    new EditorView({
      state: EditorState.create({
        doc: this.config.code,
        extensions: [
          basicSetup,
          ...(langExt ? [langExt] : []),
          ...(this.config.editable === false ? [EditorState.readOnly.of(true)] : []),
        ],
      }),
      parent: container,
    });
  }

  render() {
    return html`<div class="wrap"></div>`;
  }
}

customElements.define('edu-code', EduCode);
```

- [ ] **Step 3: Verify via browser**

Copy `code-lesson.json` into screen_dir. Navigate in the browser.

Expected:
- Code block renders with JS syntax highlighting (keywords coloured, comments italicised).
- Because `editable: false`, clicking inside the editor does not allow typing.
- No console errors.
- Network tab shows CodeMirror bundles loaded from esm.sh exactly once.

Take a screenshot.

- [ ] **Step 4: Commit**

```bash
git add plugins/paidagogos/server/components/renderers/edu-code.js plugins/paidagogos/server/test-fixtures/code-lesson.json
git commit -m "feat(paidagogos): add <edu-code> renderer (CodeMirror 6)"
```

---

## Task 8: Create `<edu-chart>` component (Chart.js)

**Files:**
- Create: `plugins/paidagogos/server/components/renderers/edu-chart.js`
- Create: `plugins/paidagogos/server/test-fixtures/chart-lesson.json`

- [ ] **Step 1: Write the test fixture**

Create `plugins/paidagogos/server/test-fixtures/chart-lesson.json`:

```json
{
  "topic": "Histograms",
  "level": "beginner",
  "renderers": ["chart"],
  "concept": "A histogram groups continuous values into bins and shows the count in each bin.",
  "why": "You'll use a histogram whenever you need to see the shape of a distribution — is it normal, skewed, or bimodal?",
  "example": {
    "renderer": "chart",
    "config": {
      "library": "chartjs",
      "type": "bar",
      "data": {
        "labels": ["0-10", "10-20", "20-30", "30-40", "40-50", "50-60"],
        "datasets": [{
          "label": "Frequency",
          "data": [4, 12, 28, 22, 8, 2],
          "backgroundColor": "rgba(88, 166, 255, 0.6)"
        }]
      },
      "options": {
        "responsive": true,
        "plugins": { "legend": { "display": false } },
        "scales": { "y": { "beginAtZero": true } }
      }
    }
  },
  "common_mistakes": [
    "Choosing too few or too many bins — 5–20 is usually right; outside that range you lose signal or amplify noise.",
    "Treating the x-axis as ordinal — histogram x-axis is continuous, bars touch each other."
  ],
  "generate_task": "Describe the distribution shown in the histogram — is it symmetric, skewed left, or skewed right?",
  "quiz": [
    {"type": "multiple_choice", "question": "The x-axis of a histogram represents...", "options": ["categories", "value bins", "time", "counts"], "answer": "value bins", "explanation": "Each bar covers a range of continuous values."},
    {"type": "fill_blank", "question": "The height of each bar represents the ___ of values in that bin.", "answer": "count", "explanation": "More formally, the frequency or count."},
    {"type": "explain", "question": "How do you choose a good bin width?", "answer": "enough bins to show shape, few enough to smooth noise", "explanation": "Rules of thumb: Sturges' formula, or √n bins."}
  ],
  "resources": [{"title": "Histogram — Wikipedia", "url": "https://en.wikipedia.org/wiki/Histogram", "type": "docs", "source": "ai-suggested"}],
  "next": "Box plots — another way to summarise a distribution",
  "estimated_minutes": 10
}
```

- [ ] **Step 2: Write the `<edu-chart>` component**

Create `plugins/paidagogos/server/components/renderers/edu-chart.js`:

```javascript
// <edu-chart config="{...}"> — renders Chart.js charts from a JSON config.
// Config: { library: "chartjs", type: string, data: object, options?: object }

const { LitElement, html, css } = window.__lit;
const CHARTJS_URL = 'https://esm.sh/chart.js@4.4.1/auto';

class EduChart extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { position: relative; width: 100%; max-width: 720px; }
  `;

  async firstUpdated() {
    if (!this.config) return;
    if (this.config.library !== 'chartjs') {
      console.warn('edu-chart: only "chartjs" library supported in V2');
      return;
    }
    const { default: Chart } = await import(CHARTJS_URL);
    const canvas = this.renderRoot.querySelector('canvas');
    new Chart(canvas, {
      type: this.config.type,
      data: this.config.data,
      options: this.config.options || { responsive: true },
    });
  }

  render() {
    return html`<div class="wrap"><canvas></canvas></div>`;
  }
}

customElements.define('edu-chart', EduChart);
```

- [ ] **Step 3: Verify via browser**

Copy `chart-lesson.json` into screen_dir. Navigate in the browser.

Expected:
- Bar chart renders with six bars showing the distribution.
- Y-axis starts at 0, no legend.
- Network shows Chart.js loaded from esm.sh.
- No console errors.

Take a screenshot.

- [ ] **Step 4: Commit**

```bash
git add plugins/paidagogos/server/components/renderers/edu-chart.js plugins/paidagogos/server/test-fixtures/chart-lesson.json
git commit -m "feat(paidagogos): add <edu-chart> renderer (Chart.js)"
```

---

## Task 9: Create `<edu-geometry>` component (JSXGraph)

**Files:**
- Create: `plugins/paidagogos/server/components/renderers/edu-geometry.js`
- Create: `plugins/paidagogos/server/test-fixtures/geometry-lesson.json`

- [ ] **Step 1: Write the test fixture**

Create `plugins/paidagogos/server/test-fixtures/geometry-lesson.json`:

```json
{
  "topic": "Triangle angle sum",
  "level": "beginner",
  "renderers": ["geometry", "math"],
  "concept": "The interior angles of a triangle always sum to 180°, regardless of its shape.",
  "why": "You'll use this in any proof involving triangles — it's the building block of Euclidean geometry.",
  "example": {
    "renderer": "geometry",
    "config": {
      "board": {"boundingbox": [-1, 6, 8, -1], "axis": true, "showCopyright": false},
      "elements": [
        {"type": "point", "id": "A", "args": [0, 0], "attrs": {"name": "A"}},
        {"type": "point", "id": "B", "args": [5, 0], "attrs": {"name": "B"}},
        {"type": "point", "id": "C", "args": [2, 4], "attrs": {"name": "C"}},
        {"type": "polygon", "args": [["A", "B", "C"]], "attrs": {"fillColor": "rgba(88, 166, 255, 0.2)"}}
      ]
    }
  },
  "common_mistakes": [
    "Forgetting that the 180° sum holds only in plane (Euclidean) geometry — on a sphere, angles sum to more than 180°.",
    "Confusing interior and exterior angles — exterior angles sum to 360°."
  ],
  "generate_task": "If two angles of a triangle are 45° and 85°, what is the third?",
  "quiz": [
    {"type": "multiple_choice", "question": "The interior angles of any triangle sum to...", "options": ["90°", "180°", "270°", "360°"], "answer": "180°", "explanation": "This is the fundamental theorem of plane geometry for triangles."},
    {"type": "fill_blank", "question": "Exterior angles of any triangle sum to ___°.", "answer": "360", "explanation": "Each exterior angle = 180° - its interior; 3×180 - 180 = 360."},
    {"type": "explain", "question": "Does the 180° rule hold on a sphere?", "answer": "no, spherical triangles sum to more than 180°", "explanation": "On a sphere, geodesic triangles have an angle excess proportional to their area."}
  ],
  "resources": [{"title": "Sum of angles of a triangle — Wikipedia", "url": "https://en.wikipedia.org/wiki/Sum_of_angles_of_a_triangle", "type": "docs", "source": "ai-suggested"}],
  "next": "Law of sines — relates sides to sines of opposite angles",
  "estimated_minutes": 10
}
```

- [ ] **Step 2: Write the `<edu-geometry>` component**

Create `plugins/paidagogos/server/components/renderers/edu-geometry.js`:

```javascript
// <edu-geometry config="{...}"> — interactive 2D geometry via JSXGraph.
// Config: { board: JSXGraphBoardAttrs, elements: Array<{type, id?, args, attrs}> }

const { LitElement, html, css } = window.__lit;
const JSX_URL = 'https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.11.1/jsxgraphcore.min.js';
const JSX_CSS = 'https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.11.1/jsxgraph.min.css';

async function ensureJSX() {
  if (window.JXG) return;
  await new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = JSX_URL;
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
  if (!document.querySelector('link[data-jsx]')) {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = JSX_CSS;
    link.dataset.jsx = 'true';
    document.head.appendChild(link);
  }
}

class EduGeometry extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .board { width: 100%; max-width: 600px; height: 400px; border: 1px solid var(--border, #e9ecef); border-radius: 8px; }
  `;

  async firstUpdated() {
    if (!this.config?.board) return;
    await ensureJSX();
    const div = this.renderRoot.querySelector('.board');
    // JSXGraph needs a real id on the host div
    const hostId = 'jxg-' + Math.random().toString(36).slice(2, 10);
    div.id = hostId;
    const board = window.JXG.JSXGraph.initBoard(hostId, this.config.board);
    const refs = {};
    for (const el of (this.config.elements || [])) {
      const resolvedArgs = el.args.map(a =>
        Array.isArray(a) ? a.map(x => refs[x] || x) : (refs[a] || a)
      );
      const created = board.create(el.type, resolvedArgs, el.attrs || {});
      if (el.id) refs[el.id] = created;
    }
  }

  render() {
    return html`<div class="board"></div>`;
  }
}

customElements.define('edu-geometry', EduGeometry);
```

- [ ] **Step 3: Verify via browser**

Copy `geometry-lesson.json` into screen_dir. Navigate.

Expected:
- A triangle with labelled vertices A, B, C renders.
- You can drag any vertex and the triangle updates (JSXGraph default interactivity).
- No console errors.
- Network shows JSXGraph JS + CSS loaded once.

Take a screenshot.

- [ ] **Step 4: Commit**

```bash
git add plugins/paidagogos/server/components/renderers/edu-geometry.js plugins/paidagogos/server/test-fixtures/geometry-lesson.json
git commit -m "feat(paidagogos): add <edu-geometry> renderer (JSXGraph)"
```

---

## Task 10: Create `<edu-sim-2d>` component (Matter.js)

**Files:**
- Create: `plugins/paidagogos/server/components/renderers/edu-sim-2d.js`
- Create: `plugins/paidagogos/server/test-fixtures/sim-2d-lesson.json`

- [ ] **Step 1: Write the test fixture**

Create `plugins/paidagogos/server/test-fixtures/sim-2d-lesson.json`:

```json
{
  "topic": "Gravity and falling objects",
  "level": "beginner",
  "renderers": ["sim-2d"],
  "concept": "Objects near Earth's surface accelerate downward at ~9.8 m/s² regardless of mass (neglecting air resistance).",
  "why": "You'll use this to predict motion in games, physics problems, and real-world trajectories from ballistics to satellites.",
  "example": {
    "renderer": "sim-2d",
    "config": {
      "world": {"gravity": {"x": 0, "y": 1}},
      "bodies": [
        {"type": "rectangle", "x": 400, "y": 580, "width": 800, "height": 40, "options": {"isStatic": true, "label": "ground"}},
        {"type": "circle", "x": 200, "y": 100, "radius": 30, "options": {"restitution": 0.7, "label": "small ball"}},
        {"type": "circle", "x": 600, "y": 100, "radius": 60, "options": {"restitution": 0.7, "label": "big ball"}}
      ],
      "canvas": {"width": 800, "height": 600}
    }
  },
  "common_mistakes": [
    "Thinking heavier objects fall faster — in a vacuum they don't; on Earth air resistance makes the difference.",
    "Forgetting that g depends on the planet — the moon has about 1/6 of Earth's gravity."
  ],
  "generate_task": "Predict which ball hits the ground first. Then observe and explain.",
  "quiz": [
    {"type": "multiple_choice", "question": "On Earth (no air resistance), a heavy ball and a light ball dropped together will...", "options": ["heavy lands first", "light lands first", "both land together", "depends on shape"], "answer": "both land together", "explanation": "Gravitational acceleration is mass-independent."},
    {"type": "fill_blank", "question": "Earth's gravitational acceleration is approximately ___ m/s².", "answer": "9.8", "explanation": "9.81 m/s² is the standard value at sea level."},
    {"type": "explain", "question": "Why do feathers fall slower than rocks in practice?", "answer": "air resistance affects low-mass, high-area objects more", "explanation": "In a vacuum (Apollo 15 hammer and feather experiment) they fall identically."}
  ],
  "resources": [{"title": "Gravitational acceleration — Wikipedia", "url": "https://en.wikipedia.org/wiki/Gravitational_acceleration", "type": "docs", "source": "ai-suggested"}],
  "next": "Projectile motion — gravity + initial velocity",
  "estimated_minutes": 12
}
```

- [ ] **Step 2: Write the `<edu-sim-2d>` component**

Create `plugins/paidagogos/server/components/renderers/edu-sim-2d.js`:

```javascript
// <edu-sim-2d config="{...}"> — interactive 2D physics via Matter.js.
// Config: {
//   world: { gravity: {x, y} },
//   bodies: Array<{type, x, y, ...dims, options}>,
//   canvas: { width, height }
// }

const { LitElement, html, css } = window.__lit;
const MATTER_URL = 'https://esm.sh/matter-js@0.20.0';

class EduSim2d extends LitElement {
  static properties = { config: { type: Object } };

  static styles = css`
    :host { display: block; margin: 1rem 0; }
    .wrap { border: 1px solid var(--border, #e9ecef); border-radius: 8px; overflow: hidden; background: var(--surface, #f8f9fa); }
    canvas { display: block; max-width: 100%; }
  `;

  async firstUpdated() {
    if (!this.config?.canvas) return;
    const Matter = await import(MATTER_URL);
    const { Engine, Render, Runner, Bodies, Composite, Mouse, MouseConstraint } = Matter;

    const engine = Engine.create({ gravity: this.config.world?.gravity || { x: 0, y: 1 } });
    const container = this.renderRoot.querySelector('.wrap');
    const render = Render.create({
      element: container,
      engine,
      options: {
        width: this.config.canvas.width,
        height: this.config.canvas.height,
        wireframes: false,
        background: 'transparent',
      },
    });

    const bodies = (this.config.bodies || []).map(b => {
      switch (b.type) {
        case 'rectangle': return Bodies.rectangle(b.x, b.y, b.width, b.height, b.options || {});
        case 'circle':    return Bodies.circle(b.x, b.y, b.radius, b.options || {});
        case 'polygon':   return Bodies.polygon(b.x, b.y, b.sides, b.radius, b.options || {});
        default: console.warn('edu-sim-2d: unknown body type', b.type); return null;
      }
    }).filter(Boolean);

    Composite.add(engine.world, bodies);

    const mouse = Mouse.create(render.canvas);
    const mouseConstraint = MouseConstraint.create(engine, {
      mouse,
      constraint: { stiffness: 0.2, render: { visible: false } },
    });
    Composite.add(engine.world, mouseConstraint);
    render.mouse = mouse;

    Render.run(render);
    const runner = Runner.create();
    Runner.run(runner, engine);
  }

  render() {
    return html`<div class="wrap"></div>`;
  }
}

customElements.define('edu-sim-2d', EduSim2d);
```

- [ ] **Step 3: Verify via browser**

Copy `sim-2d-lesson.json` into screen_dir. Navigate.

Expected:
- Two circles fall and bounce on a ground plane.
- Clicking and dragging a ball physically drags it (MouseConstraint).
- Both balls hit the ground simultaneously (because gravity is mass-independent — this is what the lesson demonstrates).
- No console errors.
- Network shows matter-js loaded from esm.sh.

Take a screenshot mid-simulation (ball mid-air).

- [ ] **Step 4: Commit**

```bash
git add plugins/paidagogos/server/components/renderers/edu-sim-2d.js plugins/paidagogos/server/test-fixtures/sim-2d-lesson.json
git commit -m "feat(paidagogos): add <edu-sim-2d> renderer (Matter.js)"
```

---

## Task 11: Full regression verification

**Files:**
- Read: all test fixtures
- Read: lesson.html
- Read: an existing non-renderer Lesson JSON (pre-V2)

- [ ] **Step 1: Verify V1 backwards compatibility**

Find or create a Lesson JSON without a `renderers` field (e.g. the Flexbox example from lesson-schema.md — minus the `renderers` field). Place in screen_dir.

Expected:
- Lesson renders fully (concept, why, code block with Prism, quiz, resources).
- Console shows no errors about missing `renderers` field.
- Network tab shows NO loads of `/components/renderers/*.js`.

If the `renderExample` function from Task 5 doesn't handle `lesson.renderers === undefined` gracefully, update it to default to `[]`:

```javascript
await loadRenderers(lesson.renderers || []);
```

- [ ] **Step 2: Verify each V2 fixture**

For each test fixture in `plugins/paidagogos/server/test-fixtures/`:
1. Copy into screen_dir
2. Wait for SSE reload
3. Check: the right renderer is active in the DOM (look for `<edu-math>`, `<edu-chart>`, etc.)
4. Check network: only the listed renderer modules loaded
5. Check console: zero errors

- [ ] **Step 3: Verify lazy loading — multi-renderer lesson**

Modify the Pythagorean fixture so `renderers: ["math", "geometry"]` and add a geometry config. Navigate. Check: both math and geometry modules load; chart/code/sim-2d do NOT load.

- [ ] **Step 4: Verify the quiz still works end-to-end**

Use any fixture with a quiz. Click through multiple-choice → fill-blank → explain. Verify:
- Answers are accepted
- Explanations reveal
- Quiz events POST to `/events` (check Network)
- SSE reload still works when the JSON file changes

- [ ] **Step 5: Document runtime findings**

If any component had CDN version mismatches, browser compat issues, or loading quirks — note them in `CHANGELOG.md` under `## V2 — Core Renderer System` with specific versions pinned.

- [ ] **Step 6: Commit findings (if any)**

```bash
git add plugins/paidagogos/CHANGELOG.md
git commit -m "docs(paidagogos): record V2 renderer verification notes"
```

If no changes, skip this commit.

---

## Task 12: Update DECISIONS.md with V2 decisions

**Files:**
- Modify: `docs/plugins/learn/DECISIONS.md`

- [ ] **Step 1: Read current DECISIONS.md**

```bash
Read docs/plugins/learn/DECISIONS.md
```

Note the existing decision numbering to continue the sequence.

- [ ] **Step 2: Append V2 decisions**

Add new entries at the end of the file:

```markdown
## V2 Decisions

### Decision 8 — Two-layer component model: `<edu-[name]>` vs `<learn-[name]>`

**Context:** V2 introduces interactive renderers. We needed to decide whether to give them plugin-scoped names (`<paidagogos-math>`) or broader names.

**Decision:** Two prefixes. `<edu-[name]>` for subject-domain renderers (math, chart, code, geometry, sim-2d, etc.) with no plugin state or skill awareness. `<learn-[name]>` for pedagogy components (quiz, hint, progress, streak) that are plugin-scoped and can read `.paidagogos/prefs.json`.

**Why:** Renderers are portable — a future tutoring plugin should be able to reuse `<edu-math>` without dragging paidagogos state with it. Pedagogy components are intrinsically tied to the learn lifecycle; they need plugin state and skill hooks.

**Consequences:** Component files live in two directories (`components/renderers/`, `components/pedagogy/`). The boundary is enforced by naming — any `<edu-[name]>` that imports `.paidagogos/prefs.json` is a lint violation.

### Decision 9 — Lit 3 for web components, CDN ESM only

**Context:** Needed a web component framework. Candidates: Lit, Stencil, Svelte, Microsoft FAST, vanilla.

**Decision:** Lit 3.x, loaded via CDN as an ES module (`cdn.jsdelivr.net/npm/lit@3`).

**Why:** 5 KB gzipped runtime, no build step (drops into `lesson.html` as `<script type="module">`), class-based authoring matches existing JS patterns, Shadow DOM optional so CSS custom properties flow through. Google uses it at YouTube/Chrome DevTools scale.

**Consequences:** No build pipeline for V2. All libraries must be CDN-deliverable. Component files live as plain `.js` ES modules served by the existing HTTP server.

### Decision 10 — Web Awesome for UI chrome (not Shoelace)

**Context:** Needed prebuilt UI components (progress bars, tabs, dialogs, badges).

**Decision:** Web Awesome 3.x via CDN autoloader. Shoelace is sunset; Web Awesome is its active successor from the same author.

**Why:** Same component API philosophy as Shoelace, actively developed, free CDN tier, no build step.

**Consequences:** Lesson.html loads `https://ka-f.webawesome.com/webawesome@3.5.0/webawesome.loader.js`. Components load on first use only. Pro-tier components are opt-in and paid.

### Decision 11 — `renderers[]` in Lesson JSON drives lazy loading

**Context:** Different lessons need different renderers. Loading all of them always wastes bandwidth and blocks the page.

**Decision:** Lesson JSON includes a required `renderers: RendererKey[]` field. `lesson.html` reads it and dynamically imports only the listed modules.

**Why:** Keeps the base payload small (Lit 5 KB + Web Awesome loader + Prism 2 KB). A CSS lesson never loads Three.js. An authoring error (missing renderer key) fails loudly instead of silently.

**Consequences:** `paidagogos:micro` must classify renderers for every lesson. `renderer-map.md` is the single source of truth for topic → renderer mapping. Adding a new renderer requires: (a) component file, (b) entry in `RENDERER_MODULES`, (c) keyword added to `renderer-map.md`, (d) V2 set expanded in `lesson-schema.md`.
```

- [ ] **Step 3: Commit**

```bash
git add docs/plugins/learn/DECISIONS.md
git commit -m "docs(paidagogos): record V2 architecture decisions 8-11"
```

---

## Task 13: Update CHANGELOG.md

**Files:**
- Modify: `plugins/paidagogos/CHANGELOG.md`

- [ ] **Step 1: Add V2 entry**

Prepend (after the header) a new section:

```markdown
## 0.2.0 — 2026-04-XX

### Added — V2 Core Renderer System
- `renderers[]` field in Lesson JSON — lazy imports by topic
- `<edu-math>` — KaTeX-rendered mathematics (inline + display mode)
- `<edu-code>` — CodeMirror 6 code blocks with language syntax (JS, TS, Python, CSS, HTML, JSON)
- `<edu-chart>` — Chart.js charts via JSON config (bar, line, scatter, etc.)
- `<edu-geometry>` — JSXGraph interactive 2D geometry
- `<edu-sim-2d>` — Matter.js 2D physics simulations
- `renderer-map.md` — keyword → renderer classification table for `paidagogos:micro`
- Lit 3 runtime bootstrapped in lesson.html
- Web Awesome 3 UI chrome loader
- `/components/**` static route in the HTTP server

### Changed
- `lesson.html` now reads `renderers[]` and lazy-imports components via ESM
- `example` field in Lesson JSON can now include `renderer` and `config` for renderer-driven rendering; `code`/`prose` remain for plain lessons
- `paidagogos:micro` SKILL.md gained a "Classify renderers" step

### Compatibility
- Pre-V2 lessons (no `renderers` field) render identically to V1 — the field defaults to `[]` at runtime
```

Replace `2026-04-XX` with the date the branch is merged.

- [ ] **Step 2: Commit**

```bash
git add plugins/paidagogos/CHANGELOG.md
git commit -m "docs(paidagogos): changelog entry for V2 renderer system"
```

---

## Final Verification

Before marking the plan complete, run this end-to-end check:

- [ ] **Step 1: Clean server start**

Kill any running paidagogos server. Run `plugins/paidagogos/server/start-server.sh`. Verify it boots and prints the server URL.

- [ ] **Step 2: Test each fixture in sequence**

For each fixture (`math`, `code`, `chart`, `geometry`, `sim-2d`):
1. Copy to screen_dir
2. SSE reload
3. Visual check passes
4. Network tab check: only the relevant renderer(s) loaded
5. Console clean

- [ ] **Step 3: Test a V1 (no-renderer) lesson**

Copy a pre-V2 Lesson JSON. Verify it still works.

- [ ] **Step 4: Test a multi-renderer lesson**

Write a one-off fixture with `renderers: ["math", "geometry"]` and an example that uses `geometry`. Verify both modules load.

- [ ] **Step 5: Report**

Report: "V2 complete. All 5 renderers verified. V1 backwards compat confirmed. Ready to merge to main."

---

## Deferred to later plans

The following from the spec are NOT in this V2 plan — each will get its own plan:

- **V2.1** (`2026-04-XX-paidagogos-v2.1-heavy-renderers.md`): `<edu-python>` (Pyodide), `<edu-sandbox>` (Sandpack), `<edu-scene-3d>` (Three.js), `<edu-canvas>` (p5.js)
- **V2.2** (`2026-04-XX-paidagogos-v2.2-pedagogy.md`): `<learn-hint>`, `<learn-progress>`, `<learn-streak>`, `<learn-explain>` + `paidagogos:explain` skill + `.paidagogos/prefs.json` schema extension
- **V3** (`2026-04-XX-paidagogos-v3-adaptive.md`): FSRS scheduling, `paidagogos:recall`, `paidagogos:path`, BKT mastery tracking

---

## Spec reference

Full architectural context: `docs/superpowers/specs/2026-04-15-learn-v2-design.md` (sections 3.1–3.5 and Phase V2).
Research and tool comparison: `docs/plugins/learn/research/rendering-and-pedagogy.md`.
