# Visual-Kit — Architectural Decisions

ADR-style log of load-bearing decisions.

---

## D-01 · Library plugin via plugin.json dependencies (not MCP server)

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** Multiple plugins (paidagogos, namesmith, draftloom) need visual rendering. Claude Code v2.1.110+ supports `dependencies[]` in `plugin.json`; the canonical pattern in Anthropic docs is a "library plugin" exposing shared capability to dependents. MCP-UI is an emerging alternative, but Claude Code CLI is not listed as an MCP-UI host.

**Decision.** visual-kit ships as a first-class plugin in the marketplace. Consumers declare `{ "name": "visual-kit", "version": "~1.0.0" }` in their `dependencies[]`. Seam is runtime only — `bin/visual-kit` on PATH plus HTTP endpoints on localhost. No filesystem coupling.

**Consequences.** Version resolution works via marketplace git tags (`visual-kit--v1.0.0`). Consumers' plugin.json grows one entry. No MCP handshake overhead. MCP-UI remains a V3 path (UIResource wrapping) without blocking V1.

---

## D-02 · Single `<vk-*>` prefix; no `<edu-*>` / `<learn-*>` split

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** The paidagogos V2 spec proposed two prefixes — `<edu-*>` for portable renderers and `<learn-*>` for pedagogy components. The split was justified by "`<learn-streak>` reads `.paidagogos/prefs.json`."

**Decision.** Collapse to a single `<vk-*>` prefix. All components are pure: data in via attributes/slots, events out. No component reads plugin state; evaluation and persistence live in consuming plugins.

**Consequences.** A `<vk-streak>` in namesmith (writing streaks) reuses the same component paidagogos uses for lesson streaks. Plugin-specific state stays in the plugin. CI enforces purity (`scripts/lint-pure-components.mjs` blocks `fetch`, `localStorage`, cross-module reads from components).

---

## D-03 · SurfaceSpec JSON contract, not raw HTML (except `free`)

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** Three candidate contracts: typed JSON → server renders (paidagogos's current pattern), raw HTML fragment → server wraps (superpowers' brainstorming pattern), or a hybrid. Typed JSON gives schema validation and no HTML-escape bugs but couples consumers to a renderer menu; raw HTML is maximally flexible but unsafe under LLM content.

**Decision.** Typed SurfaceSpec JSON as the primary contract — six V1 surfaces (lesson, gallery, outline, comparison, feedback, free). `free` is an escape hatch that accepts raw HTML; it is safe because (a) the page-level CSP forbids inline script, and (b) the server DOMPurifies the payload.

**Consequences.** Adding a new layout usually means adding a surface to visual-kit, not a feature to consumers. Consumers write structured data, not markup. Composite surfaces are explicitly shared — every consumer gets gallery, outline, comparison for free.

---

## D-04 · Per-workspace server lifecycle (not global singleton)

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** Reviewer feedback called out that a global "one visual-kit server for the machine" architecture is fragile: two Claude Code sessions, two worktrees, or shared dev boxes all collide. CWD ambiguity makes event routing non-deterministic.

**Decision.** Port is derived from `sha256(absolute workspace path)` offset into `[20000, 60000)`. Advisory lock at `<workspace>/.visual-kit/server/state/server.lock`. Atomic `server-info` via `tmp + rename`. Live PID probe before attaching. Auto-increment port on collision.

**Consequences.** Multiple workspaces run independent servers concurrently. Restart is idempotent — `visual-kit serve` either boots or attaches. Workspace identity is the project's absolute path.

---

## D-05 · v2-renderers branch preserved as reference, not merged

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** The `feat/paidagogos-v2-renderers` branch contains five browser-verified Lit components (`edu-math`, `edu-code`, `edu-chart`, `edu-geometry`, `edu-sim-2d`), test fixtures, and a renderer-map. That work was built against paidagogos's in-house server and loads dependencies from CDNs (esm.sh, jsdelivr) at runtime. visual-kit rejects runtime CDN loads in favor of pre-bundled, SRI-pinned, CSP-compatible bundles served from `/vk/*.js`.

Merging v2-renderers to main directly would ship paidagogos V2 briefly, then Plan A's Task 19 would delete that work during the visual-kit migration — double churn.

**Decision.** Archive the v2-renderers artifacts into `plugins/visual-kit/reference/` (edu-components source, lesson fixtures, renderer-map.md) on the visual-kit-v1 branch. These files are **not shipped** (not referenced by `src/`, not in any bundle, not on any route). They exist purely as porting reference for Plan B.

Plan B will port the rendering logic — KaTeX integration, Chart.js config shape, JSXGraph setup, Matter.js world — into proper `<vk-math>`, `<vk-chart>`, `<vk-geometry>`, `<vk-sim-2d>`, `<vk-code>` bundles under visual-kit's architecture (bundled deps, shadow DOM, pure components, JSON sibling props).

Once Plan B ships and the `vk-*` components pass integration tests with the same fixtures, `plugins/visual-kit/reference/` can be deleted and the v2-renderers branch can be marked superseded.

**Consequences.** No browser-verified rendering logic is lost. v2-renderers work enters main through visual-kit's path, not paidagogos's. Plan A scope remains 22 tasks (no expansion). The reference directory adds ~400 lines of preserved code to the working tree.

**Provenance.** Reference files copied from commit `682b316` on branch `feat/paidagogos-v2-renderers`, 2026-04-17.

---

## D-06 · Core bundle only in V1; domain bundles deferred to Plan B

**Date:** 2026-04-17 · **Status:** Accepted.

**Context.** The design spec lists nine bundles (core + chart, math, code, geometry, sim-2d, audio, quiz, progress). Shipping all nine plus three consumer migrations plus infrastructure in one plan yields 80+ tasks.

**Decision.** Plan A (22 tasks) ships the core bundle (layout primitives + minimal `<vk-code>`) and migrates paidagogos. Plan B adds the domain bundles needed by paidagogos V2.1, namesmith, and draftloom, and performs those consumer migrations. Plan C adds the heavy bundles (3D, Pyodide, Sandpack) when a consumer needs them.

**Consequences.** Plan A is shippable in isolation — paidagogos migrates and renders lessons end-to-end. Plan B can port from `reference/edu-components/` directly. Plan C is gated on real consumer demand.

---
