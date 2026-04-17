# Reference material — not shipped

This directory holds prior-art source from the paidagogos V2 renderer work. It is **not part of the shipping visual-kit bundle** and is not referenced by `src/`, `bin/`, `dist/`, or any runtime code. Its sole purpose is to preserve browser-verified rendering logic that will be ported into proper `<vk-*>` components during Plan B.

## What's here

### `edu-components/`

Five Lit web components built and browser-verified on the `feat/paidagogos-v2-renderers` branch:

| File | Upstream library | Role |
|---|---|---|
| `edu-math.js` | KaTeX | LaTeX math rendering |
| `edu-code.js` | CodeMirror 6 | Code display / editing |
| `edu-chart.js` | Chart.js | Charts |
| `edu-geometry.js` | JSXGraph | Interactive geometry |
| `edu-sim-2d.js` | Matter.js | 2D physics simulation |

### `fixtures/`

Five `Lesson` SurfaceSpec fixtures that exercise each renderer end-to-end. Suitable as input to visual-kit integration tests once the corresponding `<vk-*>` bundles ship.

### `renderer-map.md`

Topic → renderer classification rules. Used by `paidagogos:micro` to populate the `renderers[]` field in generated lessons.

## Architecture deltas to reconcile when porting

The edu-\*.js modules were built for paidagogos's in-house server and must be refactored before they fit visual-kit:

1. **Runtime CDN loads → bundled dependencies.** The edu-\* components `import` Lit and `script`-load KaTeX / Chart.js / etc. from `esm.sh` and `cdn.jsdelivr.net` at runtime. visual-kit's CSP is `default-src 'none'; script-src 'self' 'nonce-…'`, which blocks this entirely. Port target: bundle each library via esbuild into `dist/<bundle>.js`, served from `/vk/<bundle>.js`.
2. **`config` attribute → slotted content + JSON sibling.** edu-\* uses `<edu-math config="…">` with a JSON-stringified config attribute. visual-kit's pattern (AR-8 in the design spec) is to pass complex props via a sibling `<script type="application/json">` element, not attributes — safer under lit-html SSR escape rules.
3. **`<edu-*>` prefix → `<vk-*>` prefix.** Single-prefix taxonomy per the design spec; components are pure and portable regardless of domain.
4. **Light-DOM render → shadow-DOM (default) with opt-out.** edu-math uses light DOM so page-level KaTeX CSS cascades in. visual-kit bundles the KaTeX CSS into the bundle itself and renders in shadow DOM.
5. **Zero plugin-state coupling.** edu-\* has none today; keep that invariant in the vk-\* ports (the CI gate `scripts/lint-pure-components.mjs` enforces it).

## Provenance

Files in `edu-components/` and `fixtures/` were copied verbatim from commit `682b316` of branch `feat/paidagogos-v2-renderers` on 2026-04-17. No modifications made — this is a read-only archive.

## When to delete

After Plan B (visual-kit V1 domain bundles + namesmith + draftloom migrations) lands and the `<vk-math>`, `<vk-code>`, `<vk-chart>`, `<vk-geometry>`, `<vk-sim-2d>` components have shipped and been verified end-to-end, this directory can be removed. Until then, keep it.
