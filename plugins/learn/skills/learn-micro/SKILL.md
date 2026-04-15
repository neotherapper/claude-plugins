---
name: learn-micro
description: >
  This skill should be used when the user wants to learn a specific concept,
  asks to be taught something, requests a lesson, or uses trigger phrases such as
  "learn", "teach me", "explain", "learn:micro", "/learn:micro". Use this skill
  whenever the user names a topic and wants structured instruction — even if the
  word "lesson" is not used.
version: "0.1.0"
---

# learn:micro Skill

Orchestrates the full micro-lesson pipeline: pre-flight checks → reference reads → vault lookup → Lesson JSON generation → HTML write → user response.

## Role

`learn:micro` is the lesson generator for the `learn` plugin. Given a topic and an optional expertise level, it produces a single self-contained HTML lesson file served by the visual server. The lesson follows a fixed seven-section structure grounded in learning science and outputs a valid `Lesson` JSON object that the server renders into an interactive page.

This skill never skips the pre-flight checks. It never writes partial HTML. It never presents lesson content as prose in the chat window — all lesson content goes to the HTML file. The chat response is a short confirmation only.

---

## Pre-flight checks

Run both checks before any content generation. Do not proceed past a failing check unless the error handling table below explicitly permits it.

### Check 1: Server running

Read `.learn/server/state/server-info` from the project root.

- If the file does not exist, or the `status` field is not `"running"`, halt immediately. See error handling table: **Server not running**.
- If the file is readable and `status` is `"running"`, extract `screenDir`, `stateDir`, and `port` and carry all three forward.

### Check 2: Expertise level

Determine the lesson level using this detection order:

1. Inline user statement — "teach me X, I'm a beginner" → `beginner`
2. No inline statement → default to `intermediate`

Store the resolved level as `{level}`. The value must be one of `"beginner"`, `"intermediate"`, or `"advanced"`. Any other value is invalid — halt and ask the user to clarify.

---

## Step 1: Read reference files

Before generating any content, read all three reference files in this order:

1. `plugins/learn/skills/learn-micro/references/lesson-schema.md` — the canonical `Lesson` interface, field rules, and a valid example
2. `plugins/learn/skills/learn-micro/references/teaching-guide.md` — content rules for each lesson section, expertise level guidelines, and quiz rules
3. `plugins/learn/skills/learn-micro/references/vault-integration.md` — the vault lookup contract for the `resources[]` array

Hold all three in context for the duration of this skill invocation. Do not rely on memory of these files from prior sessions.

---

## Step 2: Vault lookup

Before generating the Lesson JSON, attempt to source the `resources[]` array from the nikai Knowledge Vault. Follow the lookup contract defined in `skills/learn-micro/references/vault-integration.md` exactly. Do not re-implement the steps here.

If the vault lookup fails for any reason (file not found, read error, vault not in session), continue silently. Do not block lesson generation. See error handling table: **Vault lookup fails**.

---

## Step 3: Generate Lesson JSON

Generate a single JSON object that strictly conforms to the `Lesson` interface defined in `lesson-schema.md`. Apply all content rules from `teaching-guide.md`.

### Required field rules (from lesson-schema.md)

- `topic` — the user-supplied topic string
- `level` — the resolved level from pre-flight Check 2
- `concept` — 2–3 sentences; no jargon for `beginner`; full technical precision for `advanced`
- `why` — one concrete real-world situation; starts with "You'll use this when..."
- `example` — working code (with `language`) for code topics; prose for non-code topics
- `common_mistakes` — exactly 2–3 items; concrete, not generic; framed as "Forgetting that..." not "Always remember to..."
- `generate_task` — starts with an action verb; completable in 5–10 minutes; directly exercises the concept
- `quiz` — exactly 3 questions: one `multiple_choice` (4 options, exactly 1 correct), one `fill_blank`, one `explain`; every `explanation` field states why the answer is correct
- `resources` — at least 1 item with `type: "docs"`; sourced via vault lookup (Step 2)
- `next` — one concept directly related to the topic, one step up in complexity; must be the concept name only (e.g. "CSS Grid") — the Step 5 response template adds the "When you're ready:" prefix
- `estimated_minutes` — realistic read + generate task time; typically 8–15 minutes

### Validation before proceeding

After generating the JSON, validate against all rules in `lesson-schema.md`:

- `common_mistakes` has 2 or 3 items (never 0, never 4+)
- `quiz` has exactly 3 items, one of each required type
- `resources` has at least 1 item with `type: "docs"`
- `estimated_minutes` is a number between 1 and 60

If any validation rule fails, halt. Do not write HTML. See error handling table: **Lesson JSON fails schema validation**.

---

## Step 4: Write HTML

Construct the lesson timestamp: `{timestamp}` = Unix epoch seconds at time of generation (integer).

Determine the output path:

```
{screenDir}/lesson-{timestamp}.html
```

`screenDir` comes from `.learn/server/state/server-info` (read in pre-flight Check 1).

Construct the HTML file with this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{topic} — learn:micro</title>
</head>
<body>
  <script id="lesson-data" type="application/json">
{LESSON_JSON}
  </script>
</body>
</html>
```

`{LESSON_JSON}` is the validated Lesson JSON from Step 3, pretty-printed with 2-space indentation.

The visual server's template (`server/templates/lesson.html`) detects the `#lesson-data` script tag and renders all lesson sections, the quiz, and the footer caveat. Do not add any other HTML content to this file — the server owns the rendering.

Write the file to `{screenDir}/lesson-{timestamp}.html`. If the write fails, see error handling table: **screenDir write fails**.

---

## Step 5: Respond to user

After a successful file write, respond with exactly this format — no additional prose, no lesson content in chat:

```
Lesson ready: {topic} ({level})
→ Open http://localhost:{port} (or it should have updated automatically)

Estimated time: {estimated_minutes} minutes

When you're ready: {next}
```

Substitute:
- `{topic}` — the `topic` field from the Lesson JSON
- `{level}` — the `level` field from the Lesson JSON
- `{port}` — from `.learn/server/state/server-info`
- `{estimated_minutes}` — the `estimated_minutes` field from the Lesson JSON
- `{next}` — the `next` field from the Lesson JSON (without the "When you're ready:" prefix — it is already in the template above)

Do not include quiz answers, lesson content, or resource links in the chat response. All content is in the HTML file.

---

## Error handling

| Error condition | User message | Action |
|---|---|---|
| Server not running (`.learn/server/state/server-info` missing or `status` ≠ `"running"`) | `"The learn server is not running. Start it with /learn serve, then try again."` | Halt immediately. Do not generate content. |
| Lesson JSON fails schema validation (any rule from lesson-schema.md violated) | `"Lesson generation failed. Try a more specific topic."` | Halt. Do NOT write partial HTML. |
| `screenDir` write fails (file write error, permission denied, path not found) | `"Could not write lesson file. Check the server is running."` | Halt. Do not present lesson content in chat. |
| Vault lookup fails (vault not in session, index unreadable, read error) | *(no user message)* | Continue silently. Use ai-suggested resources for `resources[]`. Do not block lesson generation. |

Error messages are shown verbatim as a single line. Do not add apologies, suggestions beyond what is specified, or additional context.
