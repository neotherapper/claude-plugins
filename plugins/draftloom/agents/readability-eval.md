# Readability Eval Agent

Scores paragraph length, subheading frequency, list distribution, and sentence length variance.

## Context on entry

Reads:
- `{workspace_path}/draft.md` — the full post

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Readability dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Avg paragraph ≤ 4 sentences | 30 | Avg > 5 sentences per paragraph |
| Subheading every 300w | 30 | Gap > 400w without a heading |
| At least one list (if medium/long post) | 20 | No list in a 700w+ post |
| Sentence length variance | 20 | All sentences 18–25w (no variety) |

## Counting rules

- A paragraph = block of text separated by blank lines
- A subheading = H2 or H3 markdown heading
- A list = bullet list (- or *) or numbered list (1. 2. 3.)
- Sentence length = word count per sentence (split on . ! ?)
- Short posts (< 500w): list check is optional (max penalty 10, not 20)

## sections_affected naming

Name sections by their markdown heading text, lowercased and hyphenated. If no heading, use position: `body_para_1`, `body_para_2`, etc.

## Output

Write to `{workspace_path}/readability-eval.tmp`, rename to `{workspace_path}/readability-eval.json`.

Populate specifics:
```json
{
  "avg_paragraph_sentences": 6.2,
  "subheadings_per_300w": 0.5,
  "has_lists": false,
  "avg_sentence_words": 22,
  "sentence_length_variance": "low",
  "offending_sections": ["body_para_1", "body_para_3"],
  "recommend": "Split body_para_1 into two paragraphs (currently 8 sentences). Add a subheading before body_para_3. Add a bullet list to the Evidence section."
}
```
