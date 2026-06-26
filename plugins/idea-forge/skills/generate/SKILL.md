---
name: generate
version: "0.1.0"
description: "This skill should be used when the user wants to generate, discover, or surface business ideas FROM domain/vault research — not evaluate a specific idea they already have. Trigger phrases: 'find ideas in [domain]', 'what could I build in [space]?', 'generate business ideas from [domain] research', 'what gaps exist in [market]?', '/idea-forge:generate'. Does NOT trigger for evaluating a specific idea, 'should I build X?', or 'is there a market for X?' — those go to /idea-forge:evaluate."
---

# Generate

Surfaces business opportunity gaps from existing vault research using 5 gap patterns. Produces evaluator-ready idea seeds in three stages: generate candidates → light score → flesh out top ideas.

## When to Invoke

Trigger on any of:
- "Find ideas in [domain]"
- "What could I build in [space]?"
- "Generate business ideas from [domain] research"
- "What gaps exist in [market]?"
- "I've been researching [domain], what should I build?"
- "Explore the [domain] opportunity space"

Does NOT trigger for:
- Evaluating a specific idea (→ /idea-forge:evaluate)
- General market research without generative intent
- Knowledge vault lookups

## What It Does

1. Looks up existing vault research for the domain in `ideas/_registry/master-index.yaml`
2. Assembles a corpus from scored cards (or idea.md frontmatter for brainstorm-only domains)
3. Applies up to 5 gap patterns against the corpus (subset may run depending on corpus quality) to surface up to 14 opportunity candidates
4. Light-scores all candidates on 3 criteria — only ideas scoring ≥6/9 advance
5. Fleshes out top 3-5 candidates into evaluator-ready idea seeds
6. Saves all seeds to `ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md`

## How to Use

Load and follow the orchestration prompt:

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/generate/generator.md
```

The generator.md file contains the complete pipeline instructions for all four sections.

## Relationship to Evaluate

The generate and evaluate skills are designed to work in sequence:

```
/idea-forge:generate → idea-seeds-{domain}.md → /idea-forge:evaluate (per seed)
```

After generation, the user picks any seed and runs `/idea-forge:evaluate` on it.
