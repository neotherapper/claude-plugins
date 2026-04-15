# Plugin Workspace Setup — Design Spec

**Date:** 2026-04-14  
**Status:** Approved  

## Goal

Configure `claude-plugins` as a first-class plugin-building workspace. When working in this repo, Claude should have the right MCP servers available and the right plugins active — so the toolchain for building, speccing, testing, and validating plugins is loaded automatically.

## Scope

Three files, no new plugin code:

1. `.mcp.json` — MCP server configuration (chrome-devtools)
2. `.claude/settings.json` — project-level plugin activation
3. `AGENTS.md` — updated intent → tool routing for plugin development

## Components

### `.mcp.json`

Wire up `chrome-devtools-mcp` via `npx` so it's available in every session in this repo without a local install. This enables live browser testing of plugins that produce web output (e.g. beacon's HAR/OpenAPI reports, any future UI-facing plugin work).

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "type": "stdio",
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest", "--autoConnect"]
    }
  }
}
```

### `.claude/settings.json`

Project-scoped settings file (committed, not local) that enables two plugins on top of the globally active ones:

| Plugin | Source | Key capabilities |
|--------|--------|-----------------|
| `plugin-dev` | `claude-plugins-official` | `/create-plugin` command; agent-creator, skill-reviewer, plugin-validator agents; command-development and skill-development skills |
| `agent-skills` | `addy-agent-skills` | `/spec`, `/plan`, `/build`, `/test`, `/review`, `/ship` commands; spec-driven-development, browser-testing-with-devtools, api-and-interface-design, planning-and-task-breakdown, incremental-implementation skills |

These stack on top of globally enabled plugins (superpowers, skill-creator, remember, claude-code-setup, claude-md-management).

### `AGENTS.md` Update

Add a "Plugin Development" section that maps plugin-building intents to specific tools. This prevents Claude from guessing and ensures the right skill fires for common plugin-building tasks:

| Intent | Tool |
|--------|------|
| "spec out this plugin / I want to build X" | `agent-skills:spec-driven-development` |
| "break this into tasks / plan the work" | `agent-skills:planning-and-task-breakdown` |
| "create a new plugin / scaffold this plugin" | `plugin-dev:/create-plugin` |
| "write a skill for X" | `plugin-dev:skill-development` |
| "write a command for X" | `plugin-dev:command-development` |
| "validate / review this skill" | `plugin-dev:skill-reviewer` agent |
| "test this in the browser / check browser output" | `agent-skills:browser-testing-with-devtools` + chrome-devtools MCP |
| "design the API / interface for this plugin" | `agent-skills:api-and-interface-design` |
| "implement this incrementally" | `agent-skills:incremental-implementation` |

## What's Excluded

- `eur-lex-mcp` and `mcp-cerebra-legal-server` — domain-specific legal tools, not relevant to plugin creation
- `nx-mcp` and `playwright-local` — localhost-only, not portable across sessions
- `task-master-ai` — redundant with superpowers planning workflow already global
- A new `plugins/plugin-builder/` plugin — premature; use the workflow first, extract later

## Implementation Steps

1. Create branch `feat/plugin-workspace-setup`
2. Create `.mcp.json`
3. Create `.claude/settings.json`
4. Update `AGENTS.md` with plugin development section
5. Commit and push branch
