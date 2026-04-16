# Teaching Guide

Rules `learn:micro` MUST follow when generating lesson content.

## Lesson template (fixed order)

```
1. Concept       — 2–3 sentences. No jargon for beginner; technical precision for advanced.
2. Why           — One concrete real-world situation where this applies.
3. Example       — Working code or clear prose. For code: use the simplest case that illustrates the concept.
4. Common mistakes — 2–3 mistakes. These pre-empt wrong mental models formed from the example.
5. Generate task — A production task the user can attempt right now. Starts with a verb ("Write", "Build", "Implement", "Explain", "Refactor").
6. Quiz          — 3 questions, default ON. Types: one multiple_choice + one fill_blank + one explain.
7. Next          — One follow-on concept. Directly related, one step up in complexity. Phrase as: "When you're ready: [concept]"
```

Never reorder these sections. The sequence is grounded in learning science: encoding (1–3) → misconception correction (4) → production (5) → retrieval (6) → forward momentum (7).

## Expertise level rules

| Level | Concept | Example | Quiz |
|-------|---------|---------|------|
| `beginner` | Plain language, analogies, no assumed knowledge | Minimal working snippet, heavily commented | Questions test recall and basic application |
| `intermediate` | Technical terms used correctly, brief definitions if uncommon | Realistic use case, some nuance | Questions test application and edge cases |
| `advanced` | Full technical precision, no hand-holding | Non-trivial example with trade-offs visible | Questions test evaluation and synthesis |

**Detection order:**
1. Inline user statement: "teach me X, I'm a beginner" → use `beginner`
2. Stored preference in `.learn/prefs.json` (V2 only — not available in V1)
3. Default: `intermediate`

## Quiz rules

- Always generate exactly 3 questions: one per type (`multiple_choice`, `fill_blank`, `explain`)
- Quiz is ON by default. Only skip if user explicitly says "skip quiz" or "no quiz"
- Every `explanation` field must say why the answer is correct, not just restate it
- `multiple_choice` must have exactly 4 options; exactly 1 is correct
- `explain` questions should ask the user to produce an explanation, not recall a fact

## Common mistakes rules

- 2–3 items, never fewer, never more
- Each must be a mistake a real learner makes with this specific concept
- Frame as what goes wrong, not as a rule to follow: "Forgetting that..." not "Always remember to..."

## Generate task rules

- Must be something the user can do right now, in a text editor or REPL
- Must directly exercise the concept just taught
- Must be completable in 5–10 minutes
- Starts with an action verb: "Write", "Build", "Implement", "Explain", "Refactor"

## Content accuracy caveat (REQUIRED)

Every lesson HTML MUST include this caveat in the footer:

> ⚠️ This explanation is AI-generated. Verify against official documentation before using in production.

Never omit this. Never modify the wording.

## "What to explore next"

After the quiz, suggest exactly one follow-on concept. It must be:
- Directly related to the lesson topic
- One step up in complexity (not a tangent)
- Phrased as: "When you're ready: [concept]"
