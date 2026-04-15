# Draftloom — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Draftloom guides users through writing viral blog posts. It captures a voice profile, proposes a section wireframe, drafts prose via a writer agent, evaluates across 4 dimensions (SEO, hook, voice, readability) in parallel, patches failing sections iteratively, and generates platform-specific distribution copy.

**Commands:** `/draftloom:setup` · `/draftloom:draft` · `/draftloom:eval`

**Version:** 0.1.0 — see `features.md` for v1 scope and v2+ roadmap.

---

## File map

```
plugins/draftloom/
├── _index.md              ← you are here
├── personas.md            ← who uses this plugin and how
├── features.md            ← v1 shipped features + v2+ roadmap
├── architecture.md        ← agent flow, file contracts, design decisions
│
├── .claude-plugin/
│   └── plugin.json        ← manifest: name, version, author, hooks, skills[], agents[]
│
├── skills/
│   ├── setup/
│   │   ├── SKILL.md                    ← /draftloom:setup — 3Q profile onboarding
│   │   └── references/
│   │       ├── interview-questions.md  ← 3 essential + 6 deferred questions
│   │       ├── profile-schema.md       ← full profile JSON schema + validation
│   │       └── storage-guide.md        ← project vs global ~/.draftloom/
│   ├── draft/
│   │   ├── SKILL.md                    ← /draftloom:draft — orchestrates full workflow
│   │   └── references/
│   │       ├── brief-questions.md      ← 4 mandatory + optional SEO questions
│   │       ├── layout-templates.md     ← section templates + wireframe editor rules
│   │       ├── workspace-schema.md     ← ★ complete file contract for all agents
│   │       ├── scoring-rubric.md       ← thresholds, routing, iteration rules
│   │       ├── eval-output-spec.md     ← standardised eval JSON schema
│   │       ├── distribution-guide.md   ← platform copy templates + char limits
│   │       └── turso-setup.md          ← optional Turso MCP backend
│   └── eval/
│       ├── SKILL.md                    ← /draftloom:eval — standalone scorer
│       └── references/
│           └── eval-guide.md           ← eval-only mode via orchestrator
│
├── agents/
│   ├── orchestrator.md       ← owns eval loop, dispatches all agents, aggregates scores
│   ├── writer.md             ← drafts (iter 1) and patches (iter 2+, sections_affected only)
│   ├── seo-eval.md           ← SEO specialist → seo-eval.json
│   ├── hook-eval.md          ← hook/virality specialist → hook-eval.json
│   ├── voice-eval.md         ← voice match specialist → voice-eval.json
│   ├── readability-eval.md   ← readability specialist → readability-eval.json
│   └── distribution.md       ← generates platform copy → distribution.json
│
└── hooks/
    └── hooks.json            ← SessionStart: hint /draftloom:setup if no profiles found
```

---

## How agents communicate

All state flows through files in `posts/{slug}/` — never through conversation history.

| File | Owner | Purpose |
|------|-------|---------|
| `draft.md` | writer | the post prose |
| `brief.md` | draft skill | locked during iteration loop |
| `meta.json` | draft skill | title, slug, profile_id, draft_status, timestamps |
| `scores.json` | orchestrator | aggregated scores per iteration |
| `*-eval.json` | each eval agent | raw output, overwrite per iteration |
| `state.json` | orchestrator | current_iteration, locked_brief flag |
| `session.json` | draft skill | checkpoint for session recovery |
| `distribution.json` | distribution agent | platform-specific copy |
| `iterations.log` | writer + orchestrator | append-only audit trail |

Eval agents write atomically (tmp → rename) — file presence signals completion. Orchestrator polls for all 4 `*-eval.json` files before aggregating.

---

## How to add a new skill

1. Create `skills/{name}/SKILL.md` with YAML frontmatter (`name`, `description` in third person with trigger phrases)
2. Keep SKILL.md lean: 1,500–2,000 words, imperative form, no second person
3. Add `references/` for detailed content loaded on demand
4. Add `examples/` for working samples
5. Register in `.claude-plugin/plugin.json` under `skills[]`
6. Add trigger phrases to `AGENTS.md` at repo root
7. Write a `.feature` file in `docs/plugins/draftloom/specs/`

---

## How to add a new eval agent

1. Create `agents/{name}-eval.md` following the contract in `skills/draft/references/eval-output-spec.md`
2. Output file: `{name}-eval.json` (atomic write, overwrites each iteration)
3. Required fields: `schema_version`, `agent`, `iteration`, `timestamp`, `score`, `feedback`, `sections_affected`, `suggestion_type`, `specifics`
4. Write completion signal by renaming from `.tmp` on finish
5. Add the agent to `orchestrator.md` parallel dispatch list
6. Add dimension to `scoring-rubric.md` with pass threshold and weight
7. Update `workspace-schema.md` to include the new `{name}-eval.json`
8. Add scenarios to `docs/plugins/draftloom/specs/eval.feature`

---

## Key rules

- **Never modify passing sections.** Writer patches only `sections_affected` from failing eval JSONs.
- **Aggregate score = minimum**, not average. No dimension papers over another.
- **File-based is primary.** Turso is optional redundancy — Turso failure never blocks iteration.
- **SKILL.md stays lean.** Move detail to `references/`. Target 1,500–2,000 words per skill.
- **Third-person descriptions.** Frontmatter `description` must start "This skill should be used when the user asks to..."
- **Workspace-schema.md is the contract.** Any new file added to the workspace must be documented there first.

---

## Related docs

- Design spec: `docs/superpowers/specs/2026-04-15-draftloom-design.md`
- Feature specs: `docs/plugins/draftloom/specs/`
- Personas: `plugins/draftloom/personas.md`
- Features: `plugins/draftloom/features.md`
- Architecture: `plugins/draftloom/architecture.md`
