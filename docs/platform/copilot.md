# Beacon — GitHub Copilot Setup

## Install

```bash
git clone https://github.com/neotherapper/claude-plugins.git

# Copy skills to Copilot's discovery directory
mkdir -p .github/skills .github/agents
cp -r claude-plugins/plugins/beacon/skills/site-recon .github/skills/
cp -r claude-plugins/plugins/beacon/skills/site-intel .github/skills/
cp claude-plugins/plugins/beacon/agents/site-analyst.md .github/agents/
```

## Configure Copilot instructions

Add to `.github/copilot-instructions.md`:

```markdown
## Beacon Skills

When the user asks to analyse a site, map API surfaces, or research endpoints,
follow the skill in `.github/skills/site-recon/SKILL.md`.

When the user asks about a previously researched site, follow `.github/skills/site-intel/SKILL.md`.

All analysis output goes to `docs/research/{site-name}/`.
```

## Invoke the site analyst agent

```
@site-analyst Analyse https://example.com
@site-analyst What endpoints did we find on stripe.com?
```

## Tool name mapping

| Skill references | Copilot equivalent |
|-----------------|-------------------|
| `Read` | `view` |
| `Write` | `create` |
| `Edit` | `edit` |
| `Bash` | `bash` |
| `Grep` | `grep` |
| `Glob` | `glob` |
| `WebSearch` | `web_fetch` with search URL |
| `Task` (subagent) | `task` with `agent_type` |

## Usage tips

- Reference skills explicitly in chat: `Follow the site-recon skill for https://example.com`
- Use `@site-analyst` persona for structured analysis requests
- Copilot reads `.github/copilot-instructions.md` on every session — keep it concise
