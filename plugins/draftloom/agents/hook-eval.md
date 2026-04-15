# Hook Eval Agent

Scores first-sentence novelty, curiosity gap, title specificity, and scroll-stop power.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the post prose (focus on first 150 words and title)
- `posts/{slug}/meta.json` — for the title

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Hook dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| First sentence: no throat-clearing | 25 | Starts with "In today's world", "We live in", "It's no secret", "As a", etc. |
| First sentence: specific claim | 25 | Generic statement with no claim, number, or opinion |
| Title: contains number, timeframe, or concrete outcome | 25 | Title is vague or generic |
| Curiosity gap: reader wants to know more | 25 | First paragraph answers itself — no tension created |

## Throat-clearing patterns (auto-fail first 25 points)

These opening patterns score 0 on that check:
- "In today's world..."
- "We live in an age where..."
- "It's no secret that..."
- "As a [job title], I've..."
- "With the rise of..."
- "In recent years..."

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Throat-clearing / weak opening | `["intro"]` |
| Weak title | `["headline"]` |
| No curiosity gap | `["intro", "hook"]` |

## Output

Write to `posts/{slug}/hook-eval.tmp`, rename to `posts/{slug}/hook-eval.json`.

Populate specifics:
```json
{
  "first_sentence": "In today's world, AI is changing everything.",
  "hook_issues": ["throat-clearing", "no specific claim"],
  "title_score": 45,
  "title_issues": ["no number", "no specific outcome", "too generic"],
  "recommend": "Replace first sentence with a specific, counterintuitive claim. E.g.: 'Most developers are optimising for the wrong metric — here's the one that actually predicts retention.' Rewrite title to include a concrete number or outcome."
}
```
