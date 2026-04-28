# Idea Forge Workspace Schema

All evaluation output lives in `ideas/{slug}/research/` in the user's project.

## Files

| File | Owner | Written when |
|------|-------|-------------|
| `market.md` | market-research agent | Stage 1 |
| `competition.md` | competition-research agent | Stage 1 |
| `data.md` | data-research agent | Stage 1 |
| `distribution.md` | distribution-research agent | Stage 1 |
| `customer-voice.md` | customer-voice agent | Stage 1 |
| `competitor-profiles.md` | competitor-deep-dive agent | Stage 1.5 |
| `scoring.md` | scoring agent | Stage 2 |
| `critic.md` | critic agent | Stage 3 |
| `scored-card-v1.md` | orchestrator | Stage 4 (final output) |

## File contents

These are human-readable markdown research reports, not JSON. Each file contains the full narrative output of its agent, including findings, evidence, and analysis in prose and table format.

## Stage sequencing

- **Stage 1 (parallel):** market-research, competition-research, data-research, distribution-research, customer-voice run simultaneously
- **Stage 1.5 (sequential):** competitor-deep-dive runs after competition-research completes (needs COMPETITOR_DOMAINS from its report)
- **Stage 2:** scoring agent runs after all Stage 1 + 1.5 files exist
- **Stage 3:** critic agent runs after scores.json exists
- **Stage 4:** orchestrator runs after critic-review.json exists; writes idea-card.md

## Path rules

- Research files are always written to `ideas/{slug}/research/` — never to `ideas/drafts/`
- A draft at `ideas/drafts/{slug}.md` must be promoted to `ideas/{slug}/idea.md` before any research file is written
- All files are atomic writes (overwrite per run, not appended)
- Version N re-evaluations write to the same paths (overwriting previous run data)

## Adding a new agent

1. Create `agents/{name}-research.md` following the output contract above
2. Output file: `{name}-research.json`
3. Required JSON fields: `schema_version`, `agent`, `timestamp`, `findings[]`, `confidence`
4. Add the agent to `agents/orchestrator.md` Stage 1 parallel dispatch list
5. Add a scoring input reference in `skills/evaluate/references/criteria.md`
6. Update this file to document the new output file
