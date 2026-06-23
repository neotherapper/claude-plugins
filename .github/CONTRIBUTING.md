# Contributing

Thanks for contributing to `neotherapper/claude-plugins` — a marketplace of AI
agent plugins for Claude Code (and Gemini CLI, Copilot, Cursor, Windsurf, and
OpenCode).

## Repository layout

- `plugins/<name>/` — one folder per plugin
  - `.claude-plugin/plugin.json` — required manifest (`name`, `version`, `description`)
  - `commands/`, `agents/`, `skills/`, `hooks/` — optional components
- `.claude-plugin/marketplace.json` — the marketplace manifest Claude Code reads;
  published plugins are listed here
- `scripts/validate-marketplace.sh` — validates the manifest and every plugin
- `AGENTS.md` / `CLAUDE.md` — agent instructions (edit `AGENTS.md`; `CLAUDE.md` imports it)

## Adding or changing a plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name` (matching the
   folder), `version`, `description`, and ideally `author`, `license`, `keywords`.
2. To **publish** it, add an entry to `.claude-plugin/marketplace.json`:

   ```json
   { "name": "<name>", "source": "./plugins/<name>", "description": "..." }
   ```

   Leaving a plugin out of the manifest keeps it an unpublished draft — the
   validator warns about it but does not fail.
3. Bump the plugin's `version` in `plugin.json` whenever behaviour changes.

## Conventions

- **Agents** (`agents/*.md`) need YAML frontmatter with `name` and `description`.
  Internal pipeline agents (dispatched by an orchestrator, not for direct use)
  should say so in the description so they don't auto-trigger.
- **Skills** (`skills/<name>/SKILL.md`) need frontmatter with `name` (matching the
  folder) and a specific, trigger-friendly `description`. Keep `SKILL.md` lean and
  push detail into `references/`.
- Use `${CLAUDE_PLUGIN_ROOT}` for in-plugin paths in hooks and skills — never
  hardcode absolute paths.
- Don't commit `node_modules/`, build output, or `.DS_Store`.

## Before opening a PR

Run the validator — CI runs the same check and gates merges to `main`:

```bash
bash scripts/validate-marketplace.sh
```

For Beacon tech packs specifically, see
[`plugins/beacon/CONTRIBUTING.md`](../plugins/beacon/CONTRIBUTING.md) and the
`tests/validate-*.sh` scripts.

## Commit style

Conventional commits with a plugin scope, e.g. `feat(beacon): …`,
`fix(paidagogos): …`, `chore(repo): …`.
