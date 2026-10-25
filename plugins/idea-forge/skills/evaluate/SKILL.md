---
name: evaluate
description: "Evaluate whether a specific business idea is worth building. Runs 6 research agents, 13-criterion evidence-based scoring, and a critic pass, then returns a BET/BUILD/PIVOT/KILL verdict with a scored card. Use when someone describes an idea (SaaS, marketplace, directory, e-commerce, content site, free tool site) and wants it evaluated, rated, validated, or honestly critiqued, or asks whether it's viable, worth building, or has market demand. That includes casual framings ('got this side project idea', 'thinking about building…') and the /idea-forge:evaluate prefix. Not for writing copy, PRDs, or pitch decks; tech-stack questions; knowledge vault lookups; or market research with no specific idea (finding ideas → /idea-forge:generate)."
license: MIT
metadata:
  version: "0.2.0"
  author: Georgios Pilitsoglou
---

# Evaluate

> Paths in this skill are relative to the folder that contains this SKILL.md. Resolve them to absolute paths before reading a file or running a script.

Evaluates one business idea, or a family of related ideas, through a staged pipeline:

1. A short founder interview.
2. Five parallel research agents (market, competition, data, distribution, customer voice), plus a competitor deep-dive.
3. Scoring on 13 weighted criteria through a business-model lens.
4. A critic pass.
5. A final verdict.

Every score cites the evidence behind it. Outputs land in the project's idea vault (`ideas/`).

## Run it

Read `evaluator.md` and follow it from Step 0. It owns the whole pipeline: the modes (single vs family), vault promotion rules, agent dispatch, and outputs.

## Files

| File | Role |
|------|------|
| `evaluator.md` | Orchestration: the steps, in order |
| `references/tool-status.md` | Which research CLIs work, their substitutes, worktree setup. Every research agent reads it first |
| `references/criteria.md` | The 13 criteria and their rubrics |
| `references/lenses/{directory,ecommerce,saas,marketplace,content,tool-site}.md` | Per-model rubric and weight overrides |
| `references/workspace-schema.md` | File contract for all agent outputs |
| `references/idea-card-template.md` · `references/ranking-entry-template.md` | Output formats |
| `agents/{market,competition,data,distribution}-research.md`, `agents/customer-voice.md` | Stage 1 research agents |
| `agents/competitor-deep-dive.md` | Stage 1.5, which runs once competition research returns |
| `agents/scoring.md` · `agents/critic.md` · `agents/orchestrator.md` | Stages 2–4 |
| `agents/family-evaluator.md` | Family mode |

## Outputs

- Scored card: `ideas/{slug}/scored-card-v{N}.md`. Ideas always get a folder; scored cards never live under `ideas/drafts/`.
- Research archive: `ideas/{slug}/research/v{N}/`
- Leaderboard: `ideas/_registry/ranking.md`
- New ideas before evaluation: `ideas/drafts/{slug}.md`, promoted to a folder when the evaluator first runs.
