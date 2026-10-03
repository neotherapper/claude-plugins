# neotherapper/claude-plugins

> AI agent plugins by [@neotherapper](https://github.com/neotherapper) · [pilitsoglou.com](https://pilitsoglou.com)

[![validate](https://github.com/neotherapper/claude-plugins/actions/workflows/validate.yml/badge.svg)](https://github.com/neotherapper/claude-plugins/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **Claude Code plugin marketplace** whose skills install into **any agent harness** — Pi, OpenCode,
Cline, Kiro, Codex, Cursor, Gemini CLI, GitHub Copilot, Windsurf, Antigravity, and 70+ more — with
one `npx skills add neotherapper/claude-plugins` ([install](#installation-30-second-setup)).
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

## Installation (30-second setup)

Two ways in. **Claude Code** installs a plugin as a managed bundle that updates when we ship.
**Every other harness** gets the skills through the universal [`skills` CLI](https://github.com/vercel-labs/skills)
(`npx skills add`), which copies each skill folder, whole, to
the path your agent scans. Claude Code users should stick to the marketplace: adding
`-a claude-code` on top of it gives you every skill twice.

### Claude Code

```
/plugin marketplace add neotherapper/claude-plugins
/plugin install beacon@neotherapper-plugins
```

Skills, commands, agents, and hooks are auto-discovered per plugin. Install any of:
`beacon`, `aegis`, `reframe`, `namesmith`, `draftloom`, `idea-forge`, `paidagogos`, `visual-kit`
(all `@neotherapper-plugins`).

### Everything else — Pi, OpenCode, Cline, Kiro, Codex, Cursor, Gemini CLI, Copilot, and 70+ more

```bash
# interactive: pick the skills and the agents you have installed
npx skills@latest add neotherapper/claude-plugins

# non-interactive: every skill, into the agents you name
npx skills@latest add neotherapper/claude-plugins --skill '*' -a pi -a opencode -a cline -a kiro-cli -y

# one plugin's skills only (skill names per plugin are in the table below)
npx skills@latest add neotherapper/claude-plugins --skill site-recon --skill site-intel --skill site-fleet -a opencode -y
```

Add `-g` to install for your user instead of the current project, and `npx skills update` to pull
the latest versions later. The CLI auto-detects installed agents; for an agent it cannot detect
(a fresh machine, CI, a harness it has no entry for) add `--copy` so the files land as real
directories at that agent's path instead of symlinks into `.agents/skills/`.

| Harness | `-a` flag | Project path the skill lands in | Notes |
|---|---|---|---|
| Pi | `pi` | `.pi/skills/` | use `--copy` if Pi isn't detected on the machine |
| OpenCode | `opencode` | `.agents/skills/` | native fallback path — verified live |
| Cline | `cline` | `.agents/skills/` | shared "universal" path |
| Kiro CLI / IDE | `kiro-cli` | `.kiro/skills/` | custom agents: add `skill://.kiro/skills/**/SKILL.md` to `resources` |
| Codex | `codex` | `.agents/skills/` | reads `AGENTS.md` natively too |
| Cursor | `cursor` | `.agents/skills/` | |
| Gemini CLI | `gemini-cli` | `.agents/skills/` | or `gemini skills install` — see [docs/platform/gemini-cli.md](docs/platform/gemini-cli.md) |
| GitHub Copilot | `github-copilot` | `.agents/skills/` | see [docs/platform/copilot.md](docs/platform/copilot.md) |
| Windsurf | `windsurf` | `.windsurf/skills/` | |
| Antigravity | `antigravity` | `.agents/skills/` | |
| Roo Code / Kilo / Goose / Droid / Qwen / MiniMax / Mistral Vibe … | see [full list](https://github.com/vercel-labs/skills#supported-agents) | per agent | |
| DeepSeek or any harness not listed | `universal` | `.agents/skills/` | most harnesses read `.agents/skills/`; otherwise copy the folder — see below |

**No CLI, or a harness the CLI does not know?** A skill is just a folder. Copy it to wherever
your agent scans for `SKILL.md`:

```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/site-recon <your-agent-skills-dir>/
```

Or clone this repo and open it as the workspace: `AGENTS.md` at the root is read natively by
Codex, OpenCode, Antigravity, Kiro, and Gemini CLI, and the `.agents/skills/` + `.kiro/skills/`
symlink farms expose every skill in place.

### Which skills belong to which plugin

| Plugin | Skills (`--skill` names) |
|---|---|
| beacon | `site-recon`, `site-intel`, `site-fleet` |
| aegis | `site-security` |
| reframe | `site-redesign` |
| namesmith | `site-naming` |
| draftloom | `draft`, `eval`, `setup` |
| idea-forge | `generate`, `evaluate` |
| paidagogos | `paidagogos`, `paidagogos-micro`, `paidagogos-path` |
| visual-kit | no skills — a shared renderer used by paidagogos; Claude Code plugin only |

`scripts/check-skills-cli.sh` runs in CI and fails if the skills CLI stops seeing any of these.

**What a CLI install carries, per plugin.** A CLI copy is the whole skill folder: `SKILL.md` plus
any `scripts/`, `references/`, `templates/`, `technologies/`, `categories/` or `agents/` it ships.
Skill text uses paths relative to that folder, so the copy works without the rest of the repo:

| Plugin | Via `npx skills add` | Needs more than the skill folder |
|---|---|---|
| namesmith, draftloom, aegis, reframe, idea-forge (`generate`, `evaluate`) | works | nothing |
| beacon `site-recon` | works | nothing; version reads `unversioned` outside a plugin install |
| beacon `site-intel`, `site-fleet` | works with `site-recon` | `site-recon` installed alongside (tech packs, templates, shared scripts) |
| paidagogos `paidagogos-micro` | works | `visual-kit` for rendered lessons; falls back to Markdown in chat |
| paidagogos `paidagogos`, `paidagogos-path` | partial | `visual-kit` renderer; path's index build (`scripts/build-index.mjs`) needs a repo clone |

`visual-kit` is a Node app and `build-index.mjs` needs the plugin's `node_modules`, so neither fits
in a skill folder: use the Claude Code plugin or a repo clone for those. Installing every skill
(`--skill '*'`) satisfies the beacon sibling rule.

### Cross-Tool (gh skill)

```sh
# Install a skill for any agent
gh skill install neotherapper/claude-plugins site-recon --agent claude-code
gh skill install neotherapper/claude-plugins site-recon --agent opencode

# Pin to a specific version
gh skill install neotherapper/claude-plugins site-recon@v0.7.1

# Update all skills across all agents
gh skill update --all
```

<details>
<summary><b>Manual per-tool notes — Codex, OpenCode, Antigravity, Kiro, Cursor, Windsurf</b></summary>

**OpenAI Codex CLI** — reads this repo's root `AGENTS.md` automatically. Skills at `.agents/skills/`
(a documented Codex scan root) are symlinks back into `plugins/`, so clone the repo and work inside
it, or use `npx skills add` above. MCP servers go in `~/.codex/config.toml`.

**OpenCode** — reads the root `AGENTS.md` and falls back to scanning `.agents/skills/`, so cloning
this repo exposes every skill with **no extra config**. MCP servers go in `opencode.json` under `mcp`.
Full guide: [docs/platform/opencode.md](docs/platform/opencode.md).

**Google Antigravity (CLI `agy` + IDE)** — reads the root `AGENTS.md`, rules from `.agents/rules/`,
and skills from `.agents/skills/`. Workspace MCP config is `.agents/mcp_config.json`.

**AWS Kiro** — reads the root `AGENTS.md` plus `.kiro/steering/`, loads skills from `.kiro/skills/`.
MCP servers go in `.kiro/settings/mcp.json`. Open this repo as the workspace, or import a skill
folder via Kiro's "Agent Steering & Skills" panel.

**Cursor** — full guide: [docs/platform/cursor.md](docs/platform/cursor.md)
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
- **Any other harness** gets the same folders through the `skills` CLI, which scans this repo for
  `SKILL.md` files and copies each skill folder to the path that harness reads.
  `scripts/check-skills-cli.sh` is CI-gated so the CLI always sees every skill.
  `scripts/check-skill-portability.py` fails CI if a skill references a plugin-root path or a file
  outside its own folder, and `scripts/check-skills-cli-install.sh` installs every skill with
  `--copy` and smoke-tests the copies.
- Adding a skill? Run `scripts/sync-skills.sh`; CI runs `scripts/sync-skills.sh --check` to fail the
  build if a skill isn't exposed.

Full details, per-tool paths, and verification status: **[docs/platform/multi-tool-support.md](docs/platform/multi-tool-support.md)**.

---

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to add a plugin, run the validators, and the
skill/agent conventions. For Beacon tech packs specifically, see the
[Beacon contributing guide](plugins/beacon/CONTRIBUTING.md).

Built by [@neotherapper](https://github.com/neotherapper) · Articles at [pilitsoglou.com](https://pilitsoglou.com)
