# Plugin Workspace Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure `claude-plugins` as a plugin-building workspace with chrome-devtools MCP, project-level plugin activation, and intent-routing in AGENTS.md.

**Architecture:** Three files — `.mcp.json` wires the chrome-devtools MCP server, `.claude/settings.json` enables `plugin-dev` and `agent-skills` plugins for this project, and `AGENTS.md` gets a new Plugin Development section that routes plugin-building intents to the right tools.

**Tech Stack:** JSON (config), Markdown (AGENTS.md), Claude Code plugin system

---

### Task 1: Create branch

**Files:**
- No file changes — branch creation only

- [ ] **Step 1: Create and switch to the feature branch**

```bash
git checkout -b feat/plugin-workspace-setup
```

Expected output:
```
Switched to a new branch 'feat/plugin-workspace-setup'
```

- [ ] **Step 2: Verify you are on the correct branch**

```bash
git branch --show-current
```

Expected output:
```
feat/plugin-workspace-setup
```

---

### Task 2: Create `.mcp.json`

**Files:**
- Create: `.mcp.json`

- [ ] **Step 1: Verify `.mcp.json` does not already exist**

```bash
ls .mcp.json 2>/dev/null && echo "EXISTS" || echo "DOES NOT EXIST"
```

Expected output:
```
DOES NOT EXIST
```

- [ ] **Step 2: Create `.mcp.json`**

Create the file at `.mcp.json` with this exact content:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "type": "stdio",
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest", "--autoConnect"]
    }
  }
}
```

- [ ] **Step 3: Validate JSON is well-formed**

```bash
python3 -m json.tool .mcp.json
```

Expected output:
```json
{
    "mcpServers": {
        "chrome-devtools": {
            "type": "stdio",
            "command": "npx",
            "args": [
                "chrome-devtools-mcp@latest",
                "--autoConnect"
            ]
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add .mcp.json
git commit -m "feat(workspace): add chrome-devtools MCP server config"
```

---

### Task 3: Create `.claude/settings.json`

**Files:**
- Create: `.claude/settings.json`

Note: `.claude/settings.local.json` already exists with project-specific `allow` permissions. This task creates the committed `settings.json` alongside it — the local file is for machine-specific permissions, this file is for shared project configuration.

- [ ] **Step 1: Verify `.claude/settings.json` does not already exist**

```bash
ls .claude/settings.json 2>/dev/null && echo "EXISTS" || echo "DOES NOT EXIST"
```

Expected output:
```
DOES NOT EXIST
```

- [ ] **Step 2: Create `.claude/settings.json`**

Create the file at `.claude/settings.json` with this exact content:

```json
{
  "enabledPlugins": {
    "plugin-dev@claude-plugins-official": true,
    "agent-skills@addy-agent-skills": true
  }
}
```

- [ ] **Step 3: Validate JSON is well-formed**

```bash
python3 -m json.tool .claude/settings.json
```

Expected output:
```json
{
    "enabledPlugins": {
        "plugin-dev@claude-plugins-official": true,
        "agent-skills@addy-agent-skills": true
    }
}
```

- [ ] **Step 4: Verify `.claude/settings.local.json` is untouched**

```bash
python3 -m json.tool .claude/settings.local.json
```

Expected: the existing permissions object prints without error (no merge or overwrite happened).

- [ ] **Step 5: Commit**

```bash
git add .claude/settings.json
git commit -m "feat(workspace): enable plugin-dev and agent-skills plugins for this project"
```

---

### Task 4: Update `AGENTS.md`

**Files:**
- Modify: `AGENTS.md`

Add a new `## Plugin Development` section at the end of the file. This section maps plugin-building intents to the specific tools now active in this workspace.

- [ ] **Step 1: Append the Plugin Development section to `AGENTS.md`**

Add the following to the end of `AGENTS.md` (after the existing `## Anti-Rationalizations` section):

```markdown

## Plugin Development

This repo is also a plugin-building workspace. The following plugins are active for this purpose (see `.claude/settings.json`):

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
| "create a skill" / "write a new skill" | `skill-creator@claude-plugins-official` skill |

### Execution Rules (Plugin Development)

1. When a plugin-building intent matches the table above, load and follow the mapped skill before doing any implementation work
2. The chrome-devtools MCP is available for browser testing — use it via `agent-skills:browser-testing-with-devtools`, not directly
3. All new plugin code goes in `plugins/<plugin-name>/` — never in `docs/` or project root
4. Specs for new plugins go in `docs/superpowers/specs/` before any implementation begins
```

- [ ] **Step 2: Verify the section was appended correctly**

```bash
tail -40 AGENTS.md
```

Expected: the output ends with the `### Execution Rules (Plugin Development)` block and its 3 rules.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): add plugin development intent routing and workspace tool map"
```

---

### Task 5: Final verification and push

**Files:**
- No file changes

- [ ] **Step 1: Verify all three target files exist**

```bash
ls .mcp.json .claude/settings.json AGENTS.md
```

Expected output:
```
.mcp.json
.claude/settings.json
AGENTS.md
```

- [ ] **Step 2: Verify branch commit history**

```bash
git log --oneline main..HEAD
```

Expected output (3 commits):
```
<hash> docs(agents): add plugin development intent routing and workspace tool map
<hash> feat(workspace): enable plugin-dev and agent-skills plugins for this project
<hash> feat(workspace): add chrome-devtools MCP server config
```

- [ ] **Step 3: Check working tree is clean**

```bash
git status
```

Expected output:
```
On branch feat/plugin-workspace-setup
nothing to commit, working tree clean
```

- [ ] **Step 4: Push branch**

```bash
git push -u origin feat/plugin-workspace-setup
```

Expected output:
```
Branch 'feat/plugin-workspace-setup' set up to track remote branch 'feat/plugin-workspace-setup' from 'origin'.
```
