---
name: evaluate
version: "0.1.0"
description: "Invoke this skill for ANY business idea validation, evaluation, or viability check. Key trigger signals: 'should I build', 'is this worth building', 'validate this', 'good idea?', 'rate my startup', 'honest feedback on my startup', 'is there market demand', 'wondering if the market is there', 'is this worth starting', 'any thoughts on viability', 'evaluate', 'got this side project idea', 'thinking about building', 'is this viable'. Also triggers for the /idea-forge:evaluate prefix and any message where someone describes a SaaS, marketplace, directory, e-commerce, content site, or free tool idea and wants to know whether it's worth pursuing. Runs 5+ research agents + scoring + critic pipeline and returns BET/BUILD/PIVOT/KILL verdict. Does NOT trigger for: writing copy/PRDs/pitch decks, filling in document sections, tech stack questions, knowledge vault lookups, general market research without a specific idea to evaluate."
---

# Evaluate

Evaluates business ideas across 6 model types (directory, e-commerce, SaaS, marketplace, content, tool-site) through a rigorous multi-stage research and scoring pipeline with lens-specific rubrics.

## When to Invoke

Trigger on any of:
- "evaluate idea", "score idea", "rate idea", "validate idea"
- "/idea-forge:evaluate"
- "is this a good idea?", "should I build X?", "is there a market for X?"
- "what are the chances of success?", "give me honest feedback on this"
- "evaluate this e-commerce idea", "rate this SaaS concept"
- "is this marketplace viable?", "should I build a directory for X?"
- User describes any business concept and asks for assessment or feedback

## What It Does

1. Receives an idea description (1-2 paragraphs)
2. Asks 5 targeted questions about founder fit and early validation (Criteria 11 + 13)
3. Runs 5 parallel research agents: market demand, competition (with funding intelligence + tech stack detection), data availability, distribution (with traction channel fit), and customer voice
4. Runs a competitor deep-dive agent: Tranco rank, domain age, page count, robots.txt signals, HTTP headers, funding history
5. Scores the idea across 13 weighted criteria with evidence — source attribution required for all claims
6. Classifies PMF archetype (Hair on Fire / Hard Fact / Future Vision) and checks for tarpit patterns
7. Stress-tests scores through a critic agent to catch bias
8. Produces a final scored card with DVF assessment, competitor landscape, feature gap matrix, traction channel ranking, customer development stage, and verdict (BET / BUILD / PIVOT / KILL)
9. Archives all raw research data to `ideas/{slug}/research/` for future reference

## How to Use

Load and follow the orchestration prompt:

```
Read skills/evaluate/evaluator.md
```

The evaluator.md file contains the complete pipeline instructions, agent dispatch logic, and output handling.

## Key Files

| File | Purpose |
|------|---------|
| `evaluator.md` | Main orchestration — read this to run an evaluation |
| `references/criteria.md` | 13 scoring criteria with rubrics |
| `references/workspace-schema.md` | Complete file contract for all agent outputs |
| `references/idea-card-template.md` | Output template for scored cards |
| `references/ranking-entry-template.md` | Leaderboard row format |
| `references/lenses/directory.md` | Lens: directory business model rubrics |
| `references/lenses/ecommerce.md` | Lens: e-commerce business model rubrics |
| `references/lenses/saas.md` | Lens: SaaS business model rubrics |
| `references/lenses/marketplace.md` | Lens: marketplace business model rubrics |
| `references/lenses/content.md` | Lens: content/reference business model rubrics |
| `references/lenses/tool-site.md` | Lens: free web utility (calculator/converter/generator) rubrics |

## Agents

All agent prompts live in `agents/` at the plugin root:

| Agent | Purpose |
|-------|---------|
| `agents/market-research.md` | Stage 1: Market research agent |
| `agents/competition-research.md` | Stage 1: Competition research agent |
| `agents/data-research.md` | Stage 1: Data availability agent |
| `agents/distribution-research.md` | Stage 1: Distribution opportunity agent |
| `agents/customer-voice.md` | Stage 1: Synthetic interview — pain signals from public sources |
| `agents/competitor-deep-dive.md` | Stage 1.5: Deep competitor profiling agent |
| `agents/scoring.md` | Stage 2: Evidence-based scoring agent |
| `agents/critic.md` | Stage 3: Bias detection and score adjustment |
| `agents/orchestrator.md` | Stage 4: Final aggregation and verdict |
| `agents/family-evaluator.md` | Family mode: evaluate a cluster of related ideas |

## Output Location

- Individual idea cards: `ideas/{slug}/scored-card-v{N}.md` (always a folder)
- Research archives: `ideas/{slug}/research/`
- Rankings leaderboard: `ideas/_registry/ranking.md`
- New ideas before evaluation: `ideas/drafts/{slug}.md` (promoted to folder when the evaluator first runs)
