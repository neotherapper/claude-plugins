# Claude Code Plugin System — Research Reference

> Reference for AI agents building Beacon. Covers the plugin manifest, component discovery, path portability, and skill authoring conventions.

## Plugin Structure

Every Claude Code plugin follows this layout:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required manifest
├── commands/                # Slash commands (.md files, auto-discovered)
├── agents/                  # Subagent definitions (.md files, auto-discovered)
├── skills/                  # Skills (subdirectories, auto-discovered)
│   └── skill-name/
│       └── SKILL.md         # Required per skill
├── hooks/
│   └── hooks.json           # Event handler config
├── .mcp.json                # MCP server definitions
└── scripts/                 # Helper scripts and utilities
```

**Critical rules:**
- Manifest MUST be at `.claude-plugin/plugin.json` — nowhere else
- Component directories (commands, agents, skills, hooks) MUST be at plugin root, NOT inside `.claude-plugin/`
- Only create directories the plugin actually uses

## Plugin Manifest (`plugin.json`)

### Minimal

```json
{
  "name": "beacon"
}
```

### Full (Beacon's actual manifest shape)

```json
{
  "name": "beacon",
  "version": "0.1.0",
  "description": "Map any site's API surface — systematically.",
  "author": {
    "name": "Georgios Pilitsoglou",
    "url": "https://pilitsoglou.com"
  },
  "homepage": "https://github.com/neotherapper/beacon-plugin",
  "repository": "https://github.com/neotherapper/beacon-plugin",
  "license": "MIT",
  "keywords": ["api-mapping", "site-analysis", "osint", "recon"]
}
```

### Custom component paths (supplements, does not replace, auto-discovery)

```json
{
  "name": "beacon",
  "commands": "./custom-commands",
  "agents": ["./agents", "./specialized-agents"],
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

Paths must be relative (`./`) and cannot be absolute.

## Component Types

### Commands (`commands/*.md`)

Auto-discovered. All `.md` files in `commands/` become slash commands.

```markdown
---
name: beacon-analyze
description: Analyse a site and produce structured API surface documentation
---

Command instructions here...
```

Usage: `/beacon:analyze https://example.com`

### Agents (`agents/*.md`)

Auto-discovered. Invoked manually or selected by Claude based on task context.

```markdown
---
description: Agent role and expertise
capabilities:
  - Specific task 1
---

Detailed instructions...
```

### Skills (`skills/{name}/SKILL.md`)

Auto-discovered. Claude activates them based on the description matching the user's request.

**Frontmatter requirements:**
- `name` — display name
- `description` — **must be third-person** with concrete trigger phrases
- `version` — semver

**Body requirements:**
- Use **imperative/infinitive form** (verb-first), NOT second person ("you should…")
- Keep SKILL.md lean: 1,500–2,000 words. Move detail to `references/`
- Reference all supporting files explicitly

**Directory structure for a full skill:**
```
skills/skill-name/
├── SKILL.md              # Core: triggers, workflow overview, pointers
├── references/           # Loaded as needed; can be large
│   ├── patterns.md
│   └── api-reference.md
├── examples/             # Working code, configs, templates
│   └── example.sh
└── scripts/              # Utility scripts (can execute without loading into context)
    └── validate.sh
```

**Progressive disclosure (3 levels):**
1. Metadata (name + description) — always in context (~100 words)
2. SKILL.md body — when skill triggers (<5k words)
3. References / scripts — loaded only when Claude determines they're needed

### Hooks (`hooks/hooks.json`)

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh",
      "timeout": 30
    }]
  }]
}
```

Available events: `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreCompact`, `Notification`

### MCP Servers (`.mcp.json`)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

## Portable Paths — `${CLAUDE_PLUGIN_ROOT}`

Always use `${CLAUDE_PLUGIN_ROOT}` for intra-plugin references. Never hardcode absolute paths.

**In JSON config (hooks, MCP):**
```json
"command": "${CLAUDE_PLUGIN_ROOT}/scripts/run.sh"
```

**In SKILL.md / command files:**
```markdown
Scripts are at: ${CLAUDE_PLUGIN_ROOT}/scripts/helper.py
```

**In executed scripts:**
```bash
#!/bin/bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
```

## Auto-Discovery Timing

1. Plugin install → components register
2. Plugin enable → components become available
3. No restart required — takes effect on next Claude Code session
4. Custom paths in `plugin.json` **supplement** (not replace) defaults

## File Naming

| Component | Convention | Example |
|-----------|------------|---------|
| Commands | kebab-case `.md` | `beacon-analyze.md` → `/beacon:analyze` |
| Agents | kebab-case `.md` | `recon-agent.md` |
| Skills | kebab-case directory | `site-recon/` |
| Scripts | kebab-case with extension | `probe-site.sh` |
| References | kebab-case `.md` | `osint-patterns.md` |

## Skill Description — Good vs Bad

**Good:**
```yaml
description: This skill should be used when the user asks to "analyse a site", "map API surfaces", "research {url}", or runs /beacon:analyze. Runs a 12-phase investigation producing structured docs/research/{site}/ output.
```

**Bad:**
```yaml
description: Provides site analysis guidance.  # vague, no trigger phrases, not third person
```

## Beacon-Specific Notes

- Beacon uses two skills: `site-recon` (research mode) and `site-intel` (router/load mode)
- Scripts are NOT bundled inside the plugin directory — they are downloaded at runtime from GitHub (see `../script-distribution/INDEX.md`)
- Tech packs live in `technologies/` at the plugin root, versioned as `{framework}/{major}.x.md`
- All output goes to `docs/research/{site}/` in the USER's project, not in the plugin

## References

- plugin-dev plugin: `/Users/georgiospilitsoglou/.claude/plugins/cache/claude-plugins-official/plugin-dev/`
- Plugin structure skill: `plugin-dev/skills/plugin-structure/SKILL.md`
- Skill development skill: `plugin-dev/skills/skill-development/SKILL.md`
