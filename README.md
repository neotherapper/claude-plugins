# neotherapper/claude-plugins

> AI agent plugins by [@neotherapper](https://github.com/neotherapper) · [pilitsoglou.com](https://pilitsoglou.com)

[![validate](https://github.com/neotherapper/claude-plugins/actions/workflows/validate.yml/badge.svg)](https://github.com/neotherapper/claude-plugins/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **Claude Code plugin marketplace** that also works with **OpenAI Codex**, **OpenCode**,
**Google Antigravity**, and **AWS Kiro** — plus Gemini CLI, GitHub Copilot, Cursor, and Windsurf.
One `AGENTS.md` drives the instructions layer for every tool; the skills are exposed to each tool
at the path it scans. See **[docs/platform/multi-tool-support.md](docs/platform/multi-tool-support.md)**
for the full settings/files matrix.

---

## Plugins

| Plugin | What it does |
|---|---|
| [**beacon**](plugins/beacon/) | Map any site's API surface — systematically. Tech fingerprinting, endpoint probing, JS/source-map mining, OSINT, then a browser visit plan. |
| [**reframe**](plugins/reframe/) | Turn any live site into a purpose-driven redesign brief for Claude Design. |
| [**namesmith**](plugins/namesmith/) | Find the right name for your project — brand interview, AI generation across 8 archetypes, live domain availability + pricing (Cloudflare / Porkbun). |
| [**draftloom**](plugins/draftloom/) | AI-powered blog post drafting. Write in your voice, optimised for virality. |
| [**idea-forge**](plugins/idea-forge/) | Two-stage business idea pipeline: surface opportunity gaps and evaluate viability. |
| [**paidagogos**](plugins/paidagogos/) | Structured AI-powered lessons for any topic, rendered in a local visual browser UI. |
| [**visual-kit**](plugins/visual-kit/) | Shared local visual rendering for the plugins above — the `vk-*` component library, HTTP server, and SurfaceSpec JSON contract. |

### Featured: beacon

Run one command and Beacon:
1. Detects the tech stack and loads a framework-specific guide
2. Probes all known public endpoints, sitemaps, feeds, and GraphQL schemas
3. Analyses JS bundles and source maps for hidden API paths
4. Runs OSINT (certificate transparency, Wayback Machine, GitHub code search, Google dorks)
5. Compiles a browser visit plan — then executes it
6. Writes `docs/sites/{site}/research/` with INDEX, tech-stack, site-map, API surfaces, and an OpenAPI spec

In future sessions, ask questions about the site and Beacon routes directly to the pre-built research files.

---

## Installation

### Claude Code

```
/plugin marketplace add neotherapper/claude-plugins
/plugin install beacon@neotherapper-plugins
```

Skills, commands, agents, and hooks are auto-discovered per plugin. Install any of:
`beacon`, `reframe`, `namesmith`, `draftloom`, `idea-forge`, `paidagogos`, `visual-kit`
(all `@neotherapper-plugins`).

### OpenAI Codex CLI

Codex reads this repo's root `AGENTS.md` automatically. The skills are exposed at `.agents/skills/`
(one of Codex's documented scan roots). Clone the repo and work inside it, or copy `AGENTS.md` +
`.agents/skills/` into your project. MCP servers go in `~/.codex/config.toml`.

### OpenCode

OpenCode reads the root `AGENTS.md` automatically and falls back to scanning `.agents/skills/`, so
cloning this repo (or adding it to your workspace) exposes every skill with **no extra config**.
MCP servers go in `opencode.json` under the `mcp` key.

### Google Antigravity (CLI `agy` + IDE)

Antigravity reads the root `AGENTS.md`, workspace rules from `.agents/rules/`, and workspace skills
from `.agents/skills/` — all shipped here. Workspace MCP config is `.agents/mcp_config.json`.

### AWS Kiro

Kiro reads the root `AGENTS.md` (always-included) plus steering in `.kiro/steering/`, and loads
skills from `.kiro/skills/`. MCP servers go in `.kiro/settings/mcp.json`. Open this repo as the
workspace, or import a skill folder via Kiro's "Agent Steering & Skills" panel.

<details>
<summary><b>Other tools — Gemini CLI, GitHub Copilot, Cursor, Windsurf</b></summary>

**Gemini CLI**
```bash
gemini skills install https://github.com/neotherapper/claude-plugins.git --path plugins/beacon/skills
```

**GitHub Copilot**
```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/* .github/skills/
cp -r claude-plugins/plugins/beacon/agents/* .github/agents/
```
Then in `.github/copilot-instructions.md`: `Skills are available in .github/skills/. Follow them when they match the task.`

**Cursor**
```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/* .cursor/rules/
```

**Windsurf**
```bash
git clone https://github.com/neotherapper/claude-plugins.git
cat claude-plugins/plugins/beacon/skills/site-recon/SKILL.md >> .windsurfrules
```
</details>

---

## How the multi-tool wiring works

- **`AGENTS.md`** (repo root) is the single source of cross-tool instructions — read natively by
  Claude Code, Codex, OpenCode, Antigravity, and Kiro.
- **Skills live once** under `plugins/<plugin>/skills/<skill>/`. `scripts/sync-skills.sh` mirrors
  each one via symlink into `.agents/skills/` (Codex + Antigravity + OpenCode) and `.kiro/skills/`
  (Kiro) — so there's a single source of truth and no duplicated content.
- Adding a skill? Run `scripts/sync-skills.sh`; CI runs `scripts/sync-skills.sh --check` to fail the
  build if a skill isn't exposed.

Full details, per-tool paths, and verification status: **[docs/platform/multi-tool-support.md](docs/platform/multi-tool-support.md)**.

---

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to add a plugin, run the validators, and the
skill/agent conventions. For Beacon tech packs specifically, see the
[Beacon contributing guide](plugins/beacon/CONTRIBUTING.md).

Built by [@neotherapper](https://github.com/neotherapper) · Articles at [pilitsoglou.com](https://pilitsoglou.com)
