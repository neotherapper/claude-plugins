# Beacon — OpenCode / Codex Setup

## Setup

OpenCode and Codex use `AGENTS.md` as their system prompt and activate skills via intent matching.

```bash
git clone https://github.com/neotherapper/claude-plugins.git
```

Copy the top-level `AGENTS.md` to your project, or merge into your existing one:

```bash
cp claude-plugins/AGENTS.md AGENTS.md
```

Or add these lines to your existing `AGENTS.md`:

```markdown
## Beacon Skills

@claude-plugins/plugins/beacon/skills/site-recon/SKILL.md
@claude-plugins/plugins/beacon/skills/site-intel/SKILL.md

When user asks to analyse a site or map API surfaces → follow site-recon skill.
When user asks about a known site → follow site-intel skill.
```

## Intent → skill mapping

| User request | Skill |
|-------------|-------|
| "analyse https://..." | site-recon |
| "map API surface of..." | site-recon |
| "research this site" | site-recon |
| "tell me about [known site]" | site-intel |
| "load research for..." | site-intel |

## Subagent dispatch (Codex)

Enable in `~/.codex/config.toml`:
```toml
[features]
multi_agent = true
```

Then Beacon can dispatch `spawn_agent` for parallel OSINT and JS analysis phases.

## Tool name mapping

| Skill references | Codex equivalent |
|-----------------|-----------------|
| `Read`, `Write`, `Edit` | Native file tools |
| `Bash` | Native shell tools |
| `Task` (subagent) | `spawn_agent` |
| `TodoWrite` | `update_plan` |
| `Skill` | Skills load natively |

## Usage tips

- Skills load natively in Codex — the `@` reference in AGENTS.md is sufficient
- `spawn_agent` requires `multi_agent = true` in config
- Output goes to `docs/research/{site-name}/` in your working directory
- In Codex Desktop (sandbox): branch operations may be blocked — commit work and use App UI controls
