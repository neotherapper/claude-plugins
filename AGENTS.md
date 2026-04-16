# neotherapper/claude-plugins — Agent Instructions

This repository contains AI agent plugins that work across Claude Code, Gemini CLI,
GitHub Copilot, Cursor, Windsurf, and OpenCode.

## Available Plugins

### paidagogos — Structured Lesson Teacher

Skills in `plugins/paidagogos/skills/`:

| Skill | Path | When to activate |
|-------|------|-----------------|
| `paidagogos` | `plugins/paidagogos/skills/paidagogos/SKILL.md` | User asks to learn a topic, wants an explanation, or says "teach me X" |
| `paidagogos:micro` | `plugins/paidagogos/skills/paidagogos-micro/SKILL.md` | User specifies `/paidagogos:micro` directly, or router routes a single-concept request here |

### beacon — Site API Surface Mapper

Skills in `plugins/beacon/skills/`:

| Skill | Path | When to activate |
|-------|------|-----------------|
| `site-recon` | `plugins/beacon/skills/site-recon/SKILL.md` | User asks to analyse a site, map API surfaces, research a URL, or runs `/beacon:analyze` |
| `site-intel` | `plugins/beacon/skills/site-intel/SKILL.md` | User asks about a previously researched site, or asks questions about `docs/research/{site}/` files |

## Intent → Skill Mapping

When the user's request matches any of these patterns, load and follow the corresponding skill:

| User intent | Skill to activate |
|-------------|------------------|
| "teach me [topic]" | `paidagogos` |
| "explain [topic]" | `paidagogos` |
| "how does [topic] work" | `paidagogos` |
| "I want to learn [topic]" | `paidagogos` |
| "what is [topic]" (learning context) | `paidagogos` |
| "quiz me on [topic]" | `paidagogos` |
| "/paidagogos serve" | `paidagogos` (start visual server) |
| "analyse https://..." | `site-recon` |
| "research this site" | `site-recon` |
| "map the API surface of..." | `site-recon` |
| "what endpoints does X have?" | `site-recon` (new) or `site-intel` (if already researched) |
| "find the API for..." | `site-recon` |
| "tell me about [known site]" | `site-intel` |
| "load the research for..." | `site-intel` |
| "what did we find on..." | `site-intel` |

## Execution Rules

1. If a skill applies, **you must load and follow it** — do not summarise or shortcut it
2. Skills define a mandatory phase sequence — do not reorder phases
3. All tool names in skills use Claude Code conventions; adapt to your platform:
   - `Read` → `read_file` (Gemini) / `view` (Copilot) / native file tool (Codex)
   - `Bash` → `run_shell_command` (Gemini) / `bash` (Copilot) / native shell (Codex)
   - `Grep` → `grep_search` (Gemini) / `grep` (Copilot)
   - `WebSearch` → `google_web_search` (Gemini) / `web_fetch` with search URL (Copilot)
   - `Task` (subagent) → `spawn_agent` (Codex) / not supported (Gemini — run sequentially)

## Output Convention

All analysis output goes to `docs/research/{site-name}/` in the user's working directory.
Never write site-specific data into the plugin directories.

## Anti-Rationalizations

| Rationalization | Reality |
|----------------|---------|
| "This site is simple, I can skip phases" | Simple sites still have hidden endpoints. Run all phases. |
| "I already know the framework, skip fingerprinting" | Version matters — wrong version = wrong tech pack |
| "OSINT is overkill for this" | Phase 9 regularly finds subdomains and historical endpoints missed by all other phases |
| "I'll skip the browse plan and just open the browser" | Unplanned browsing misses systematic coverage. Always compile the plan first. |

## Plugin Development

This repo is also a plugin-building workspace. The following plugins are active here — project-level plugins are configured in `.claude/settings.json`; the last two are globally active:

- **`plugin-dev@claude-plugins-official`** — scaffolding, skill/command development, validation agents
- **`agent-skills@addy-agent-skills`** — spec, planning, browser testing, API design, incremental implementation
- **`superpowers@claude-plugins-official`** — brainstorming, planning, TDD, debugging (globally active)
- **`skill-creator@claude-plugins-official`** — create and iterate on skills (globally active)

The **chrome-devtools MCP server** is wired via `.mcp.json` for live browser testing.

### Plugin Development Intent → Tool Mapping

When the user's request matches any of these patterns, use the corresponding tool:

| User intent | Tool to use |
|-------------|-------------|
| "spec out this plugin" / "I want to build X plugin" | `agent-skills:spec-driven-development` skill |
| "break this into tasks" / "plan the work" | `agent-skills:planning-and-task-breakdown` skill |
| "create a new plugin" / "scaffold this plugin" | `plugin-dev:/create-plugin` command |
| "write a skill for X" | `plugin-dev:skill-development` skill |
| "write a command for X" | `plugin-dev:command-development` skill |
| "validate this skill" / "review this skill" | `plugin-dev:skill-reviewer` agent |
| "test this in the browser" / "check browser output" | `agent-skills:browser-testing-with-devtools` skill + chrome-devtools MCP |
| "design the API / interface for this plugin" | `agent-skills:api-and-interface-design` skill |
| "implement this incrementally" | `agent-skills:incremental-implementation` skill |
| "create a skill" / "write a new skill" | `skill-creator:skill-creator` skill |

### Execution Rules (Plugin Development)

1. When a plugin-building intent matches the table above, load and follow the mapped skill before doing any implementation work
2. The chrome-devtools MCP is available for browser testing — use it via `agent-skills:browser-testing-with-devtools`, not directly
3. All new plugin code goes in `plugins/<plugin-name>/` — never in `docs/` or project root
4. Specs for new plugins go in `docs/superpowers/specs/` before any implementation begins
