# Learn Plugin V2 — Modular Renderer Architecture Design

**Date:** 2026-04-15  
**Status:** Approved  
**Scope:** V2 through V3 phases — renderer system, pedagogy layer, adaptive layer

---

## 1. Problem

The V1 learn plugin generates rich Lesson JSON but renders everything as static text and code blocks. No subject-domain visualisation. A trigonometry lesson can't show an interactive unit circle. A physics lesson can't run a simulation. A data science lesson can't execute Python.

The template is fixed: concept → why → example → quiz. The example is always a code block or plain text, regardless of topic.

This limits the plugin to text-heavy subjects and prevents the high-retention teaching patterns (Visual/Conceptual, Learn-by-Doing, Active Recall with spaced repetition) from being applied.

---

## 2. Goals

1. **V2:** Subject-domain renderers — lessons can include interactive math, charts, geometry, physics simulations, live code, and 3D scenes
2. **V2.1:** Heavy renderers — Python execution, JS live playgrounds, 3D, canvas
3. **V2.2:** Pedagogy layer — Socratic hints, mastery progress, streaks, Feynman explain-back
4. **V3:** Adaptive layer — spaced repetition scheduling, knowledge tracing, learning paths

Non-goals for this spec:
- Multi-agent architecture (V3+ research item)
- Mobile-native clients
- LMS integrations

---

## 3. Architecture

### 3.1 Two-Layer Component Model

The system uses two component namespaces with a hard boundary between them:

**`<edu-[name]>` — Renderer Catalog (portable)**

Subject-domain renderers. Pure display/interaction components. No plugin state, no skill awareness, no `.learn/prefs.json` access. Can be embedded in any web page or other plugins.

```
<edu-math>          KaTeX equation display
<edu-math-input>    MathLive interactive editor (for assessment input)
<edu-geometry>      JSXGraph 2D interactive geometry
<edu-graph>         Desmos graphing calculator
<edu-chart>         Chart.js / Plotly.js charts (switched by lesson config)
<edu-code>          CodeMirror 6 — static or editable code blocks
<edu-sandbox>       Sandpack — live JS/TS/React execution
<edu-python>        Pyodide — full CPython WASM runtime
<edu-python-loader> Loader state component (required for Pyodide)
<edu-scene-3d>      Three.js / A-Frame 3D scene
<edu-sim-2d>        Matter.js 2D physics simulation
<edu-canvas>        p5.js creative coding canvas
<edu-audio>         Tone.js + Wavesurfer.js
<edu-animate>       GSAP / Rive animation
```

**`<learn-[name]>` — Pedagogy Components (plugin-scoped)**

Plugin-specific interaction components. Know about `.learn/prefs.json`, session state, and skill-generated data. Tied to the learn plugin lifecycle.

```
<learn-quiz>        Quiz interaction (existing — extend)
<learn-hint>        Socratic hint system (three-tier: nudge → clue → answer)
<learn-explain>     Feynman explain-back (text input + AI evaluation)
<learn-progress>    Mastery and path progress indicator
<learn-streak>      Habit tracking — daily streak badge + XP
```

**UI Chrome: Web Awesome**

Web Awesome (CDN) provides buttons, badges, progress bars, tab panels, tooltips, and dialogs. It is the visual framework layer that wraps both component types. Loaded via the CDN autoloader:

```html
<script type="module"
  src="https://ka-f.webawesome.com/webawesome@3.5.0/webawesome.loader.js">
</script>
```

Components load only when used. Free core tier. No build step.

---

### 3.2 Lesson JSON Extension

Add a `renderers` array to the existing Lesson JSON schema:

```typescript
interface Lesson {
  // Existing V1 fields (unchanged)
  topic: string;
  level: "beginner" | "intermediate" | "advanced";
  persona: string;
  concept: string;
  why: string;
  example: LessonExample;
  quiz: QuizQuestion[];
  
  // V2 extension
  renderers: RendererKey[];  // list of <edu-[name]> keys needed by this lesson
}

type RendererKey =
  | "math" | "math-input" | "geometry" | "graph" | "chart"
  | "code" | "sandbox" | "python" | "scene-3d" | "sim-2d"
  | "canvas" | "audio" | "animate";

interface LessonExample {
  type: string;
  renderer?: RendererKey;  // which <edu-[name]> renders this example
  config?: Record<string, unknown>;  // renderer-specific config
}
```

Example — Fourier Series lesson:

```json
{
  "topic": "Fourier Series",
  "level": "intermediate",
  "renderers": ["math", "chart"],
  "example": {
    "type": "chart",
    "renderer": "chart",
    "config": {
      "library": "chartjs",
      "chart_type": "line",
      "title": "Fourier approximation of a square wave",
      "datasets": [{ "label": "3 terms", "data": [...] }, { "label": "10 terms", "data": [...] }]
    }
  }
}
```

---

### 3.3 Renderer Tier System (Load Strategy)

lesson.html reads `renderers[]` on load and lazy-imports only the listed components. A lesson with `"renderers": ["code"]` never loads Three.js.

| Tier | Components | Load strategy |
|------|-----------|---------------|
| **0 — Always** | Lit runtime (5 KB), Web Awesome loader, Prism.js (2 KB core) | Bundled inline in lesson.html |
| **1 — Light** | KaTeX, Chart.js, Wavesurfer.js, Matter.js | Dynamic import on demand, <100 KB gz each |
| **2 — Medium** | Three.js, CodeMirror 6, D3.js, JSXGraph | Lazy import, 75–155 KB gz |
| **3 — Heavy** | Plotly.js, Pyodide, Monaco Editor, GeoGebra | Explicit `<edu-[X]-loader>` required, >400 KB |

**Rule:** Any renderer in Tier 3 must show an `<edu-[X]-loader>` progress component before mounting. The renderer itself is not inserted into the DOM until the loader completes.

---

### 3.4 Topic → Renderer Mapping

`paidagogos:micro` uses a `renderer-map.md` reference file (parallel to `vault-integration.md`) to determine the `renderers[]` array for a given topic:

```
"CSS Flexbox"        → ["code"]
"Trigonometry"       → ["math", "geometry"]
"Fourier Series"     → ["math", "chart"]
"Sorting Algorithms" → ["code", "canvas"]
"Orbital Mechanics"  → ["scene-3d", "sim-2d"]
"Python pandas"      → ["code", "python"]
"Music Intervals"    → ["audio"]
"Newton's Laws"      → ["sim-2d", "chart"]
"Molecular Bonds"    → ["scene-3d"]
"Statistics"         → ["chart", "math"]
```

The skill selects renderers based on topic classification keywords + subject domain. Unrecognised topics default to `["code"]`.

---

### 3.5 Web Component Framework

**Lit** (v3.x, 5 KB gz, no build step).

Reasons: negligible runtime cost, no build toolchain required (drop `<script type="module">` into lesson.html), class-based authoring, reactive properties, Shadow DOM optional (CSS custom properties from lesson.html flow through), Google-backed with YouTube/Chrome DevTools production usage.

Lit components are defined in separate files under `plugins/paidagogos/server/components/`:

```
components/
  renderers/
    edu-math.js
    edu-chart.js
    edu-code.js
    edu-geometry.js
    edu-sim-2d.js
    edu-scene-3d.js
    edu-python.js
    edu-python-loader.js
    ...
  pedagogy/
    learn-quiz.js       (refactored from inline lesson.html)
    learn-hint.js
    learn-explain.js
    learn-progress.js
    learn-streak.js
```

lesson.html generates `<script type="module">` imports dynamically based on the lesson's `renderers[]` array.

---

### 3.6 Pedagogy Data Model

All pedagogy state persists in `.learn/prefs.json` (already referenced in V1 vault integration):

```typescript
interface LearnPrefs {
  // V1 (existing)
  topics_seen: string[];
  
  // V2.2 additions
  streak: {
    current: number;
    last_active: string;  // ISO date
    longest: number;
  };
  xp: number;
  
  // V3 additions
  knowledge_components: Record<string, KnowledgeComponent>;
  review_queue: ReviewItem[];
}

interface KnowledgeComponent {
  topic: string;
  p_mastery: number;       // Bayesian KT estimate (0–1)
  fsrs_state: FSRSState;   // FSRS scheduling parameters
  last_reviewed: string;
  review_count: number;
}

interface ReviewItem {
  topic: string;
  due: string;             // ISO datetime
  priority: number;
}
```

---

## 4. Component Behaviour Specs

### `<edu-python>` + `<edu-python-loader>`

Pyodide is 6.4 MB with a 2–5 s cold start. Required behaviour:

1. `<edu-python-loader>` renders immediately with progress bar and "Booting Python runtime…" message
2. Pyodide loads via streaming instantiation (`loadPyodide({ indexURL })`)
3. Runtime is instantiated once per browser session and cached globally (`window.__pyodideRuntime`)
4. On subsequent lessons, `<edu-python>` checks for cached runtime before showing loader
5. `<edu-python>` exposes: code editor (CodeMirror 6), Run button, stdout/stderr output panel

### `<learn-hint>`

Three-tier hint system:

1. **Nudge:** Restates the question with emphasis on the key concept
2. **Clue:** Points to the relevant principle without giving the answer
3. **Answer:** Full worked solution with explanation

Each tier is revealed only after the user requests it. The current tier level is stored in lesson session state (not persisted to prefs.json — hints reset per lesson).

### `<learn-quiz>` (V2.2 extension of V1)

V2.2 extends the existing quiz with:
- Score tracking written to `.learn/prefs.json` → feeds FSRS scheduling in V3
- Per-question timing data (for knowledge tracing)
- MathLive input mode when `renderer: "math-input"` is set on the question

### `<learn-streak>`

Reads `.learn/prefs.json` streak data. Updates `last_active` on any lesson completion. Increments `streak.current` if last active was yesterday; resets to 1 if gap > 1 day. Displays as a `<wa-badge>` (Web Awesome) with flame icon and streak count.

---

## 5. Implementation Phases

### Phase V2 — Core Renderer System

Deliverables:
- `renderers[]` field added to Lesson JSON schema and `paidagogos:micro` skill
- `renderer-map.md` reference file for topic → renderer mapping
- lesson.html dynamic import logic
- Lit runtime added to lesson.html (Tier 0)
- `<edu-math>` — KaTeX
- `<edu-code>` — CodeMirror 6 replacing static Prism for interactive lessons
- `<edu-chart>` — Chart.js
- `<edu-geometry>` — JSXGraph
- `<edu-sim-2d>` — Matter.js
- Web Awesome CDN loader in lesson.html

Acceptance criteria:
- A trigonometry lesson renders a live JSXGraph diagram
- A statistics lesson renders a Chart.js histogram
- A JavaScript lesson has an editable CodeMirror 6 block
- Lessons without renderers work identically to V1 (no regressions)

### Phase V2.1 — Heavy Renderers

Deliverables:
- `<edu-python>` + `<edu-python-loader>` — Pyodide
- `<edu-sandbox>` — Sandpack JS live execution
- `<edu-scene-3d>` — Three.js + A-Frame
- `<edu-canvas>` — p5.js

Acceptance criteria:
- A pandas lesson runs Python in-browser with output rendered
- Pyodide loads once per session (verified by checking `window.__pyodideRuntime` reuse)
- A 3D geometry lesson shows an interactive Three.js scene

### Phase V2.2 — Pedagogy Layer

Deliverables:
- `<learn-hint>` — three-tier Socratic hints
- `<learn-progress>` — mastery indicator reading `.learn/prefs.json`
- `<learn-streak>` — habit tracking + XP
- `<learn-explain>` — Feynman explain-back (text input → `paidagogos:explain` skill call)
- Extended `.learn/prefs.json` schema (streak, xp, quiz scores)
- `paidagogos:explain` skill — evaluates user's explanation against expected concepts

Acceptance criteria:
- Completing 3 lessons in a row shows a streak badge
- Hint system reveals only one tier at a time
- Explain-back evaluates conceptual coverage, not exact wording

### Phase V3 — Adaptive Layer

Deliverables:
- FSRS-inspired review scheduling in `.learn/prefs.json`
- `paidagogos:recall` skill — retrieves due review items and generates review lesson
- `paidagogos:path` skill — dependency-ordered topic suggestions
- `<learn-quiz>` MathLive integration for mathematical answer input
- Knowledge component graph — per-topic mastery tracking (BKT-inspired)

Acceptance criteria:
- After 5 lessons on related topics, `paidagogos:recall` suggests a review session
- `paidagogos:path` recommends "learn X before Y" when knowledge gap detected
- Review scheduling intervals grow correctly over time

---

## 6. Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Web component framework | **Lit** | 5 KB, no build step, class-based, Google-backed |
| UI chrome library | **Web Awesome** | Shoelace successor, active development, free CDN core |
| Math display | **KaTeX** | Sub-ms rendering, 28 KB gz, no deps |
| Math computation | **Math.js** | 500+ functions, expression parser, CDN |
| Charts (default) | **Chart.js** | 65 KB gz, 8 types, responsive defaults |
| Charts (scientific) | **Plotly.js** | 40+ types, 3D surfaces, JSON-spec driven |
| 2D geometry | **JSXGraph** | MIT, self-hostable, drag-and-drop constraints |
| 2D physics | **Matter.js** (default) | Built-in renderer, mouse interaction, educational resources |
| 3D | **Three.js** | De facto standard, 112K stars, ESM CDN |
| Python WASM | **Pyodide** | Full CPython, NumPy/pandas, streaming instantiation |
| Code editor | **CodeMirror 6** | 93 KB gz, modular, accessible, mobile-friendly |
| JS playground | **Sandpack** | CodeSandbox bundler, used by react.dev |
| Component prefix (renderers) | **`<edu-[name]>`** | Portable across plugins, no plugin coupling |
| Component prefix (pedagogy) | **`<learn-[name]>`** | Plugin-scoped, can access `.learn/prefs.json` |
| Heavy WASM threshold | **500 KB** | Requires explicit loader state component |
| Pyodide session strategy | **Single global runtime** | `window.__pyodideRuntime` — load once, reuse across lessons |

---

## 7. Open Questions

The following are deferred design decisions, not blockers for V2:

1. **Import map vs component-owned CDN:** Should lesson.html maintain a central import map for all renderer versions, or should each `<edu-[name]>` component own its CDN URL? Central import map is easier to upgrade; component-owned is more portable. Recommend: central import map for V2, revisit at V2.1.

2. **A2UI formalisation:** The `renderers[]` + typed component JSON maps directly to the A2UI agent→surface model. At what point do we formalise this as an A2UI surface? V2 can stay pragmatic; V3 is the natural migration point.

3. **Desmos vs JSXGraph:** Desmos is CDN-only (no offline), JSXGraph is MIT and self-hostable. For offline use, JSXGraph is the safe default. Recommend: JSXGraph as default; offer Desmos as opt-in via renderer config `"library": "desmos"`.

4. **`paidagogos:explain` evaluation strategy:** The Feynman explain-back skill needs to evaluate semantic coverage, not exact wording. Options: (a) LLM eval inline in the skill, (b) structured rubric with expected concepts. Recommend: structured rubric for V2.2, upgrade to LLM eval when confidence is established.

---

## 8. Files Affected

### New files (V2)
```
plugins/paidagogos/server/components/renderers/edu-math.js
plugins/paidagogos/server/components/renderers/edu-chart.js
plugins/paidagogos/server/components/renderers/edu-code.js
plugins/paidagogos/server/components/renderers/edu-geometry.js
plugins/paidagogos/server/components/renderers/edu-sim-2d.js
plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md
```

### Modified files (V2)
```
plugins/paidagogos/server/templates/lesson.html    — dynamic renderer import + Web Awesome loader
plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md  — add renderers[] field
plugins/paidagogos/skills/paidagogos-micro/SKILL.md     — renderer classification logic
```

### New files (V2.1)
```
plugins/paidagogos/server/components/renderers/edu-python.js
plugins/paidagogos/server/components/renderers/edu-python-loader.js
plugins/paidagogos/server/components/renderers/edu-sandbox.js
plugins/paidagogos/server/components/renderers/edu-scene-3d.js
plugins/paidagogos/server/components/renderers/edu-canvas.js
```

### New files (V2.2)
```
plugins/paidagogos/server/components/pedagogy/learn-hint.js
plugins/paidagogos/server/components/pedagogy/learn-explain.js
plugins/paidagogos/server/components/pedagogy/learn-progress.js
plugins/paidagogos/server/components/pedagogy/learn-streak.js
plugins/paidagogos/skills/paidagogos-explain/SKILL.md
```

### Modified files (V2.2)
```
plugins/paidagogos/server/components/pedagogy/learn-quiz.js   — refactored from lesson.html inline
plugins/paidagogos/.claude-plugin/plugin.json                  — add paidagogos:explain skill
```

### New files (V3)
```
plugins/paidagogos/skills/paidagogos-recall/SKILL.md
plugins/paidagogos/skills/paidagogos-path/SKILL.md
```

---

## 9. Research Reference

Full renderer library research, WASM tier analysis, teaching styles taxonomy, and component pattern mappings are documented in:

`docs/plugins/paidagogos/research/rendering-and-pedagogy.md`
