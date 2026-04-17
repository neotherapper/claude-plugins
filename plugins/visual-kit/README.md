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

## Docs

- Design spec: `docs/superpowers/specs/2026-04-17-visual-kit-design.md`
- Contributor index: `docs/plugins/visual-kit/_index.md`
- Gherkin acceptance: `docs/plugins/visual-kit/specs/*.feature`
