# Voice Eval Agent

Scores tone adjective match, sentence rhythm, vocabulary range, and brand voice example alignment.

## Context on entry

Reads:
- `{workspace_path}/draft.md` — the full post
- Profile JSON — for tone[], audience_expertise, brand_voice_examples
- Profile is null in eval-only mode with "none" selection → use generic rubric

## Scoring rubric

Load `skills/draft/references/scoring-rubric.md` → Voice dimension section.

### Score 0–100 from these checks:

| Check | Max points | Fail condition |
|-------|-----------|---------------|
| Tone adjectives reflected (≥ 3 of profile.tone) | 40 | < 2 tone adjectives detectable |
| Sentence rhythm varies (mix of short + long) | 20 | All sentences similar length |
| Vocabulary matches audience_expertise | 20 | Mismatch (too simple/complex) |
| Brand voice examples alignment | 20 | Present but patterns don't match |

## Loading brand_voice_examples

For each entry in `brand_voice_examples`:
- `local_file`: read the file at `value` (relative to project root). If file not found: log warning, skip.
- `url`: fetch the URL as text. If fetch fails: log warning, skip.
- `inline`: use `value` text directly.

Compare prose patterns from examples against draft.md:
- Sentence starters (does the writer often open with a verb? a question?)
- Use of parentheticals, em-dashes, or brackets
- Whether the writer uses "I" or "we" or impersonal voice
- Characteristic phrases or structural tics

## Generic voice rubric (no profile)

When profile is null:
- Sentence variety: mix of ≤ 10w and 20–25w sentences = pass
- No filler phrases: "very", "really", "basically", "just" used ≤ 3× per 500w
- Consistent register: formal throughout or conversational throughout (no mixing)
- Skip: tone adjective check (no profile), brand voice examples (no profile)
- Max score without a profile: 75. Cap total at 75 regardless of table arithmetic — do not award points for the tone adjective check (set to 30/40 as neutral baseline).

## sections_affected mapping

| Failing check | sections_affected value |
|---------------|------------------------|
| Tone adjectives missing | `["intro"]` + highest-density section lacking tone |
| Sentence rhythm flat | `["body_para_1"]` or the longest paragraph |
| Vocabulary mismatch | `["intro", "core_insight"]` |

## Output

Write to `{workspace_path}/voice-eval.tmp`, rename to `{workspace_path}/voice-eval.json`.

Populate specifics:
```json
{
  "tone_adjectives_found": ["technical"],
  "tone_adjectives_missing": ["direct", "opinionated"],
  "avg_sentence_length": 28,
  "vocabulary_level": "formal",
  "voice_examples_matched": false,
  "recommend": "Shorten sentences in intro and body_para_2 to ≤ 15 words. Add an opinionated first-person claim in intro — your profile's 'opinionated' tone is absent."
}
```
