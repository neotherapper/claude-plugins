---
name: paidagogos-micro
description: >
  This skill should be used when the user wants to learn a specific concept,
  asks to be taught something, requests a lesson, or uses trigger phrases such as
  "learn", "teach me", "explain", "paidagogos:micro", "/paidagogos:micro". Use this skill
  whenever the user names a topic and wants structured instruction — even if the
  word "lesson" is not used.
version: "0.1.0"
---

# paidagogos:micro Skill

Orchestrates the full micro-lesson pipeline: pre-flight checks → reference reads → vault lookup → Lesson JSON generation → JSON write → user response.

## Role

`paidagogos:micro` is the lesson generator for the `paidagogos` plugin. Given a topic and an optional expertise level, it produces a validated `Lesson` JSON file that the visual server injects into its rendering template and serves as an interactive browser page. The lesson follows a fixed seven-section structure grounded in learning science.

The visual server owns all HTML rendering — the skill's only output is a `.json` data file. This skill never skips the pre-flight checks. It never writes partial data. It never presents lesson content as prose in the chat window. The chat response is a short confirmation only.

---

## Pre-flight checks

Run both checks before any content generation. Do not proceed past a failing check unless the error handling table below explicitly permits it.

### Check 1: Server running

Read `.paidagogos/server/state/server-info` from the project root.

- If the file does not exist, or the `status` field is not `"running"`, halt immediately. See error handling table: **Server not running**.
- If the file is readable and `status` is `"running"`, extract `screenDir`, `stateDir`, and `port` and carry all three forward.

### Check 2: Expertise level

Determine the lesson level using this detection order:

1. Inline user statement — "teach me X, I'm a beginner" → `beginner`
2. No inline statement → default to `intermediate`

Store the resolved level as `{level}`. The value must be one of `"beginner"`, `"intermediate"`, or `"advanced"`. Any other value is invalid — halt and ask the user to clarify.

---

## Step 1: Read reference files

Before generating any content, read all four reference files in this order:

1. `plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md` — the canonical `Lesson` interface, field rules, and a valid example
2. `plugins/paidagogos/skills/paidagogos-micro/references/teaching-guide.md` — content rules for each lesson section, expertise level guidelines, and quiz rules
3. `plugins/paidagogos/skills/paidagogos-micro/references/vault-integration.md` — the vault lookup contract for the `resources[]` array
4. `plugins/paidagogos/skills/paidagogos-micro/references/renderer-map.md` — the keyword → renderer classification table for `renderers[]`

Hold all four in context for the duration of this skill invocation. Do not rely on memory of these files from prior sessions.

---

## Step 2: Vault lookup

Before generating the Lesson JSON, attempt to source the `resources[]` array from the nikai Knowledge Vault. Follow the lookup contract defined in `skills/paidagogos-micro/references/vault-integration.md` exactly. Do not re-implement the steps here.

If the vault lookup fails for any reason (file not found, read error, vault not in session), continue silently. Do not block lesson generation. See error handling table: **Vault lookup fails**.

---

## Step 3: Classify renderers

1. Read `references/renderer-map.md`.
2. Apply the keyword → renderer table to the topic.
3. Collect all matching renderer keys into `renderers[]`.
4. If the lesson has a visual example, pick the single most appropriate renderer from `renderers[]` and set `example.renderer`. Also populate `example.config` with the renderer-specific structure (see component documentation for each renderer).
5. If no keywords match and the topic is not a programming language, set `renderers: []` and omit `example.renderer`.
6. Do NOT invent renderer keys. Only the V2 set is available: `math`, `code`, `chart`, `geometry`, `sim-2d`. If the topic would benefit from a renderer not in this set, check `renderer-map.md` "Out of scope for V2" and fall back to `renderers: []` or `["code"]` as appropriate.

---

## Step 4: Generate Lesson JSON

Generate a single JSON object that strictly conforms to the `Lesson` interface defined in `lesson-schema.md`. Apply all content rules from `teaching-guide.md`.

### Required field rules (from lesson-schema.md)

- `topic` — the user-supplied topic string
- `level` — the resolved level from pre-flight Check 2
- `concept` — 2–3 sentences; no jargon for `beginner`; full technical precision for `advanced`
- `why` — one concrete real-world situation; starts with "You'll use this when..."
- `example` — working code (with `language`) for code topics; prose for non-code topics; if a renderer was selected in Step 3, also set `example.renderer` (the chosen renderer key) and `example.config` (renderer-specific configuration object)
- `renderers` — array of renderer keys classified in Step 3 (e.g. `["code"]`, `["math", "code"]`, or `[]`); always present, never omitted
- `common_mistakes` — exactly 2–3 items; concrete, not generic; framed as "Forgetting that..." not "Always remember to..."
- `generate_task` — starts with an action verb; completable in 5–10 minutes; directly exercises the concept
- `quiz` — exactly 3 questions: one `multiple_choice` (4 options, exactly 1 correct), one `fill_blank`, one `explain`; every `explanation` field states why the answer is correct
- `resources` — at least 1 item with `type: "docs"`; sourced via vault lookup (Step 2)
- `next` — one concept directly related to the topic, one step up in complexity; must be the concept name only (e.g. "CSS Grid") — the Step 6 response template adds the "When you're ready:" prefix
- `estimated_minutes` — realistic read + generate task time; typically 8–15 minutes

### Validation before proceeding

After generating the JSON, validate against all rules in `lesson-schema.md`:

- `common_mistakes` has 2 or 3 items (never 0, never 4+)
- `quiz` has exactly 3 items, one of each required type
- `resources` has at least 1 item with `type: "docs"`
- `estimated_minutes` is a number between 1 and 60

If any validation rule fails, halt. Do not write HTML. See error handling table: **Lesson JSON fails schema validation**.

---

## Step 5: Write lesson JSON to screen_dir

The visual server owns all HTML rendering. It reads `server/templates/lesson.html` and injects the lesson data into the `#lesson-data` script tag automatically. Your job is to write the data file — nothing more.

Construct the lesson timestamp: `{timestamp}` = Unix epoch seconds at time of generation (integer).

Determine the output path:

```
{screenDir}/lesson-{timestamp}.json
```

`screenDir` comes from `.paidagogos/server/state/server-info` (read in pre-flight Check 1).

Write the file containing the validated Lesson JSON from Step 4, pretty-printed with 2-space indentation. The file must be valid JSON — no prose, no wrappers, no HTML.

```json
{
  "topic": "…",
  "level": "…",
  … (full Lesson JSON)
}
```

The visual server detects the new `.json` file via its file-watcher, injects it into `lesson.html`, and the browser auto-reloads via SSE.

If the write fails, see error handling table: **screenDir write fails**.

---

## Step 6: Respond to user

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
- `{port}` — from `.paidagogos/server/state/server-info`
- `{estimated_minutes}` — the `estimated_minutes` field from the Lesson JSON
- `{next}` — the `next` field from the Lesson JSON (without the "When you're ready:" prefix — it is already in the template above)

Do not include quiz answers, lesson content, or resource links in the chat response. All content is in the HTML file.

---

## Error handling

| Error condition | User message | Action |
|---|---|---|
| Server not running (`.paidagogos/server/state/server-info` missing or `status` ≠ `"running"`) | `"The paidagogos server is not running. Start it with /paidagogos serve, then try again."` | Halt immediately. Do not generate content. |
| Lesson JSON fails schema validation (any rule from lesson-schema.md violated) | `"Lesson generation failed. Try a more specific topic."` | Halt. Do NOT write the JSON file. |
| `screenDir` write fails (file write error, permission denied, path not found) | `"Could not write lesson file. Check the server is running."` | Halt. Do not present lesson content in chat. |
| Vault lookup fails (vault not in session, index unreadable, read error) | *(no user message)* | Continue silently. Use ai-suggested resources for `resources[]`. Do not block lesson generation. |

Error messages are shown verbatim as a single line. Do not add apologies, suggestions beyond what is specified, or additional context.
