# Idea Forge — Architecture

## Two-skill pipeline

```
/idea-forge:generate
  input:  ideas/_registry/master-index.yaml  (vault domain research)
  output: ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md

        ↓  seeds file (optional hand-off)

/idea-forge:evaluate
  input:  idea-seeds file  OR  inline idea description
  output: ideas/{slug}/research/*  +  ideas/{slug}/scored-card-v1.md
```

Each skill is independently invocable. `evaluate` accepts an inline idea description and proceeds without a seeds file.

---

## Evaluate stage flow

```
Stage 0  — Intake
           5 targeted questions, up to 3 interview passes
           Output: enriched idea brief (held in context)

Stage 1  — Parallel research (5 agents, concurrent)
           market-research     → market-research.json
           competition-research → competition-research.json
           data-research       → data-research.json
           distribution-research → distribution-research.json
           customer-voice      → customer-voice.json
           Orchestrator waits for all 5 files before advancing.

Stage 1.5 — Competitor deep-dive
           competitor-deep-dive → competitor-deep-dive.json
           Inputs: competition-research.json (competitor list)
           Outputs: Tranco rank, domain age, funding history per competitor

Stage 2  — Scoring
           scoring agent reads all research JSON files + lens file
           Output: scores.json (13 criteria, weighted, with evidence citations)

Stage 3  — Critic pass
           critic agent reads scores.json
           Flags over-confident scores, proposes adjustments
           Output: critic-review.json

Stage 4  — Orchestration
           orchestrator aggregates scores.json + critic-review.json
           Applies critic adjustments
           Computes weighted average
           Maps average to verdict (BET / BUILD / PIVOT / KILL)
           Output: scored-card-v1.md
```

---

## File contract

All workspace files live in the **user's project**, not in the plugin directory.

```
ideas/
├── _registry/
│   ├── master-index.yaml                          ← vault index, read by generate
│   └── idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md ← generate output, evaluate input
└── {slug}/
    └── research/
        ├── market-research.json
        ├── competition-research.json
        ├── data-research.json
        ├── distribution-research.json
        ├── customer-voice.json
        ├── competitor-deep-dive.json
        ├── scores.json
        ├── critic-review.json
        └── scored-card-v1.md
```

Each JSON file is owned by exactly one agent. Files are written atomically (tmp → rename). File presence signals completion — the orchestrator polls for all Stage 1 files before dispatching Stage 1.5.

The full schema for every research file is documented in `skills/evaluate/references/workspace-schema.md`. Any new file added to `ideas/{slug}/research/` must be documented there before the agent is wired in.

---

## Lens selection logic

The scoring agent selects one lens from `skills/evaluate/references/lenses/` before scoring. Lens selection is inferred from the idea brief using this priority order:

1. Founder explicitly states the business model in the intake interview.
2. Revenue model signals in the idea description (subscription → saas, transaction fee → marketplace, listing fee → directory, etc.).
3. Primary value delivery mechanism (data aggregation → directory, physical goods → ecommerce, utility → tool-site, media → content).
4. If ambiguous after all three passes, default to `tool-site.md` and flag the assumption in the scored card.

The selected lens is noted in `scores.json` under `lens_used`. The critic is permitted to challenge the lens choice; if overridden, the orchestrator re-runs scoring with the new lens before producing the final card.

Available lenses: `directory.md`, `ecommerce.md`, `saas.md`, `marketplace.md`, `content.md`, `tool-site.md`.

---

## Why skills are independently invocable

`generate` and `evaluate` are separate skills rather than a single pipeline for two reasons:

**Human review gate.** The seeds file is a deliberate pause point. Founders review and filter the shortlist before investing evaluation cycles. Running evaluate automatically on all generate output would waste research capacity on candidates the founder would have discarded.

**Different input modes.** Founders often come to `evaluate` with an idea they developed outside of generate — from a conversation, a customer call, or their own research. Requiring a seeds file would block the most common evaluate entry point.

The seeds file format is the only contract between skills. Its path pattern (`ideas/_registry/idea-seeds-{domain}-{date}-run-N.md`) must not change without updating both `SKILL.md` files and the `_index.md` pipeline diagram.
