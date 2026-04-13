# Bundled Dev Skills for Contributors

This directory contains Claude Code plugins to help contributors extend Beacon
without needing to separately install development tools.

## Included

- **superpowers** — brainstorming, writing-plans, skill-creator, debugging and other workflow skills
- **plugin-dev** — plugin-structure, command-development, hook-development, mcp-integration

## How to use

When you open this repo in Claude Code, these plugins are available automatically.
Run `/plugin install` if they don't load on first open.

To create a new skill:
```
invoke skill-creator
```

To scaffold plugin components:
```
invoke plugin-dev:plugin-structure
```

## Installing the referenced plugins

These plugins are referenced by name. Install them via:

```bash
/plugin install superpowers@claude-plugins-official
/plugin install plugin-dev@claude-plugins-official
```

Contributors should install these before making changes to skills or commands.
