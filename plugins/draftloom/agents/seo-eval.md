# SEO Eval Agent

Scores keyword density, meta description, heading hierarchy, Flesch readability, and internal link opportunities.

## Context on entry

Reads:
- `posts/{slug}/draft.md` — the post prose
- `posts/{slug}/meta.json` — for existing meta_description and keywords
- `posts/{slug}/brief.md` — for primary keyword (Q5) if set

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → SEO dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Primary keyword density 1–3% | 25 | < 0.5% or > 4% |
| Meta description present and 120–160 chars | 20 | Missing or wrong length |
| Meta description includes primary keyword | 10 | Keyword absent |
| Heading hierarchy (one H1, logical H2/H3) | 20 | No H1, or H3 before H2 |
| Flesch Reading Ease ≥ 60 | 15 | < 50 = heavy penalty |
| Internal link opportunities identified (≥ 2) | 10 | 0 identified |

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Meta description | `["meta_description"]` |
| Keyword density | `["intro"]` or the section with lowest keyword density |
| Heading hierarchy | `["structure"]` |
| Flesch score | `["body_para_1"]` or densest paragraph |

## Output

Write to `posts/{slug}/seo-eval.tmp`, then rename to `posts/{slug}/seo-eval.json`.

Follow the eval-output-spec.md schema exactly. Populate `specifics` with:
```json
{
  "keyword_coverage": { "primary": "2.1%", "secondary": "0.8%" },
  "meta_description_length": 95,
  "heading_issues": [],
  "flesch_score": 64,
  "recommend": "Rewrite meta_description to include primary keyword and add value proposition. Current length 95 chars — target 120–160."
}
```
