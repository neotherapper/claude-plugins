# Beacon — Gemini CLI Setup

## Install as skills (recommended)

Gemini CLI has a native skills system. Skills auto-discover from `.gemini/skills/` and activate on-demand when they match your task.

```bash
# Install beacon skills globally
gemini skills install https://github.com/neotherapper/claude-plugins.git \
  --path plugins/beacon/skills

# Or install for this workspace only
gemini skills install https://github.com/neotherapper/claude-plugins.git \
  --path plugins/beacon/skills \
  --scope workspace
```

Verify:
```
/skills list
```

Once installed, just describe what you want:
```
analyse https://example.com
map the API surface of stripe.com
what endpoints does shopify have?
```

Gemini will activate the matching skill and follow its workflow.

## Alternative: GEMINI.md persistent context

For always-on context (loaded every session), add to your `GEMINI.md`:

```markdown
@plugins/beacon/skills/site-recon/SKILL.md
@plugins/beacon/skills/site-intel/SKILL.md
```

Or clone the repo and import locally:
```bash
git clone https://github.com/neotherapper/claude-plugins.git
```

Then in `GEMINI.md`:
```markdown
@claude-plugins/plugins/beacon/skills/site-recon/SKILL.md
@claude-plugins/plugins/beacon/skills/site-intel/SKILL.md
```

## Tool name mapping

Beacon skills use Claude Code tool names. Gemini CLI uses these equivalents:

| Skill references | Gemini CLI tool |
|-----------------|----------------|
| `Read` | `read_file` |
| `Write` | `write_file` |
| `Edit` | `replace` |
| `Bash` | `run_shell_command` |
| `Grep` | `grep_search` |
| `Glob` | `glob` |
| `WebSearch` | `google_web_search` |
| `WebFetch` | `web_fetch` |
| `Task` (subagent) | Not supported — Gemini runs phases sequentially |

Gemini will adapt tool names automatically when following skill instructions.

## MCP integration

Several Beacon probes work better with MCP tools:

```json
// ~/.gemini/config.json
{
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": { "FIRECRAWL_API_KEY": "YOUR_KEY" }
    },
    "wappalyzer": {
      "command": "npx",
      "args": ["-y", "@wappalyzer/mcp"],
      "env": { "WAPPALYZER_API_KEY": "YOUR_KEY" }
    }
  }
}
```

Both are optional — Beacon degrades gracefully with `[TOOL-UNAVAILABLE:name]` signals.

## Usage tips

- Skills activate on-demand: no need to mention "beacon" or "site-recon" explicitly
- Gemini doesn't support subagents — multi-phase analysis runs sequentially in one session
- Output goes to `docs/research/{site-name}/` in your working directory
