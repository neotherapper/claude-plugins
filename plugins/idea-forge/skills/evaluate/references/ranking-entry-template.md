# Ranking Entry Template

Each evaluated idea gets a row in the ranking leaderboard at `ideas/_registry/ranking.md`.

## Leaderboard Format

The ranking file uses this structure:

```markdown
# Idea Rankings

Ideas ranked by weighted evaluation score. Each idea was evaluated through the multi-stage pipeline (Research > Deep-Dive > Score > Critic > Orchestrate) with business-model-specific lens weighting.

| Rank | Idea | Model | Verdict | Score | Top Strength | Top Weakness | Date |
|------|------|-------|---------|-------|-------------|-------------|------|
| 1 | {idea_name} | {model} | {VERDICT} | {percentage}% | {strength} | {weakness} | {YYYY-MM-DD} |
| 2 | {idea_name} | {model} | {VERDICT} | {percentage}% | {strength} | {weakness} | {YYYY-MM-DD} |
```

## Row Format

```
| {rank} | [{idea_name}](ideas/{slug}/idea.md) | {model} | {VERDICT} | {percentage}% | {top_strength} | {top_weakness} | {YYYY-MM-DD} |
```

## Rules

1. Sort by score descending (highest first)
2. Rank is assigned by position (re-rank when adding new entries)
3. Link the idea name to its scored card file
4. Model column shows: directory, ecommerce, saas, marketplace, or content
5. Top Strength and Top Weakness should each be under 5 words
6. When adding a new entry, insert it at the correct position and re-number all ranks

## Creating the File

If `ranking.md` does not exist yet, create it with the header:

```markdown
# Idea Rankings

Ideas ranked by weighted evaluation score. Each idea was evaluated through the multi-stage pipeline (Research > Deep-Dive > Score > Critic > Orchestrate) with business-model-specific lens weighting.

| Rank | Idea | Model | Verdict | Score | Top Strength | Top Weakness | Date |
|------|------|-------|---------|-------|-------------|-------------|------|
```

Then append the first entry.
