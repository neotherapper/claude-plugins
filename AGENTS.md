# neotherapper/claude-plugins — Agent Instructions

This repository contains AI agent plugins that work across Claude Code, Gemini CLI,
GitHub Copilot, Cursor, Windsurf, and OpenCode.

## Available Plugins

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
