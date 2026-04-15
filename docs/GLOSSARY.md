# Plugin System Glossary

> Shared vocabulary for contributors across all plugins in this repo.

---

## Plugin

A self-contained unit of Claude Code functionality, installed from the marketplace or locally. A plugin lives in `plugins/{name}/` and is declared via `plugin.json`. It ships one or more skills, may include agents, and optionally registers hooks.

---

## plugin.json

The manifest file at `plugins/{name}/.claude-plugin/plugin.json`. Declares the plugin's `name`, `version`, `author`, registered `skills[]`, `agents[]`, and `hooks`. This is the entrypoint Claude Code reads at install time.

---

## Skill

A reusable workflow invoked by a slash command (e.g. `/draftloom:draft`). A skill is defined by a `SKILL.md` file at `plugins/{name}/skills/{skill-name}/SKILL.md`. Skills are stateless — they orchestrate a workflow using agents and file state.

---

## SKILL.md

The definition file for a skill. Contains YAML frontmatter (`name`, `description` in third person starting with "This skill should be used when the user asks to..."), followed by the workflow in imperative steps. Target 1,500–2,000 words. Longer content moves to `references/`.

---

## references/

A folder at `plugins/{name}/skills/{skill-name}/references/`. Contains detailed content loaded on demand as a skill progresses — schemas, rubrics, templates, API setup guides. Not loaded into context on every invocation.

---

## Agent

A specialist sub-process defined by a Markdown file in `plugins/{name}/agents/`. An agent receives focused context, performs one role, and writes output to a file. Agents do not share state through conversation history — all state flows through the filesystem.

---

## Orchestrator

A special agent that owns the multi-step loop within a workflow. The orchestrator dispatches other agents, polls for their output files, aggregates results, and decides whether to loop or finalise. Draftloom's `orchestrator.md` is the canonical example.

---

## Workspace

The set of files created by a plugin for a single user session. For Draftloom: `posts/{slug}/`. For Beacon: `docs/research/{site}/`. The workspace schema (all files, owners, purpose) is documented in each plugin's architecture files.

---

## Hook

A shell or Claude Code event handler registered in `hooks/hooks.json`. Common hook: `SessionStart` — runs when a new Claude Code session opens. Used to surface hints (e.g. "no profile found, run /draftloom:setup").

---

## Profile

A named JSON file persisting user preferences for a plugin. In Draftloom, a voice profile captures tone adjectives, style attributes, and brand voice examples. Stored at `.draftloom/profiles/{name}.json` (project-level) or `~/.draftloom/profiles/{name}.json` (global).

---

## Eval agent

A specialist agent that scores a piece of content on one dimension and writes a JSON report. In Draftloom: `seo-eval.md`, `hook-eval.md`, `voice-eval.md`, `readability-eval.md`. Each writes `{name}-eval.json` atomically (tmp → rename).

---

## Eval loop

The iterative cycle of: draft → parallel eval → aggregate score → patch failing sections → re-eval. Continues until aggregate_score ≥ 75 or the maximum iteration count is reached.

---

## aggregate_score

The final combined score for a post evaluation. Calculated as the **minimum** across all eval dimensions, not the average. Ensures no dimension can mask a failure in another.

---

## sections_affected

A JSON array field in each `*-eval.json`. Lists the specific document sections that caused a failing score. The writer agent reads this field to patch only those sections, leaving passing sections unchanged.

---

## Atomic write

The file write pattern used by eval agents: write to `{name}-eval.tmp`, then rename to `{name}-eval.json` on completion. POSIX rename is atomic — the orchestrator polls for file presence rather than checking write status. File present = write complete.

---

## Tech-pack

A framework-specific knowledge guide in `plugins/beacon/technologies/{framework}/{version}.md`. Tells the site-analyst exactly where to look for endpoints, routes, and API surfaces in a given framework version.

---

## Distribution copy

Platform-specific promotional text generated at the end of a Draftloom draft: X (Twitter) hook, LinkedIn opener, email subject line, newsletter blurb. Written to `distribution.json`.

---

## Session recovery

The ability to resume a partially-complete workflow after the Claude Code session is closed. Implemented via a `session.json` checkpoint file. On next invocation, the skill detects the checkpoint and offers to continue.

---

## Feature file (.feature)

A Gherkin BDD specification file in `docs/plugins/{name}/specs/`. Describes expected plugin behaviour in Given/When/Then scenarios. Used as acceptance criteria for implementation and as the basis for the TESTING.md guide.
