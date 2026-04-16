# Paidagogos — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — Reuse superpowers visual server pattern

**Status:** Accepted

**Context:** The plugin needs a local browser surface to render lesson cards with syntax-highlighted code, interactive quiz, and dark/light mode. Building a new server from scratch adds maintenance surface, setup friction, and implementation time.

**Decision:** Reuse the superpowers visual companion server pattern exactly — file-watcher, `screen_dir` / `state_dir`, HTML fragment writes. `server/start-server.sh` and `server/server.js` follow the same conventions as the superpowers companion.

**Consequences:** Zero reinvention. The server pattern is already proven in production. Contributors familiar with superpowers can modify the paidagogos server without a learning curve. The constraint is that the pattern must not diverge from superpowers — any upgrade to the shared pattern must be applied to both.

---

## D-02 — One-shot Lesson JSON generation

**Status:** Accepted

**Context:** Lesson content could be generated section by section (concept first, then example, then quiz) allowing course-correction between steps. Alternatively, the full `Lesson` JSON can be generated in a single prompt.

**Decision:** One-shot. `paidagogos:micro` generates the complete `Lesson` JSON in a single Claude call against a strict typed schema. No iterative assembly. No inter-step state.

**Consequences:** Fewer failure points — there is no partial-lesson state to recover from. Claude JSON output is reliable with a clearly specified schema. The trade-off is that if one section is poor, the whole lesson regenerates rather than just that section. This is acceptable in V1; section-level regeneration is a V2+ concern.

---

## D-03 — Quiz default ON with opt-out

**Status:** Accepted

**Context:** A quiz could be opt-in (user requests it) or opt-out (always present, user skips). Opt-in is safer — the user is never surprised. Opt-out maximises learning value by default.

**Decision:** Quiz is default ON. Users opt out, not in. The quiz is part of the lesson structure, not an add-on.

**Consequences:** Every lesson delivered through `paidagogos:micro` includes 3 questions unless the user explicitly skips. This aligns with evidence-based pedagogy (retrieval practice improves retention). The trade-off is that users who only want a quick reference explanation must explicitly opt out — accepted, because the target use case is learning, not lookup.

**Trade-off rejected:** Opt-in quiz. Would result in most users never attempting the quiz, undermining the plugin's core value proposition.

---

## D-04 — File-based progress in V2, not V1 (session-only in V1)

**Status:** Accepted

**Context:** Persisting lesson history, quiz scores, and expertise level across sessions would make the plugin significantly more valuable. However, a progress file system adds schema decisions, migration concerns, and purge UX that are out of scope for a V1 demo.

**Decision:** V1 is session-only. No lesson history, no quiz score persistence, no cross-session expertise level memory. Expertise level defaults to `intermediate` on each new session unless the user states it inline. File-based progress (`paidagogos:recall`, expertise persistence) ships in V2.

**Consequences:** V1 is demo-able and publishable without a data layer. Every session starts fresh — no stale state, no migration risk. The trade-off is that users must re-state their expertise level each session, which is a friction point accepted for V1 scope.

---

## D-05 — Lesson template order: Concept → Why → Example → Common mistakes → Generate → Quiz

**Status:** Accepted

**Context:** The teaching flow could be ordered many ways. Starting with examples is common in programming tutorials. Starting with the quiz forces recall before instruction (test-enhanced learning). Starting with the concept is the most conventional ordering.

**Decision:** Fixed template order: Concept → Why → Example → Common mistakes → Generate task → Quiz → Next. This order is mandatory — skills must not reorder or make sections optional (except quiz, which is user-opt-out only).

**Consequences:** The order follows a deliberate progression: understand → motivate → see it → avoid pitfalls → apply it → prove it. Common mistakes before the generate task means the user has been pre-empted on the most likely errors before they attempt the challenge. The fixed order also makes the lesson card layout deterministic, which simplifies the HTML template.

**Trade-off rejected:** Example before Concept. Code-first ordering is appealing for experienced developers but loses beginners who have no mental model to attach the example to.

---

## D-06 — Knowledge vault integration via file-read only in V1

**Status:** Accepted

**Context:** The knowledge vault (`knowledge/`) contains 500+ tool and methodology guides. Integrating them into lessons could mean: (a) prompt-stuffing full entries into context, (b) a runtime vault API, or (c) reading category index files to extract URLs and summaries.

**Decision:** File-read only. `paidagogos:micro` reads `knowledge/{category}/_index.md` to find matching `detailed` entries and uses their URLs and summaries as resource links. `stub` entries are skipped. Full vault entry content is never loaded into lesson context. No runtime API in V1.

**Consequences:** Resource links in lessons are grounded in the knowledge vault without context cost. The constraint is that only `detailed` entries are usable — stubs produce no vault resource and fall back to LLM-generated links (marked `AI-suggested, verify link`). This is the correct trade-off: stubs have insufficient content to be useful, and prompt-stuffing full entries would blow the context budget.

**Trade-off rejected:** Prompt-stuffing full vault entries. For a lesson on a topic covered by a 2,000-word vault entry, this would consume significant context for marginally better resource descriptions.

---

## D-07 — Scope classifier threshold: >3 sub-concepts → ask user before routing

**Status:** Accepted

**Context:** The `/paidagogos` router must decide when a topic is too broad for `paidagogos:micro` and should offer a learning path instead. Any threshold is a heuristic — the question is where to draw it.

**Decision:** If the topic contains more than 3 distinct sub-concepts, the router asks the user: "This is a broad topic. Do you want a full roadmap or one focused concept to start with?" It never silently routes to path (V2+). In V1, the only outcome of "full roadmap" is a clarifying message and a prompt to narrow the topic.

**Consequences:** The threshold of 3 sub-concepts catches broad topics ("teach me machine learning", "teach me React") without catching reasonably scoped ones ("teach me CSS flexbox", "explain closures"). It keeps `paidagogos:micro` as the primary path for the vast majority of plausible inputs. False positives (a topic incorrectly flagged as broad) result in one extra user interaction, not a broken lesson. The trade-off is that the sub-concept count is Claude's judgment call — it is not a deterministic classifier. This is acceptable for V1; a formal scope taxonomy is a V2 consideration.

**Trade-off rejected:** Always route single-word topics to `paidagogos:micro`. Too coarse — "teach me ML" is a single-word topic that would produce a useless lesson if forced into `paidagogos:micro` without scoping.

---

## D-08 — Two-layer component model: `<edu-[name]>` vs `<learn-[name]>`

**Status:** Accepted (V2)

**Context:** V2 introduces interactive renderers (math, charts, code, geometry, physics). We needed to decide whether to give them plugin-scoped names (`<paidagogos-math>`) or broader names, and how to separate subject-domain rendering from plugin-specific pedagogy.

**Decision:** Two prefixes with a hard boundary. `<edu-[name]>` for subject-domain renderers (`edu-math`, `edu-chart`, `edu-code`, `edu-geometry`, `edu-sim-2d`) — pure display/interaction, no plugin state, no skill awareness, no `.paidagogos/prefs.json` access. `<learn-[name]>` for pedagogy components (quiz, hint, progress, streak in V2.2) — plugin-scoped, can read plugin state, tied to the learn lifecycle.

**Consequences:** Component files live in two directories (`components/renderers/`, `components/pedagogy/`). The boundary is enforced by naming — any `<edu-[name]>` that reads plugin-specific state is a lint violation. Renderers are portable: a future tutoring plugin can reuse `<edu-math>` without dragging paidagogos state with it.

**Trade-off rejected:** Single prefix (`<paidagogos-[name]>`). Would tie renderers to the plugin name, blocking reuse. A future rename of the plugin would cascade to every component.

---

## D-09 — Lit 3 for web components, CDN ESM only

**Status:** Accepted (V2)

**Context:** Need a web component framework. Candidates: Lit, Stencil.js, Svelte, Microsoft FAST, vanilla custom elements. The existing lesson.html uses string-based innerHTML with no build step.

**Decision:** Lit 3.x, loaded per-component via ESM imports from `esm.sh/lit@3.2.1`. `lesson.html` issues a single `<link rel="modulepreload">` so the runtime is warm by the time the first renderer imports it. The browser dedupes identical module URLs, so all 5 renderers share one Lit instance.

**Why not a global `window.__lit`:** The initial V2 design exposed Lit as `window.__lit` from an inline `<script type="module">` in `lesson.html`, and renderers read `const { LitElement, html, css } = window.__lit`. Two problems surfaced during browser verification: (1) jsdelivr's `/npm/lit@3/index.js` contains bare module specifiers (`@lit/reactive-element`) that the browser cannot resolve without an import map, so the inline script failed silently; (2) even when the URL was fixed, a race existed between the inline module script finishing and the first renderer's top-level destructuring — `window.__lit` was `undefined` at import time. Switching to per-component ESM imports removed both failure modes and is more architecturally coherent (renderers are already ES modules — they should import their dependencies like any other ES module).

**Consequences:** 5 KB gzipped runtime amortised via module dedup, no build pipeline. Components drop into `/components/renderers/` as plain `.js` ES modules served by the existing HTTP server. Class-based authoring matches existing JS patterns. All renderers use light DOM (see the per-component rationale in each file) — Shadow DOM would trap external CSS (KaTeX, highlight.js) and break libraries that rely on `document.getElementById` (JSXGraph). No compile step means upgrades are drop-in CDN URL changes (currently hardcoded as `3.2.1` in each renderer + `lesson.html` preload — bumping requires editing six files but keeps the version visible at each use site).

**Trade-off rejected:** Stencil.js or Svelte with a build pipeline. Would add build tooling (npm, bundler, watch mode) with no clear payoff over Lit's drop-in CDN approach. Vanilla custom elements rejected because reactive properties + template DX would have been rebuilt by hand.

---

## D-10 — Web Awesome for UI chrome (Shoelace is sunset)

**Status:** Accepted (V2)

**Context:** Need prebuilt UI components for progress bars, tabs, dialogs, badges, tooltips. Shoelace was the obvious candidate historically.

**Decision:** Web Awesome 3.x via CDN autoloader (`ka-f.webawesome.com/webawesome@3.5.0/webawesome.loader.js`). Web Awesome is the direct successor to Shoelace (same author, same API philosophy). Shoelace is officially sunset — no active development, issues, or features. Web Awesome has 50+ components with a free CDN core tier.

**Consequences:** `lesson.html` loads the Web Awesome loader in `<head>`. Components load on first use only (autoloader pattern). Pro-tier components are opt-in and paid; we use free core only. No build step.

**Trade-off rejected:** Fork Shoelace ourselves. Shoelace is MIT-licensed and forkable, but we gain nothing over Web Awesome except a maintenance burden. Web Awesome is the upstream continuation of the same codebase.

---

## D-11 — `renderers[]` in Lesson JSON drives lazy loading

**Status:** Accepted (V2)

**Context:** Different lessons need different renderers. Loading every renderer on every page blocks the page, wastes bandwidth (~500 KB gz total across the V2 set), and scales poorly as the renderer set grows in V2.1/V2.2.

**Decision:** Lesson JSON includes a required `renderers: RendererKey[]` field. `lesson.html` reads it and dynamically imports only the listed modules via `await Promise.all(keys.map(k => import(RENDERER_MODULES[k])))`. `paidagogos:micro` populates the array using the keyword table in `renderer-map.md`.

**Consequences:** A CSS lesson never loads Three.js. Base payload stays minimal (Lit 5 KB + Web Awesome loader + existing page). Adding a new renderer requires a four-step extension: (a) component file under `components/renderers/`, (b) entry in `RENDERER_MODULES` in lesson.html, (c) keyword row in `renderer-map.md`, (d) V2 set expanded in `lesson-schema.md`. Missing an entry fails loudly — the component won't load and the console shows the missing module URL.

**Trade-off rejected:** Infer renderers at runtime from lesson content (e.g., detect LaTeX patterns in the concept text). Fragile, ambiguous, and couples rendering to content heuristics instead of explicit declarations.
