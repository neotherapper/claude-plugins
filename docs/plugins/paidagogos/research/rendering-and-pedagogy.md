# Learn Plugin — Rendering & Pedagogy Research

> Research synthesis for the learn plugin v2+ architecture.  
> Compiled from the nikai knowledge vault (developer-tools/frontend + edtech + methodologies).  
> Informs the modular component renderer design and teaching style integration.

---

## 1. Teaching Styles Taxonomy

Six evidence-based teaching patterns extracted from the best EdTech platforms. Each maps to a component pattern in the learn plugin.

| # | Teaching Style | Platform Origin | Core Mechanism | Evidence Strength |
|---|---|---|---|---|
| **TS-1** | Visual / Conceptual | Brilliant | Parameter sliders + animated diagrams build intuition before formalism | Strong (constructivism research) |
| **TS-2** | Active Recall | Anki, Brilliant | Forced retrieval before answer reveal; spacing optimised per forgetting curve | Gold standard (FSRS, SM-2; +10-20% retention over passive study) |
| **TS-3** | Learn-by-Doing | Codecademy, Scrimba | Execute code immediately; feedback loop <5 seconds; no context switch | Proven at 50M+ scale |
| **TS-4** | Mastery-based | Khan Academy, Carnegie Learning | Advance only when P(mastery) ≥ 0.95; ~700 skill components per domain | RCT evidence: +8 percentile points; d=0.36 effect size |
| **TS-5** | Socratic / Guided Discovery | Khanmigo | Never give the answer; ask guiding questions; preserve productive struggle | Strong (Khanmigo GPT-4 + pedagogical guardrails) |
| **TS-6** | Spaced Repetition | Anki, Duolingo | Review items just before forgetting; FSRS algorithm (19 params, 10-20% better than SM-2) | Gold standard (86% of US medical students; 2-4x retention vs. traditional) |
| **TS-7** | Feynman / Explain-back | — | User explains concept in own words; AI evaluates depth not exact wording | Strong cognitive science basis |
| **TS-8** | Gamification / Habit | Duolingo | Streaks, variable rewards, daily goals drive consistency over depth | Validated at 116.7M MAU, 34.7% DAU/MAU ratio |

**Key insight from pedagogy research:**  
Scrimba's core innovation — eliminating context-switching friction between watching and coding — is the single clearest UI pattern for technical education. Any rendering approach that keeps the learner in one surface beats one that requires jumping between tabs.

---

## 2. Subject Domain → Renderer Map

### 2.1 Mathematics

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| Equation display | **KaTeX** | 90 | 28 KB gz | ✅ | Sub-ms rendering, no deps. Use for all inline/block math. |
| Full LaTeX coverage | MathJax | 85 | 100 KB gz | ✅ | 10–100× slower than KaTeX. Only if KaTeX gaps matter. |
| Student math input | **MathLive** | 78 | 200 KB gz | ✅ | Interactive editor; virtual keyboard; mobile-friendly. Use for assessments. |
| Interactive 2D geometry | **JSXGraph** | 72 | 85 KB gz | ✅ | Drag points, live constraints, sliders. 15 years, academic backing. |
| Graphing calculator | **Desmos API** | 80 | 500 KB | ✅ | Students already know the interface. Proprietary/CDN-only. |
| Full K-12/uni platform | GeoGebra | 82 | 2 MB | ✅ | Geometry + algebra + calculus + 3D. Heavy. Only when depth needed. |
| Symbolic computation | **Math.js** | 85 | 180 KB gz | ✅ | 500+ functions, expression parser. Computation engine, pairs with KaTeX for display. |
| Symbolic algebra (CAS) | Algebrite | 60 | 250 KB gz | ✅ | Derivatives, integrals, factoring in-browser. Single maintainer. |

**Recommended combination for a maths lesson:**  
KaTeX (display) + Math.js (computation) + JSXGraph (interactive geometry) — all CDN, no build step, total ~290 KB gz on demand.

---

### 2.2 Physics & Simulation

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| 2D physics (approachable) | **Matter.js** | 75 | 80 KB gz | ✅ | Built-in renderer + mouse drag. Best for beginners. 18K stars. |
| 2D physics (accurate) | Planck.js | 72 | 50 KB gz | ✅ | Box2D port, 11 joint types, CCD. No built-in renderer. |
| 2D physics (performant) | Rapier.js | 82 | 1–3 MB WASM | ✅ | 2–5× faster than Matter.js. WASM payload cost. |
| 3D physics | cannon-es | 68 | 75 KB gz | ✅ | Pairs with Three.js. Declining maintenance; acceptable for education. |
| 3D scene + physics | **Three.js + cannon-es** | 97+68 | 155+75 KB gz | ✅ (ESM) | De facto standard. See 3D section. |
| Box2D faithful (WASM) | box2d-wasm | 62 | 161 KB | ✅ | Lightweight WASM (~161 KB). C-style API is verbose. |

**Recommendation:** Matter.js for beginner-level physics lessons (gravity, collisions, springs); Rapier.js when accuracy or performance is the lesson's point.

---

### 2.3 Data, Charts & Statistics

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| Standard charts (simple) | **Chart.js** | 90 | 65 KB gz | ✅ | 8 types, responsive by default, sensible defaults. Most downloaded. |
| Scientific / 3D charts | **Plotly.js** | 82 | ~1 MB | ✅ | 40+ types incl. 3D surfaces and scientific plots. JSON spec-driven. |
| Bespoke / custom viz | **D3.js** | 97 | 75 KB gz | ✅ | SVG + Canvas primitives. Steepest curve; limitless output. |
| Grammar of graphics (declarative) | Vega-Lite | 78 | 400 KB gz | ✅ | JSON spec portable across Python/R/JS. AI-generation-friendly. |
| Exploratory stats | Observable Plot | 75 | 90 KB gz | ✅ | From D3 team. Concise, statistical marks built-in. v0.x still. |
| Animated / polished | ApexCharts | 80 | 130 KB gz | ✅ | Best defaults; SVG. Single-maintainer risk. |
| Enterprise/large dataset | ECharts | 91 | 330 KB gz | ✅ | Canvas+SVG dual render; 1M+ points; Apache governance. |

**Recommendation:**  
- Default to **Chart.js** for standard lesson charts (histograms, line graphs, scatter plots)  
- Use **Plotly.js** for science/stats lessons needing 3D plots or box plots  
- Reserve **D3.js** for lessons where the visualisation IS the concept (e.g., teaching sorting algorithms, graph traversal)

---

### 2.4 Coding & Computer Science

| Need | Best option | Score | Bundle | Notes |
|---|---|---|---|---|
| Syntax highlighting | **Prism.js** | 78 | 2 KB core | Already in use. 297+ languages. |
| VS Code quality highlighting | Shiki | 85 | 695 KB | TextMate grammars. Best for build-time; heavy for runtime. |
| Live code editor (lightweight) | **CodeMirror 6** | 88 | 93 KB gz | Modular, accessible, mobile. Best standalone editor. |
| Full IDE in browser | Monaco Editor | 92 | 2–4 MB | VS Code engine. IntelliSense. Only when editing experience is the lesson. |
| Run JS/TS/React live | **Sandpack** | 80 | ~300 KB | CodeSandbox bundler in iframe. Used by react.dev. React-first. |
| Run Python live | **Pyodide** | 88 | 6.4 MB core | Full CPython + NumPy/pandas in WASM. 2–5 s cold start. Streaming instantiation. |
| Algorithm visualisation | **p5.js** | 82 | 280 KB gz | Gold standard for creative coding education. editor.p5js.org available. |
| Data structure viz | D3.js | 97 | 75 KB gz | Custom force graphs, trees, linked structures. |

**Recommendation:**  
Keep Prism.js for static code display. Add CodeMirror 6 for interactive editing. Add Sandpack for JS lesson playgrounds. Add Pyodide for data science/Python lessons — but lazy-load with explicit loading state ("Booting Python runtime… ~6 seconds").

---

### 2.5 3D (Geometry, Molecular, Architecture, Physics)

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| Any 3D scene | **Three.js** | 97 | 155 KB gz | ✅ (ESM) | 112K stars. De facto standard. React Three Fiber ecosystem. |
| Batteries-included 3D engine | Babylon.js | 92 | 500 KB gz | ✅ | Built-in physics, GUI, audio, inspector. MS backing. |
| HTML-first 3D / VR | **A-Frame** | 78 | 80 KB gz | ✅ | Declarative HTML (`<a-scene>`). No JS needed for basic scenes. Best for lessons where 3D IS incidental. |
| Visual-editor 3D | Spline | 72 | 500 KB | Partial | Proprietary format. Designer workflow. Not programmatic. |

**Recommendation:**  
- A-Frame for lessons where 3D context is illustrative (show a 3D shape, not model it)  
- Three.js for any lesson where 3D is interactive or scientifically significant (orbital mechanics, molecular structures, geometric proofs)

---

### 2.6 Music & Audio

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| Audio synthesis / music theory | **Tone.js** | 82 | 130 KB gz | ✅ | 20+ synths, BPM transport, musical time notation. |
| Waveform / phonetics / speech | **Wavesurfer.js** | 78 | 12 KB gz | ✅ | Spectrogram, regions, waveform scrubbing. Very light. |

**Lessons unlocked:** Music theory (intervals, chords, scales), phonetics, signal processing basics, acoustic physics, language pronunciation.

---

### 2.7 Animation & Explanation

| Need | Best option | Score | Bundle | CDN | Notes |
|---|---|---|---|---|---|
| Concept animation (CSS/DOM) | **GSAP** | 95 | 24 KB gz | ✅ | All plugins now free. Industry standard since 2006. |
| Lightweight animation (MIT) | Anime.js | 78 | 17 KB gz | ✅ | Single maintainer risk. v4 breaking changes. |
| Interactive state-machine animation | **Rive** | 82 | 60 KB gz | ✅ (WASM) | `.riv` format; branching interactive animations. Proprietary editor. |
| Designer-handoff animations | Lottie Web | 80 | 30–60 KB gz | ✅ | After Effects → JSON → browser. 100K+ pre-made assets. |
| React-native animations | Motion | 90 | 27 KB (4.6 KB lazy) | Partial | React-only. Not applicable to Lit architecture. |

---

## 3. Web Component Framework Decision

### Candidates

| Framework | Score | Bundle | Build step | Shadow DOM | Lazy load | Notes |
|---|---|---|---|---|---|---|
| **Lit** | 92 | **5 KB gz** | No | Optional | Via directives | Google-backed; YouTube uses it; class-based; reactive properties; 20.6K stars |
| Stencil.js | 82 | 3–8 KB/component | Yes | Optional | Built-in | Ionic-backed; multi-framework output; overkill for single app |
| Microsoft FAST | 68 | 10 KB | No | Yes | Limited | Uncertain roadmap; enterprise-focused |
| Svelte | 78 | 2–4 KB runtime | Yes | Optional | Not standard for WC | Compiler; best DX but build step required |

**Decision: Lit.**

Reasons:
1. 5 KB total runtime — negligible cost
2. No build step — drop a `<script type="module">` into lesson.html, define components inline
3. Class-based authoring matches the existing JS patterns in lesson.html
4. Shadow DOM optional — CSS custom properties (already used in lesson.html) flow through
5. Google uses it at YouTube and Chrome DevTools scale
6. v3.0 stable, long-term commitment clear

### Prebuilt Component Library

**Web Awesome** for UI chrome: modal dialogs, tooltips, badges, progress bars, tab panels.

Web Awesome is the direct successor to Shoelace (same author, same API philosophy). Shoelace is officially sunset — no active development, issues, or features. Web Awesome is the active project with 50+ components, 20+ utilities, 10+ themes, and a free CDN tier:

```html
<script type="module" src="https://ka-f.webawesome.com/webawesome@3.5.0/webawesome.loader.js"></script>
```

CDN autoloader means components load only when used. Dual-license: free core (MIT-equivalent) + Pro tier for advanced components. No build step required.

---

## 4. WASM Strategy

Three tiers of WASM usage, by payload cost:

### Tier A — Light WASM (< 200 KB)
- **Shiki**: TextMate grammar parser via Oniguruma WASM. Used at build time, not runtime.
- **Box2D WASM**: 161 KB. Simple physics for introductory lessons.
- **Rive runtime**: 60–90 KB. Interactive animations.

### Tier B — Medium WASM (200 KB – 2 MB)
- **Rapier.js 2D**: 1–2 MB. Accurate physics simulations.
- **Algebrite**: 250 KB. Symbolic algebra in-browser.

### Tier C — Heavy WASM (> 2 MB) — explicit loading state required
- **Pyodide**: 6.4 MB core. Full Python runtime. 2–5 s cold start.
  - Use streaming instantiation (`loadPyodide({ indexURL })`)
  - Show explicit loading state: `<edu-python-loader>` component
  - Only instantiate once per session; cache the runtime across lessons
  - Only load for Python/data science lessons
- **GeoGebra**: ~2 MB. Only when full platform needed.

**Rule:** Any WASM payload over 500 KB requires a `<edu-[X]-loader>` component that shows load state before mounting the renderer.

---

## 5. Modular Architecture: The Component Registry

### 5.1 Component Naming Convention

Two prefixes, two concerns:

**`<edu-[name]>` — portable renderer catalog**  
Subject-domain renderers. No pedagogy logic. Usable in any plugin or standalone page.

```
<edu-math>          — KaTeX display
<edu-math-input>    — MathLive editor
<edu-geometry>      — JSXGraph interactive geometry
<edu-graph>         — Desmos graphing calculator
<edu-chart>         — Chart.js / Plotly.js charts
<edu-code>          — Prism.js / CodeMirror static or editable code
<edu-sandbox>       — Sandpack live JS/TS execution
<edu-python>        — Pyodide Python execution (with loader)
<edu-scene-3d>      — Three.js / A-Frame 3D scene
<edu-sim-2d>        — Matter.js 2D physics simulation
<edu-canvas>        — p5.js creative coding canvas
<edu-audio>         — Tone.js + Wavesurfer.js audio
<edu-animate>       — GSAP / Rive animation
```

**`<learn-[name]>` — plugin-specific pedagogy components**  
Pedagogy interactions. Know about `.learn/prefs.json`, skills, and lesson state. Tied to the learn plugin.

```
<learn-quiz>        — existing quiz component (extend)
<learn-explain>     — Feynman explain-back
<learn-hint>        — Socratic hint system (three-tier: nudge → clue → answer)
<learn-progress>    — mastery and path indicator
<learn-streak>      — habit/gamification layer
```

The `renderers[]` array in the Lesson JSON refers to `<edu-[name]>` keys only.

### 5.2 Lesson JSON Extension

Add a `renderers` array to the Lesson JSON schema (alongside existing fields):

```json
{
  "topic": "Fourier Series",
  "level": "intermediate",
  "renderers": ["katex", "chart"],
  "example": {
    "type": "chart",
    "renderer": "chart",
    "config": {
      "library": "chartjs",
      "chart_type": "line",
      "data": { ... }
    }
  },
  "concept": "...",
  "why": "...",
  ...
}
```

The `renderers` array lists every renderer the lesson needs. lesson.html reads this array on load and lazy-imports only those components. A lesson with `"renderers": ["code"]` never loads Three.js.

### 5.3 Renderer Tiers (Load Strategy)

| Tier | Components | Load strategy |
|---|---|---|
| **0 — Always** | Lit runtime (5 KB), Prism.js (2 KB) | Bundled in lesson.html |
| **1 — Light** | KaTeX, Chart.js, Anime.js, Wavesurfer.js, Matter.js | Dynamic import on demand, <100 KB each |
| **2 — Medium** | Three.js, CodeMirror 6, D3.js, JSXGraph, Observable Plot | Lazy import, 75–155 KB gz |
| **3 — Heavy** | Plotly.js, Pyodide, Monaco Editor, GeoGebra | Explicit load state component, >400 KB |

### 5.4 How learn:micro Drives the Registry

`learn:micro` classifies the topic and populates `renderers[]` in the Lesson JSON:

```
Topic: "CSS Flexbox"       → renderers: ["code"]
Topic: "Trigonometry"      → renderers: ["katex", "geometry"]
Topic: "Fourier Series"    → renderers: ["katex", "chart"]
Topic: "Sorting Algorithms"→ renderers: ["code", "canvas"]
Topic: "Orbital Mechanics" → renderers: ["scene-3d", "sim-2d"]
Topic: "Python pandas"     → renderers: ["code", "python"]
Topic: "Music Intervals"   → renderers: ["audio"]
Topic: "Newton's Laws"     → renderers: ["sim-2d", "chart"]
Topic: "Molecular Bonds"   → renderers: ["scene-3d"]
```

The skill reads a `renderer-map.md` reference file (similar to `vault-integration.md`) to make this mapping deterministic.

---

## 6. Teaching Style → Component Pattern

This maps pedagogical patterns to specific component behaviours:

| Teaching Style | Component Pattern | Implementation |
|---|---|---|
| **TS-1 Visual/Conceptual** | Parameter sliders that update renderer in real time | JSXGraph sliders / D3 linked to `<learn-geometry>` or `<learn-chart>` |
| **TS-2 Active Recall** | Quiz with immediate explanation | `<learn-quiz>` (existing) — extend with score tracking |
| **TS-3 Learn-by-Doing** | Editable code with live output | `<learn-sandbox>` (Sandpack/Pyodide) |
| **TS-4 Mastery-based** | Concept prerequisites unlocked progressively | `<learn-progress>` reads `.learn/prefs.json` |
| **TS-5 Socratic** | Hint system that guides without revealing | `<learn-hint>` — three-tier hints (nudge → clue → answer) |
| **TS-6 Spaced Repetition** | Review scheduling based on quiz history | `learn:recall` reads `state_dir/events` to schedule repeats |
| **TS-7 Feynman** | Free-text input + AI evaluation | `<learn-explain>` posts to `/explain-eval` or calls skill inline |
| **TS-8 Gamification** | Streak badge, XP, daily goal indicator | `<learn-streak>` reads `.learn/prefs.json` streak data |

---

## 7. Recommended Stack by Phase

### V1 (current — no changes needed)
Prism.js, vanilla quiz, SSE auto-reload. Already implemented.

### V2 — Core Renderer System
Add to lesson.html:
- Lit runtime (5 KB, no build step)
- `renderers[]` field in Lesson JSON schema
- `<learn-math>` — KaTeX (28 KB gz)
- `<learn-code>` — CodeMirror 6 (93 KB gz, replaces static Prism for interactive lessons)
- `<learn-chart>` — Chart.js (65 KB gz)
- `<learn-geometry>` — JSXGraph (85 KB gz)
- `<learn-sim-2d>` — Matter.js (80 KB gz)

All CDN, no build step. Total additional weight: ~350 KB gz loaded on demand.

### V2.1 — Heavy Renderers
- `<learn-python>` — Pyodide with loader state
- `<learn-sandbox>` — Sandpack for JS lessons
- `<learn-scene-3d>` — Three.js + A-Frame
- `<learn-canvas>` — p5.js

### V2.2 — Pedagogy Layer
- `<learn-hint>` (Socratic hints)
- `<learn-progress>` + `.learn/prefs.json` schema
- `<learn-streak>` + habit tracking
- `<learn-explain>` (Feynman technique — ties to `learn:explain` skill)

### V3 — Adaptive Layer
- `<learn-recall>` with FSRS-inspired scheduling
- Knowledge component graph in `.learn/prefs.json`
- `learn:path` skill with dependency ordering
- Optional: `learn:quiz` standalone mode

---

## 8. Open Questions for Architecture Design

1. **Renderer isolation:** Should each `<learn-X>` component fully own its CDN import, or should lesson.html maintain a central import map? Central import map is cleaner; component-owned is more portable.

2. **Pyodide session management:** Pyodide runtime (~6.4 MB) should be initialised once and shared across lessons in the same browser session. Design: single Pyodide worker shared via `SharedArrayBuffer` or `BroadcastChannel`.

3. **A2UI alignment:** The `renderers[]` + typed component JSON maps directly to A2UI's surface/component model. At what point do we formalise this as an A2UI surface? V2 can stay pragmatic; V3 is a natural migration point.

4. **Desmos vs JSXGraph:** Desmos is proprietary (CDN-only, no offline). JSXGraph is MIT and self-hostable. For a plugin that must work offline, JSXGraph is the safe default; Desmos is the better UX when CDN is available.

5. **MathLive vs custom quiz input:** For assessments that require mathematical answers (not just text), MathLive is the only viable option. Standard `<input>` cannot accept LaTeX. This affects the `<learn-quiz>` component design.

6. **p5.js vs PixiJS for algorithm visualisation:** p5.js has far better educational resources (The Coding Train, editor.p5js.org) but is heavier and slower than PixiJS. For algorithm visualisations (sorting, pathfinding), p5.js is the right choice. PixiJS is for sprite-heavy interactive simulations.

---

## 9. Sources

All data sourced from nikai knowledge vault — `/knowledge/developer-tools/frontend/` and `/knowledge/edtech/` and `/knowledge/methodologies/`.

| Category | Entries read |
|---|---|
| Math / Science | KaTeX, MathJax, MathLive, JSXGraph, Desmos API, GeoGebra, Math.js, Algebrite |
| Physics | Matter.js, Rapier.js, Box2D WASM, cannon-es, Planck.js |
| WASM | Pyodide, Emscripten, wasm-bindgen, AssemblyScript |
| Audio | Tone.js, Wavesurfer.js |
| Visualization | D3.js, Chart.js, Plotly.js, ECharts, Vega-Lite, Observable Plot, ApexCharts |
| 2D Graphics | PixiJS, p5.js, Paper.js, Konva.js, Fabric.js, Two.js |
| 3D | Three.js, Babylon.js, A-Frame, PlayCanvas, Spline |
| Animation | GSAP, Anime.js, Motion, Rive, Lottie Web |
| Web Components | Lit, Stencil.js, Microsoft FAST, Web Awesome (Shoelace successor), Spectrum WC, Carbon WC, Svelte, Material Web, Ionic, Vaadin, Wired Elements |
| Code Editors | Prism.js, Highlight.js, Shiki, Monaco Editor, CodeMirror 6, Sandpack |
| EdTech Platforms | Duolingo, Brilliant, Khan Academy, Anki, Codecademy, DataCamp, Educative, Scrimba, Carnegie Learning |
| Methodologies | Spaced Repetition Algorithms (FSRS/SM-2), Knowledge Tracing (BKT/DKT), Adaptive Learning Systems, Item Response Theory |
