---
name: generate
description: "Generate new business ideas from the research already in the idea vault: surface gaps, unexplored niches, and opportunities in a domain, then turn the best into evaluator-ready seeds. Use when the user wants to go from research to ideas: 'find ideas in [domain]', 'what could I build in [space]?', 'what gaps exist in [market]?', 'given our research, what haven't we tried?', 'explore the [domain] opportunity space', 'what does the data suggest I should build?', or the /idea-forge:generate prefix. Not for judging a specific idea the user already has, including 'should I build X?' or 'is there a market for X?' (→ /idea-forge:evaluate). Not for understanding a market with no intent to generate ideas, or for tool lookups."
license: MIT
metadata:
  version: "0.2.0"
  author: Georgios Pilitsoglou
---

# Generate

> Paths in this skill are relative to the folder that contains this SKILL.md. Resolve them to absolute paths before reading a file or running a script.

Mines existing vault research for opportunity gaps using 5 gap patterns, light-scores the candidates, and fleshes out the strongest into seeds that feed straight into `/idea-forge:evaluate`:

```
/idea-forge:generate → ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md → /idea-forge:evaluate (per seed)
```

## Run it

Read `generator.md` and follow its four sections in order:
1. **Data layer:** domain lookup in `ideas/_registry/master-index.yaml`, corpus, de-dup, confirm with the user.
2. **Generation:** apply the gap patterns in `references/gap-patterns.md`.
3. **Light scoring:** three criteria; ideas scoring ≥ 6/9 advance.
4. **Seeds:** flesh out the top 3–5 into evaluator-ready seeds and save the seed file.

The run is done when the seed file is saved and the user has the shortlist with one line per seed. Then offer to evaluate whichever seed they pick.
