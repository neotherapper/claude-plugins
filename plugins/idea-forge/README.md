# Idea Forge

> Two-stage business idea pipeline for Claude Code. Surface opportunity gaps and evaluate viability.

Idea Forge guides you through finding and validating business ideas — from domain research to a scored card with a BET / BUILD / PIVOT / KILL verdict.

## Commands

| Command | What it does |
|---------|-------------|
| `/idea-forge:generate` | Surface 3-5 evaluator-ready idea seeds from domain research |
| `/idea-forge:evaluate` | Score one idea through a 5-agent research pipeline and produce a verdict |

## Quick start

```
# 1. Generate ideas from a domain you've been researching
/idea-forge:generate

# 2. Evaluate a specific idea (seed or inline description)
/idea-forge:evaluate
```

## What you get

### Generate

Produces a seeds file at `ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md` with 3-5 evaluated ideas, each pre-scored on market gap, evidence quality, and differentiation.

### Evaluate

Runs 5 parallel research agents (market, competition, data, distribution, customer-voice) plus a competitor deep-dive, scores the idea across 13 weighted criteria, runs a critic pass, and produces:

```
ideas/{slug}/
├── scored-card-v1.md       — final verdict: BET / BUILD / PIVOT / KILL
└── research/
    ├── market.md
    ├── competition.md
    ├── data.md
    ├── distribution.md
    ├── customer-voice.md
    ├── competitor-profiles.md
    ├── scoring.md
    └── critic.md
```

## Verdict scale

| Verdict | Weighted score |
|---------|---------------|
| BET | > 75% |
| BUILD | 55–75% |
| PIVOT | 40–55% |
| KILL | < 40% |

## Business model lenses

The scoring rubric adapts to the idea's model type: directory, e-commerce, SaaS, marketplace, content, or tool-site.

## Requirements

- Claude Code with plugin support
- No external services required (file-based by default)
- Optional: nikai research CLI for enhanced research agent tooling

## Contributing

Found a bug or want to add a feature? Open an issue or PR on [GitHub](https://github.com/neotherapper/claude-plugins).
Contributor docs live in `docs/plugins/idea-forge/` in the repo.
