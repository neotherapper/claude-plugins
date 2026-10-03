# Multi-tool support — settings & files each agent needs

This repo is a **Claude Code plugin marketplace** (`.claude-plugin/marketplace.json` +
`plugins/<name>/`). This document is the source of truth for making the same skills usable
by **Claude Code, OpenAI Codex CLI, OpenCode, Google Antigravity (CLI + IDE), and AWS Kiro**
with the least duplication possible — and installable into any other project, for Pi, Cline, and
70+ more harnesses, through the universal `skills` CLI (see
[Install into your own project](#install-into-your-own-project--any-harness-skills-cli)).

> **Verification status.**
> - **Claude Code** — loading exercised via the marketplace validator.
> - **OpenCode** — ✅ **verified live**: `opencode debug skill` in this repo discovers every skill
>   from `.agents/skills/<name>/SKILL.md` (the symlink farm), following the links to the canonical
>   `plugins/` content. Retiring the earlier custom loader is confirmed non-regressive.
> - **Codex, Antigravity, Kiro** — structured per each tool's **documented workspace conventions**
>   (as of 2026-07) but **not** run against a live install here (Codex is installed but its native
>   binary is broken on this machine; Antigravity/Kiro not installed). They use the same
>   `.agents/skills/` / `.kiro/skills/` mechanism OpenCode verifies. Where docs and community
>   reporting disagree on a path, we prefer the **workspace** path and flag the disputed **global**
>   one.
>
> **How non-Claude tools consume this repo.** Claude Code users `/plugin install` individual
> plugins. The other four tools do **not** install a plugin — they read the workspace files
> (`AGENTS.md`, `.agents/`, `.kiro/`), so you **clone or open this repo as the workspace** (or copy
> those top-level files into your project). A `/plugin install` consumer never receives repo-root
> `.agents/`.

---

## The short version

Two facts do almost all the work:

1. **`AGENTS.md` at the repo root is read natively by all five tools.** Claude Code imports it
   via `CLAUDE.md`; Codex, OpenCode, Antigravity, and Kiro each discover a root `AGENTS.md`
   automatically with zero configuration. Our cross-tool routing table already lives there.
   **Nothing to duplicate for the instructions layer.**

2. **`SKILL.md` is an open, shared format** ([agentskills.io](https://agentskills.io)) — the same
   `name` + `description` frontmatter triggers the skill in every tool. The only problem is
   *where each tool looks*: none of them walk our nested `plugins/<plugin>/skills/<skill>/`
   layout. They each scan a fixed, shallow, top-level directory.

So the entire multi-tool problem reduces to: **expose each skill at the top-level path each tool
scans.** We do that with a generated **symlink farm** (see [Skill exposure](#skill-exposure)),
so there is still exactly one copy of every skill — the one under `plugins/`.

---

## Per-tool matrix

| Concern | Claude Code | Codex CLI | OpenCode | Antigravity (`agy`) | Kiro |
|---|---|---|---|---|---|
| **Instructions** | `AGENTS.md` via `CLAUDE.md` import | root `AGENTS.md` (native) | root `AGENTS.md` (native) | root `AGENTS.md` (native) | root `AGENTS.md` (native, always-included) |
| **Extra rules file** | — | — | `instructions` array in `opencode.json` | `.agents/rules/*.md` (≤12k chars/file) | `.kiro/steering/*.md` (`inclusion:` frontmatter) |
| **Skills path (workspace)** | `plugins/<p>/skills/<s>/SKILL.md` (plugin nested) | `.agents/skills/<s>/SKILL.md` | `.opencode/skills/` **+ fallback** `.agents/skills/`, `.claude/skills/` | `.agents/skills/<s>/SKILL.md` | `.kiro/skills/<s>/SKILL.md` |
| **Commands** | `commands/*.md` | (custom prompts deprecated → skills) | `.opencode/commands/*.md` | `.agents/workflows/*.md` (`/name`) | Hooks / custom-agent prompt |
| **Subagents** | `agents/*.md` | `.codex/agents/*.toml` | `.opencode/agents/*.md` | plugin `agents/` | `.kiro/agents/*.json` |
| **MCP config** | `.mcp.json` | `~/.codex/config.toml` `[mcp_servers.*]` | `opencode.json` `mcp` key | `.agents/mcp_config.json` (`serverUrl` for remote) | `.kiro/settings/mcp.json` (`url` for remote) |
| **Plugin/marketplace primitive** | ✅ `.claude-plugin/marketplace.json` | ❌ none (skills + AGENTS.md only) | JS/TS plugins in `.opencode/plugins/` | `agy plugin` (`plugin.json` bundle) | "Powers" (IDE only) |

Legend: **workspace** = committed in this repo and shared with everyone who clones it. Global
(per-user `~/…`) paths exist for every tool too but are out of scope — a marketplace repo should
ship *workspace* files so a clone is self-configuring.

---

## What this repo ships (and why)

```
claude-plugins/
├── AGENTS.md                         # single source of cross-tool instructions (all 5 read this)
├── CLAUDE.md                         # @imports AGENTS.md (Claude Code)
├── .claude-plugin/marketplace.json   # Claude Code marketplace catalog
├── plugins/<name>/                   # canonical plugins (skills/agents/commands/hooks) — ONLY copy
│   ├── .claude-plugin/plugin.json
│   └── skills/<skill>/SKILL.md
├── .agents/                          # Codex + Antigravity + OpenCode(fallback)
│   ├── skills/<skill> -> ../../plugins/<p>/skills/<skill>   # symlinks (generated)
│   ├── rules/00-agents.md            # thin pointer back to AGENTS.md
│   └── mcp_config.json               # Antigravity-shape MCP (serverUrl)
├── .kiro/                            # Kiro
│   ├── skills/<skill> -> ../../plugins/<p>/skills/<skill>   # symlinks (generated)
│   ├── steering/00-agents.md         # inclusion: always → points at AGENTS.md
│   └── settings/mcp.json             # Kiro-shape MCP (url)
├── .mcp.json                         # Claude Code MCP (canonical server list)
└── scripts/sync-skills.sh            # (re)generates + validates the symlink farms
```

`.agents/skills/` intentionally serves **three** tools at once: Codex scans it, Antigravity
scans it (workspace path — the one path all sources agree on), and OpenCode falls back to it. We
do **not** create `.claude/skills/` — Claude Code already gets these skills through the plugin
marketplace, and OpenCode scans both `.claude/skills/` and `.agents/skills/`, so shipping both
would double-load every skill in OpenCode.

### Skill exposure

Canonical skills live once, under `plugins/<plugin>/skills/<skill>/`. `scripts/sync-skills.sh`
creates a symlink per skill into `.agents/skills/` and `.kiro/skills/`:

```
.agents/skills/site-recon  ->  ../../plugins/beacon/skills/site-recon
.kiro/skills/site-recon    ->  ../../plugins/beacon/skills/site-recon
```

Symlinking the **directory** (not copying) means:

- **One source of truth.** Editing `plugins/beacon/skills/site-recon/SKILL.md` updates every
  tool at once — no drift, no generated copies to keep in sync.
- **Supporting files come for free.** A skill's `scripts/`, `references/`, `assets/` are inside
  the linked directory, so they resolve identically through the symlink.

Why symlinks are safe here (the decision was measured, not assumed):

- **No name collisions** — all 11 skill folder names are unique across the 7 plugins, so a flat
  `.agents/skills/<name>/` namespace is unambiguous.
- **Kiro's limits are met** — Kiro requires `name` ≤64 chars (lowercase/digits/hyphens, matching
  the folder) and `description` ≤1024 chars. Every skill already complies (longest description is
  941 chars; all names are already lowercase-hyphen and match their folders).

`scripts/sync-skills.sh --check` verifies the farm is complete and every link resolves; it runs
in CI so a new skill that isn't exposed fails the build. Run `scripts/sync-skills.sh` (no args) to
regenerate after adding/removing a skill, or on a machine where a checkout dropped symlinks.

> **Trade-off:** symlinks are not preserved by every Windows checkout or every `.zip`/tarball
> export. On macOS/Linux with git they are preserved. If you need a symlink-free distribution,
> switch `sync-skills.sh` to copy mode — but then a drift-detection check becomes mandatory
> (which is why we default to symlinks).

---

## Install into your own project — any harness (`skills` CLI)

The symlink farm above only helps someone who **clones this repo as their workspace**. To use the
skills inside *another* project — with Pi, OpenCode, Cline, Kiro, Codex, Cursor, Gemini CLI,
Copilot, Windsurf, Antigravity, Roo, Goose, or any of the 70+ agents the
[`skills` CLI](https://github.com/vercel-labs/skills) knows — install them the same way
[mattpocock/skills](https://github.com/mattpocock/skills) does:

```bash
npx skills@latest add neotherapper/claude-plugins                     # interactive picker
npx skills@latest add neotherapper/claude-plugins --skill '*' -a pi -a opencode -a cline -a kiro-cli -y
npx skills@latest add neotherapper/claude-plugins --skill site-recon -a opencode --copy -y
npx skills update                                                     # pull newer versions later
```

What we verified on 2026-09-05 (skills CLI `latest`, local clone as the source):

| Check | Result |
|---|---|
| `npx skills add <repo> --list` | finds all 14 canonical skills, no duplicates from the `.agents/`/`.kiro/` farms |
| `-a cline -a opencode` (default symlink mode) | canonical copy at `./.agents/skills/<skill>/`, with `scripts/` + `references/` |
| `-a pi -a kiro-cli` (symlink mode, agent **not** installed) | only `.agents/skills/` written; `.pi/` and `.kiro/` skipped (this repo's own symlink farm does not cover `.pi/` either) |
| `-a pi -a kiro-cli -a cline --copy` | real dirs at `./.pi/skills/`, `./.kiro/skills/`, `./.agents/skills/` |

So: the default is fine when the agent is installed on that machine; for CI, fresh machines, or
an undetected agent, add **`--copy`**. The CLI also writes a `skills-lock.json` in the target
project so `npx skills update` can track versions.

| Harness | `-a` | Project path | Global path (`-g`) |
|---|---|---|---|
| Pi | `pi` | `.pi/skills/` | `~/.pi/agent/skills/` |
| OpenCode | `opencode` | `.agents/skills/` | `~/.config/opencode/skills/` |
| Cline | `cline` | `.agents/skills/` | `~/.agents/skills/` |
| Kiro CLI | `kiro-cli` | `.kiro/skills/` | `~/.kiro/skills/` |
| Codex | `codex` | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `cursor` | `.agents/skills/` | `~/.cursor/skills/` |
| Gemini CLI | `gemini-cli` | `.agents/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `github-copilot` | `.agents/skills/` | `~/.copilot/skills/` |
| Antigravity | `antigravity` | `.agents/skills/` | `~/.gemini/antigravity/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Claude Code (if you prefer files over the marketplace) | `claude-code` | `.claude/skills/` | `~/.claude/skills/` |
| Anything else (DeepSeek, custom harness) | `universal` | `.agents/skills/` | `~/.config/agents/skills/` |

A harness with no CLI entry and no `.agents/skills/` support still works: copy
`plugins/<plugin>/skills/<skill>/` to the directory it scans for `SKILL.md`. A skill's `scripts/`
and `references/` live inside the folder and travel with it.

**Portability gap (open).** 9 of 14 `SKILL.md` files use `${CLAUDE_PLUGIN_ROOT}` — a Claude
Code-only variable. `AGENTS.md` tells agents to resolve `${CLAUDE_PLUGIN_ROOT}/skills/<s>/…` to the
skill's own folder, but several skills also need plugin-root files that a CLI copy never includes
(verified with a `--copy` install: no `technologies/`, `categories/`, `agents/`, or plugin
`scripts/` land in the target):

| Plugin | CLI install | Plugin-root dependencies not copied |
|---|---|---|
| namesmith, draftloom, idea-forge `generate` | self-contained | — |
| beacon (`site-recon`, `site-intel`, `site-fleet`) | degraded | `technologies/`, `scripts/core/har-reconstruct.py`, `templates/query-templates.md`, `.claude-plugin/plugin.json` |
| reframe (`site-redesign`) | degraded | `categories/`, `templates/` |
| idea-forge (`evaluate`) | non-functional | `agents/*.md` (11 research-agent prompts) |
| aegis (`site-security`) | non-functional | `scripts/coverage.py` |
| paidagogos (all three) | non-functional | `packs/`, `scripts/build-index.mjs`, `visual-kit` schemas + renderer |

Follow-up: rewrite those references as skill-relative paths and move (or fetch) the plugin-root
resources into each skill folder, starting with aegis and idea-forge `evaluate`, which are single
files.

**CI gate.** `scripts/check-skills-cli.sh` runs `npx skills add . --list` and fails if the set
of discovered skills differs from the canonical `plugins/*/skills/*` set — so a renamed folder or
a broken frontmatter can never silently drop a skill from the non-Claude install path.

---

## Per-tool install / setup

### Claude Code
```
/plugin marketplace add neotherapper/claude-plugins
/plugin install beacon@neotherapper-plugins
```
Skills, commands, agents, and hooks are auto-discovered from each plugin by directory convention.

### OpenAI Codex CLI
Codex reads the root `AGENTS.md` automatically. To expose the skills, point Codex at this repo (or
clone it as a workspace) — the skills are at `.agents/skills/`, which is one of Codex's documented
scan roots. There is **no** plugin/marketplace primitive in Codex, so skills + `AGENTS.md` (+ MCP
in `~/.codex/config.toml`) are the whole integration surface.

> **Disputed path:** the primary Codex docs say skills load from `.agents/skills` (repo root, cwd,
> parents), `$HOME/.agents/skills`, `/etc/codex/skills`. Some third-party posts instead cite
> `~/.codex/skills` / `.codex/skills`. We ship `.agents/skills/` (the documented-primary path);
> verify against your installed Codex version before relying on the alternatives.

### OpenCode
OpenCode reads the root `AGENTS.md` automatically and merges it into context. It discovers skills
natively from `.opencode/skills/` and **falls back** to `.agents/skills/` and `.claude/skills/`, so
the `.agents/skills/` farm we ship is picked up with no extra config. MCP servers go in
`opencode.json` under the `mcp` key.

> **Lane decision (why there's no custom OpenCode loader).** An earlier WIP shipped a bespoke
> OpenCode plugin (`.opencode/plugins/claude-plugins.js` + `registry.json` + a second,
> OpenCode-schema `plugins/<name>/plugin.json` per plugin) that scanned the nested layout and
> offered per-project enable/disable. It was retired: OpenCode's native `.agents/skills/` fallback
> already exposes every skill with zero custom code, and the duplicate per-plugin manifests had
> **drifted** from the canonical `.claude-plugin/plugin.json` versions (e.g. draftloom 0.1.0 vs
> 0.3.0), which is exactly the failure that running two lanes produces. One lane, no drift. If
> per-project enable/disable is wanted later, rebuild it as a loader that reads the *canonical*
> `.claude-plugin/plugin.json` — never a second manifest.

### Google Antigravity (CLI `agy` + IDE)
Antigravity reads the root `AGENTS.md`, workspace rules from `.agents/rules/`, and workspace skills
from `.agents/skills/` — all of which this repo ships. Workspace MCP config is `.agents/mcp_config.json`
(note: remote servers use `serverUrl`, not `url`). The CLI and IDE share the same `.agents/` workspace
conventions.

> **Disputed path:** the Antigravity **global** skills dir is reported as either
> `~/.gemini/config/skills/` or `~/.gemini/antigravity-cli/skills/` (sources conflict). The
> **workspace** path `<repo>/.agents/skills/` is consistent across every source — that's what we ship.

### AWS Kiro
Kiro reads a root `AGENTS.md` (always-included, no inclusion modes). Steering files in
`.kiro/steering/*.md` add project context (we ship a thin `inclusion: always` pointer back to
`AGENTS.md`). Skills load from `.kiro/skills/`; MCP servers from `.kiro/settings/mcp.json`
(remote servers use `url`). Import a skill folder via the IDE's "Agent Steering & Skills" panel, or
just open this repo as the workspace so `.kiro/skills/` is present.

### Cross-Tool: gh skill (Recommended)

`gh skill` from GitHub CLI installs and updates skills across ALL agents:

```sh
# Install a skill for a specific agent
gh skill install neotherapper/claude-plugins site-recon --agent claude-code
gh skill install neotherapper/claude-plugins site-recon --agent opencode

# Pin to a specific version
gh skill install neotherapper/claude-plugins site-recon@v0.7.1

# Update all skills across all agents
gh skill update --all

# Check for updates
gh skill update --dry-run
```

This replaces the symlink farm for users who prefer versioned, updatable skills. The symlink
farm (`scripts/sync-skills.sh`) remains available for repo-clone workflows.

---

## MCP servers

There is one canonical server list (`.mcp.json` — the `chrome-devtools` stdio server). The
`mcpServers` object shape is nearly identical across tools, but key names diverge, so we keep one
canonical file and mirror it per tool:

| Tool | File | Remote-URL key | Notes |
|---|---|---|---|
| Claude Code | `.mcp.json` | `type:"http"` + `url` | canonical |
| Codex | `~/.codex/config.toml` | `url` under `[mcp_servers.<n>]` | TOML, per-user (not a repo file) |
| OpenCode | `opencode.json` `mcp` | `type:"remote"` + `url` | |
| Antigravity | `.agents/mcp_config.json` | **`serverUrl`** | `disabled`, `disabledTools` supported |
| Kiro | `.kiro/settings/mcp.json` | `url` | `autoApprove`, `disabledTools` supported |

Our only server is a local stdio server (`chrome-devtools` via `npx`), whose shape is identical
everywhere, so `.agents/mcp_config.json` and `.kiro/settings/mcp.json` carry the same server
definition as `.mcp.json`.

---

## Adding a new plugin or skill (keep all tools working)

1. Add the plugin under `plugins/<name>/` with `.claude-plugin/plugin.json` and
   `skills/<skill>/SKILL.md` (keep `description` ≤1024 chars and `name` = folder, lowercase-hyphen,
   so Kiro accepts it).
2. Register it in `.claude-plugin/marketplace.json`.
3. Run `scripts/sync-skills.sh` to create the `.agents/skills/` and `.kiro/skills/` symlinks.
4. Run `scripts/validate-marketplace.sh` and `scripts/sync-skills.sh --check` (CI runs both).

That's it — `AGENTS.md` already covers the instructions layer for every tool, and the symlink
farm exposes the new skill to Codex, OpenCode, Antigravity, and Kiro automatically.

---

## Sources

Claude Code plugin/marketplace/skill/hook/MCP schema: `code.claude.com/docs/en/{plugins,
plugin-marketplaces,plugins-reference,skills,mcp,hooks}`. Codex: `developers.openai.com/codex/*`.
OpenCode: `opencode.ai/docs/*`. Antigravity: `antigravity.google/docs/*` + Google Cloud Community
write-ups. Kiro: `kiro.dev/docs/*`. Superpowers reference topology: `github.com/obra/superpowers`
and `github.com/obra/superpowers-marketplace`.
