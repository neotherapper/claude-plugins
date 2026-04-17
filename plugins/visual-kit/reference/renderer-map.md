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
