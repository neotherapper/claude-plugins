# Plugin System Guide

> How Claude Code plugins work in this repo — plugin.json schema, skill discovery, hooks lifecycle, agent patterns.

Read this before creating a new plugin. See `docs/GLOSSARY.md` for term definitions.

---

## Plugin folder layout

Every plugin follows this structure. Items marked `(ships)` are included in the installed package. Items marked `(repo-only)` live in `docs/plugins/{name}/` and are not distributed.

```
plugins/{name}/
├── README.md                     (ships) — user-facing overview
├── CHANGELOG.md                  (ships) — version history
│
├── .claude-plugin/
│   └── plugin.json               (ships) — manifest
│
├── skills/
│   └── {skill-name}/
│       ├── SKILL.md              (ships) — skill definition
│       └── references/           (ships) — on-demand detail
│           └── *.md
│
├── agents/
│   └── {agent-name}.md           (ships) — agent definition
│
├── hooks/
│   └── hooks.json                (ships) — event handlers
│
└── scripts/                      (ships) — utility scripts

docs/plugins/{name}/              (repo-only) — contributor docs
├── _index.md                     — AI contributor entrypoint (read first)
├── personas.md                   — who uses this plugin and how
├── features.md                   — v1 shipped features + v2+ roadmap
├── architecture.md               — agent flow, file contracts, design decisions
├── DECISIONS.md                  — architectural decisions with rationale
├── TESTING.md                    — how to validate against feature specs
└── specs/
    └── *.feature                 — Gherkin acceptance criteria
```

---

## plugin.json schema

```jsonc
{
  "name": "plugin-name",           // kebab-case, unique in marketplace
  "version": "0.1.0",             // semver
  "author": "github-handle",
  "description": "One-line description",
  "skills": [
    {
      "name": "skill-name",        // maps to skills/skill-name/SKILL.md
      "command": "/plugin:skill",  // slash command that invokes this skill
      "description": "Third-person description for skill discovery"
    }
  ],
  "agents": [
    {
      "name": "agent-name",        // maps to agents/agent-name.md
      "description": "What this agent does"
    }
  ],
  "hooks": {
    "SessionStart": "hooks/hooks.json"
  }
}
```

---

## Skill discovery

When a user types a slash command, Claude Code:

1. Reads `plugin.json` to find matching `command`
2. Loads the corresponding `SKILL.md` into context
3. Executes the workflow defined in SKILL.md

SKILL.md frontmatter `description` is also used for fuzzy discovery when the user describes intent without knowing the exact command.

**Skill file rules:**
- Frontmatter `description` must start: `"This skill should be used when the user asks to..."`
- Body: imperative steps, 1,500–2,000 words target
- Heavy content (schemas, rubrics, templates) → `references/` loaded on demand
- No second person in SKILL.md — write for the AI executing it, not the user

---

## Hooks lifecycle

Hooks are declared in `hooks/hooks.json` and run at specific Claude Code events.

```json
{
  "SessionStart": {
    "action": "check-profiles",
    "message": "If no .draftloom/profiles/ found, suggest /draftloom:setup"
  }
}
```

**Available hook points:**

| Hook | When it fires |
|------|--------------|
| `SessionStart` | When a new Claude Code session opens in a project |
| `FileCreate` | When a file matching a pattern is created |
| `CommandRun` | Before a skill command executes |

Hooks must be fast (< 1s) and non-blocking. Never use hooks for long-running operations.

---

## Agent patterns

### Specialist agent
One role, one output file. Receives focused context, writes JSON or Markdown result.

```
agents/seo-eval.md
→ reads: draft.md, brief.md, profile.json
→ writes: posts/{slug}/seo-eval.json (atomic: tmp → rename)
```

### Orchestrator agent
Owns a multi-step loop. Dispatches specialists, polls output files, aggregates, decides next step.

```
agents/orchestrator.md
→ dispatches: seo-eval, hook-eval, voice-eval, readability-eval (parallel)
→ polls: {name}-eval.json presence (atomic write = file present = done)
→ aggregates: scores.json
→ decides: patch loop or finalise
```

### Key agent rules
- Agents communicate through files, never conversation history
- Atomic writes: write to `.tmp`, rename on completion
- No shared output files — each agent writes its own file
- Orchestrator aggregates after all specialist outputs are present

---

## Adding a new plugin

1. Create `plugins/{name}/` following the folder layout above
2. Write `plugin.json` with at minimum: name, version, author, skills[]
3. Create at least one skill: `skills/{skill-name}/SKILL.md`
4. Create contributor docs: `docs/plugins/{name}/`
5. Write `_index.md` as the AI contributor entrypoint
6. Write Gherkin scenarios in `docs/plugins/{name}/specs/`
7. Add to the root `AGENTS.md` trigger phrase index
8. Add to the marketplace listing (see `docs/MARKETPLACE.md`)

---

## Adding a skill to an existing plugin

1. Create `skills/{skill-name}/SKILL.md` with correct frontmatter
2. Add `references/` for any content > 200 words
3. Register in `plugin.json` under `skills[]`
4. Add trigger phrases to the root `AGENTS.md`
5. Write `.feature` scenarios in `docs/plugins/{name}/specs/{skill-name}.feature`
6. Update `docs/plugins/{name}/_index.md` file map
7. Update `docs/plugins/{name}/features.md` v1 checklist

---

## Version policy

- `0.x.y` — pre-stable: breaking changes allowed between minor versions
- `1.x.y` — stable: breaking changes require major version bump
- Patch `x.x.y` — bug fixes and non-breaking additions only

Update `CHANGELOG.md` for every release. Tag releases in git: `{plugin-name}/v{version}`.

---

## File naming conventions

| File type | Pattern | Example |
|-----------|---------|---------|
| Skill definition | `SKILL.md` (uppercase) | `skills/draft/SKILL.md` |
| Agent definition | `{role}.md` | `agents/orchestrator.md` |
| Eval agent | `{dimension}-eval.md` | `agents/seo-eval.md` |
| Eval output | `{dimension}-eval.json` | `seo-eval.json` |
| Workspace state | lowercase, descriptive | `meta.json`, `state.json` |
| References | lowercase, hyphenated | `scoring-rubric.md` |
| Feature specs | `{skill-name}.feature` | `draft.feature` |
