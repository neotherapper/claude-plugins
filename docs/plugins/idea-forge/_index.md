# Idea Forge — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Idea Forge is a two-stage business idea pipeline. It discovers opportunity gaps from domain research and scores each idea through a rigorous multi-agent evaluation, producing a final BET / BUILD / PIVOT / KILL verdict.

**Commands:** `/idea-forge:generate` · `/idea-forge:evaluate`

**Pipeline:** `generate` → `ideas/_registry/idea-seeds-{domain}-{date}.md` → `evaluate`

**Version:** 0.1.0 — see `features.md` for v1 scope and v2+ roadmap.

---

## File map

```
plugins/idea-forge/
├── _index.md              ← you are here
├── personas.md            ← who uses this plugin and how
├── features.md            ← v1 shipped features + v2+ roadmap
├── architecture.md        ← pipeline flow, file contracts, design decisions
│
├── .claude-plugin/
│   └── plugin.json        ← manifest: name, version, author, description, keywords
│
├── skills/
│   ├── generate/
│   │   ├── SKILL.md                    ← /idea-forge:generate — surfaces opportunity seeds
│   │   ├── generator.md                ← main orchestration prompt (loaded on demand)
│   │   └── references/
│   │       └── gap-patterns.md         ← 5 gap patterns used to surface candidates
│   └── evaluate/
│       ├── SKILL.md                    ← /idea-forge:evaluate — scores one idea seed
│       ├── evaluator.md                ← main orchestration prompt (loaded on demand)
│       └── references/
│           ├── criteria.md             ← 13 weighted scoring criteria with rubrics
│           ├── workspace-schema.md     ← ★ complete file contract for all agents
│           ├── idea-card-template.md   ← output template (scored card + verdict)
│           └── lenses/
│               ├── directory.md        ← scoring lens: directory model
│               ├── ecommerce.md        ← scoring lens: e-commerce model
│               ├── saas.md             ← scoring lens: SaaS model
│               ├── marketplace.md      ← scoring lens: marketplace model
│               ├── content.md          ← scoring lens: content model
│               └── tool-site.md        ← scoring lens: tool/micro-site model
│
├── agents/
│   ├── orchestrator.md           ← coordinates Stage 1 agents, runs scoring + critic
│   ├── market-research.md        ← Stage 1: demand signals → market.md
│   ├── competition-research.md   ← Stage 1: competitive landscape → competition.md
│   ├── data-research.md          ← Stage 1: data availability → data.md
│   ├── distribution-research.md  ← Stage 1: acquisition channels → distribution.md
│   ├── customer-voice.md         ← Stage 1: customer language → customer-voice.md
│   ├── competitor-deep-dive.md   ← Stage 1.5: Tranco rank, domain age, funding
│   ├── scoring.md                ← Stage 2: scores 13 criteria against lens rubric
│   ├── critic.md                 ← Stage 3: stress-tests scores, flags over-confidence
│   └── family-evaluator.md       ← Mode B: evaluates idea fit within a product family
│
└── hooks/
    └── hooks.json                ← (future) hint /idea-forge:generate if vault is stale
```

**Workspace** (lives in the user's project, not in the plugin):

```
ideas/
├── _registry/
│   ├── master-index.yaml                         ← vault of scored cards by domain
│   └── idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md ← generate output, evaluate input
└── {slug}/
    └── research/                                  ← raw agent outputs per evaluated idea
```

---

## How the two skills connect

```
/idea-forge:generate
  └─ reads    ideas/_registry/master-index.yaml
  └─ writes   ideas/_registry/idea-seeds-{domain}-{date}-run-N.md

/idea-forge:evaluate
  └─ reads    ideas/_registry/idea-seeds-{domain}-{date}-run-N.md  (or inline description)
  └─ writes   ideas/{slug}/research/*.md
  └─ produces scored idea card with BET / BUILD / PIVOT / KILL verdict
```

Each skill is independently invocable — `evaluate` accepts an inline idea description if no seeds file exists.

---

## How agents communicate

All state flows through files in `ideas/{slug}/research/` — never through conversation history.

| File | Owner | Purpose |
|------|-------|---------|
| `market.md` | market-research agent | demand signals, TAM proxies |
| `competition.md` | competition-research agent | competitor list, moat gaps |
| `data.md` | data-research agent | data source availability |
| `distribution.md` | distribution-research agent | acquisition channel viability |
| `customer-voice.md` | customer-voice agent | language, pain phrasing |
| `competitor-profiles.md` | competitor-deep-dive agent | Tranco rank, domain age, funding |
| `scoring.md` | scoring agent | 13-criteria weighted scores + evidence |
| `critic.md` | critic agent | stress-tested adjustments + flags |
| `scored-card-v1.md` | orchestrator | final output: scored card + verdict |

Stage 1 agents run in parallel. Orchestrator waits for all 5 research `.md` files before dispatching Stage 1.5 and Stage 2.

---

## How to add a new skill

1. Create `skills/{name}/SKILL.md` with YAML frontmatter (`name`, `description` in third person with trigger phrases)
2. Keep SKILL.md lean: 1,500–2,000 words, imperative form
3. Add `references/` for detailed content loaded on demand
4. The runtime discovers the skill automatically via SKILL.md — no registration needed in `plugin.json`
5. Add trigger phrases to `AGENTS.md` at repo root
6. Write a `.feature` file in `docs/plugins/idea-forge/specs/`

---

## How to add a new research agent

1. Create `agents/{name}-research.md` following the output contract in `skills/evaluate/references/workspace-schema.md`
2. Output file: `{name}.md` (atomic write, overwrites per run)
3. Required sections: agent name, timestamp, findings, confidence
4. Add the agent to `orchestrator.md` Stage 1 parallel dispatch list
5. Add a scoring input reference in `skills/evaluate/references/criteria.md`
6. Update `workspace-schema.md` to document the new output file
7. Add scenarios to `docs/plugins/idea-forge/specs/evaluate.feature`

---

## Key rules

- **Generate feeds evaluate.** Seeds file path format is the contract between skills — never change it without updating both skills.
- **Evaluate is standalone.** It must work from an inline description with no seeds file present.
- **Lens determines rubric.** Scoring agent selects the lens from `references/lenses/` based on the inferred business model — never apply a generic rubric.
- **Critic is mandatory.** Scores without a critic pass are not final.
- **Verdict mapping is strict.** BET (>75%), BUILD (55–75%), PIVOT (40–55%), KILL (<40%). Based on weighted average / 5.0. No override without explicit founder justification.
- **SKILL.md stays lean.** Move orchestration detail to `{skill}/evaluator.md` or `{skill}/generator.md`, loaded on demand.
- **Workspace-schema.md is the contract.** Any new file added to `ideas/{slug}/research/` must be documented there first.

---

## Related docs

| Doc | Location |
|-----|----------|
| Feature specs (.feature) | `docs/plugins/idea-forge/specs/` |
| Features & roadmap | `docs/plugins/idea-forge/features.md` |
| Personas | `docs/plugins/idea-forge/personas.md` |
| Architecture detail | `docs/plugins/idea-forge/architecture.md` |
