# visual-kit

Shared local-browser visual rendering for Claude Code plugins.

## What it provides

- `bin/visual-kit` — CLI (serve / stop / status) placed on PATH.
- HTTP server at `http://localhost:<port>/` (per-workspace, localhost-only, strict CSP).
- `<vk-*>` web component library served at `/vk/*.js`.
- SurfaceSpec JSON contract — consumer skills write typed JSON; visual-kit renders it.

## For consumers

In your plugin's `.claude-plugin/plugin.json`:

    {
      "dependencies": [
        { "name": "visual-kit", "version": "~1.0.0" }
      ]
    }

Start the server once per workspace:

    visual-kit serve --project-dir .

Write a SurfaceSpec to `.<your-plugin>/content/<surface-id>.json`. Open the printed URL.

## Surfaces

| Surface | For | Schema |
|---|---|---|
| `lesson` | A taught concept: explanation, code, mistakes, quiz | `lesson.v1.json` |
| `tree` | A navigable hierarchy whose nodes open a detail popover — roadmaps, curricula, taxonomies, decision trees. Rendered as a spine with children branching off it | `tree.v1.json` |
| `gallery` | A card grid. Cards may carry `href` and become links | `gallery.v1.json` |
| `outline` | A nested list | `outline.v1.json` |
| `comparison` | A table of options against criteria | `comparison.v1.json` |
| `feedback` | Scored review with findings | `feedback.v1.json` |
| `free` | Sanitised author HTML, strict CSP | `free.v1.json` |
| `free-interactive` | Author HTML+JS, **no sanitisation and no CSP** — opt-in, localhost-only trust model | `free-interactive.v1.json` |

`tree` and the core surfaces ship zero component JavaScript: disclosure uses the
native Popover API and the ordering switcher is a CSS radio group, because
components may not perform network access (CI-enforced by
`scripts/lint-pure-components.mjs`).

## Docs

- Design spec: `docs/superpowers/specs/2026-04-17-visual-kit-design.md`
- Contributor index: `docs/plugins/visual-kit/_index.md`
- Gherkin acceptance: `docs/plugins/visual-kit/specs/*.feature`
