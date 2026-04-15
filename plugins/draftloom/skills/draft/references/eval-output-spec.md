# Eval Output Specification

Contract for all eval agent output files. Every eval agent must write a file matching this schema exactly.

## Required fields

```json
{
  "schema_version": "1.0",
  "agent": "seo-eval",
  "iteration": 2,
  "timestamp": "2026-04-15T10:30:00Z",
  "score": 78,
  "feedback": "Keyword density improved. Meta description still too generic.",
  "sections_affected": ["meta_description"],
  "suggestion_type": "enhance",
  "specifics": { "...": "see per-dimension examples below" }
}
```

## Field definitions

| Field | Type | Rules |
|-------|------|-------|
| `schema_version` | string | Always `"1.0"` in v1 |
| `agent` | string | Exact agent name: `seo-eval`, `hook-eval`, `voice-eval`, `readability-eval` |
| `iteration` | number | Current iteration number, 1-indexed. Iteration 1 = first eval run. On restart, state.json resets `current_iteration` to 0; the next eval writes `iteration: 1`. |
| `timestamp` | string | ISO-8601 UTC |
| `score` | number | Integer 0–100 |
| `feedback` | string | Human-readable summary, 1–3 sentences |
| `sections_affected` | string[] | Section names from wireframe (e.g. `["intro", "meta_description"]`) |
| `suggestion_type` | string | One of: `rewrite`, `restructure`, `enhance`, `keep` |
| `specifics` | object | Dimension-specific detail (see below) |

## suggestion_type values

- `rewrite` — this section needs to be substantially rewritten
- `restructure` — the ideas are right but the structure/order is wrong
- `enhance` — small additions or changes needed (don't fully rewrite)
- `keep` — this section is passing (use when score ≥ 75 for that section)

## specifics object — per dimension

### seo-eval specifics
```json
{
  "keyword_coverage": { "primary": "2.1%", "secondary": "1.2%" },
  "meta_description_length": 95,
  "heading_issues": ["no H2 found after intro"],
  "flesch_score": 62,
  "recommend": "Rewrite meta_description to include primary keyword and value proposition"
}
```

### hook-eval specifics
```json
{
  "first_sentence": "In today's world, AI is changing everything.",
  "hook_issues": ["throat-clearing opening", "no specific claim"],
  "title_score": 45,
  "title_issues": ["no number", "no specific outcome"],
  "recommend": "Rewrite first sentence to open with a specific counterintuitive claim. Rewrite title to include a concrete outcome."
}
```

### voice-eval specifics
```json
{
  "tone_adjectives_found": ["technical"],
  "tone_adjectives_missing": ["direct", "opinionated"],
  "avg_sentence_length": 28,
  "vocabulary_level": "formal",
  "voice_examples_matched": false,
  "recommend": "Shorten sentences in intro and body_para_2. Add an opinionated claim in intro."
}
```

### readability-eval specifics
```json
{
  "avg_paragraph_sentences": 6.2,
  "subheadings_per_300w": 0.5,
  "has_lists": false,
  "avg_sentence_words": 22,
  "offending_sections": ["body_para_1", "body_para_3"],
  "recommend": "Break body_para_1 into two shorter paragraphs. Add a subheading before body_para_3."
}
```

## Atomic write protocol

1. Compute the full JSON output
2. Write to `{slug}/{agent-name}.tmp`
3. Rename `{slug}/{agent-name}.tmp` → `{slug}/{agent-name}.json`

Never write directly to the `.json` file. The orchestrator polls for file presence — a file that exists is a complete file. If rename fails (permissions, disk full), log the error and mark the dimension as "unavailable" — do not leave a stranded `.tmp` file.

## Validation

Before the orchestrator aggregates, it validates each eval JSON against this schema. Required field missing or wrong type → log validation error → report that dimension as "unavailable". Do not crash other dimensions.
