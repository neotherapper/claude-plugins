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

`paidagogos:micro` is the lesson generator for the `paidagogos` plugin. Given a topic and an optional expertise level, it produces a validated lesson `SurfaceSpec` JSON file that visual-kit picks up, renders into a browser page, and auto-reloads via SSE. The lesson follows a fixed section structure grounded in learning science.

Visual-kit owns all HTML rendering — the skill's only output is a `.json` SurfaceSpec file written to `<workspace>/.paidagogos/content/<slug>.json`. This skill never skips the pre-flight checks. It never writes partial data. It never presents lesson content as prose in the chat window. The chat response is a short confirmation only.

---

## Pre-flight checks

Run both checks before any content generation. Do not proceed past a failing check unless the error handling table below explicitly permits it.

### Check 1: Server running (auto-start if needed)

Read `<workspace>/.visual-kit/server/state/server-info` from the project root.

- If the file exists and `status` is `"running"`, extract `port` and carry it forward.
- Otherwise, auto-start visual-kit — do NOT ask the user to run the command:
  1. Run `visual-kit serve --project-dir <workspace>` as a background shell command (use the Bash tool with `run_in_background: true`).
  2. Poll `<workspace>/.visual-kit/server/state/server-info` every 500 ms for up to 10 seconds, waiting for the file to exist and `status` to equal `"running"`.
  3. When the file reports `"running"`, extract `port` and continue with the lesson flow.
  4. If the timeout elapses, halt. See error handling table: **Server failed to auto-start**.

### Check 2: Expertise level

Determine the lesson level using this detection order:

1. Inline user statement — "teach me X, I'm a beginner" → `beginner`
2. No inline statement → default to `intermediate`

Store the resolved level as `{level}`. The value must be one of `"beginner"`, `"intermediate"`, or `"advanced"`. Any other value is invalid — halt and ask the user to clarify.

---

## Step 1: Read reference files

Before generating any content, read all three reference files in this order:

1. `plugins/paidagogos/skills/paidagogos-micro/references/lesson-schema.md` — the canonical `Lesson` interface, field rules, and a valid example
2. `plugins/paidagogos/skills/paidagogos-micro/references/teaching-guide.md` — content rules for each lesson section, expertise level guidelines, and quiz rules
3. `plugins/paidagogos/skills/paidagogos-micro/references/vault-integration.md` — the vault lookup contract for the `resources[]` array

Hold all three in context for the duration of this skill invocation. Do not rely on memory of these files from prior sessions.

---

## Step 2: Vault lookup

Before generating the Lesson JSON, attempt to source the `resources[]` array from the nikai Knowledge Vault. Follow the lookup contract defined in `skills/paidagogos-micro/references/vault-integration.md` exactly. Do not re-implement the steps here.

If the vault lookup fails for any reason (file not found, read error, vault not in session), continue silently. Do not block lesson generation. See error handling table: **Vault lookup fails**.

---

## Step 3: Generate lesson SurfaceSpec

Generate a single JSON object that strictly conforms to the `lesson` SurfaceSpec v1 defined in `lesson-schema.md` (canonical schema: `vk://schemas/lesson.v1.json`). Apply all content rules from `teaching-guide.md`.

### Required field guidance (from lesson-schema.md)

- `surface` — always `"lesson"`
- `version` — always `1`
- `topic` — the user-supplied topic string
- `level` — the resolved level from pre-flight Check 2
- `estimated_minutes` — realistic read + generate task time; typically 8–15 minutes
- `caveat` — always `"AI-generated — verify against official docs."`
- `sections` — ordered array of typed sections; include at minimum: `concept`, `why`, `code` (or prose equivalent), `mistakes`, `generate`, `resources`, `next`
  - `concept` text: 2–3 sentences; no jargon for `beginner`; full technical precision for `advanced`
  - `why` text: one concrete real-world situation; starts with "You'll use this when..."
  - `code` source: working code (with `language`) for code topics
  - `mistakes` items: exactly 2–3; concrete, not generic; framed as "Forgetting that..."
  - `generate` task: starts with an action verb; completable in 5–10 minutes
  - `quiz` items: exactly 3 questions — one `multiple_choice`, one `fill_blank`, one `explain` (renders as placeholder in core bundle; full interaction in Plan B)
  - `resources` items: at least 1 with `type: "docs"`; sourced via vault lookup (Step 2)
  - `next` concept: one concept one step up in complexity; concept name only (e.g. "CSS Grid")

### Validation before proceeding

After generating the SurfaceSpec, validate:

- `surface` is `"lesson"` and `version` is `1`
- `mistakes` section `items` has 2 or 3 entries (never 0, never 4+)
- `quiz` section `items` has exactly 3 entries, one of each required type
- `resources` section `items` has at least 1 item with `type: "docs"`
- `estimated_minutes` is a number between 1 and 60

If any validation rule fails, halt. Do not write the file. See error handling table: **Lesson SurfaceSpec fails schema validation**.

---

## Step 4: Write lesson SurfaceSpec to content dir

Visual-kit owns all HTML rendering. Your job is to write the SurfaceSpec data file — nothing more.

Construct the lesson slug from the topic: lowercase, spaces replaced by hyphens, non-alphanumeric characters stripped. Example: "CSS Flexbox" → `css-flexbox`.

Determine the output path:

```
<workspace>/.paidagogos/content/<slug>.json
```

Write the file containing the validated lesson SurfaceSpec from Step 3, pretty-printed with 2-space indentation. The file must be valid JSON conforming to `vk://schemas/lesson.v1.json`. No prose, no wrappers, no HTML.

```json
{
  "surface": "lesson",
  "version": 1,
  "topic": "…",
  "level": "…",
  "estimated_minutes": 12,
  "caveat": "AI-generated — verify against official docs.",
  "sections": [ /* typed sections */ ]
}
```

Visual-kit detects the new `.json` file via its file-watcher and the browser auto-reloads via SSE.

If the write fails, see error handling table: **content write fails**.

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
- `{topic}` — the `topic` field from the SurfaceSpec
- `{level}` — the `level` field from the SurfaceSpec
- `{port}` — from `<workspace>/.visual-kit/server/state/server-info`
- `{estimated_minutes}` — the `estimated_minutes` field from the SurfaceSpec
- `{next}` — the `concept` field of the `next` section (without the "When you're ready:" prefix — it is already in the template above)

Do not include quiz answers, lesson content, or resource links in the chat response. All content is in the HTML file.

---

## Error handling

| Error condition | User message | Action |
|---|---|---|
| Server failed to auto-start (auto-start timed out after 10 s, or `visual-kit` binary not found on `PATH`) | `"Could not start visual-kit automatically. Verify the binary is installed: run `which visual-kit`."` | Halt immediately. Do not generate content. Do not ask the user to start it manually — first re-check `PATH` and report the actual error from the background process. |
| Lesson SurfaceSpec fails schema validation (any rule from lesson-schema.md violated) | `"Lesson generation failed. Try a more specific topic."` | Halt. Do NOT write the JSON file. |
| Content write fails (file write error, permission denied, path not found) | `"Could not write lesson file. Check visual-kit is running."` | Halt. Do not present lesson content in chat. |
| Vault lookup fails (vault not in session, index unreadable, read error) | *(no user message)* | Continue silently. Use ai-suggested resources for `resources[]` section. Do not block lesson generation. |

Error messages are shown verbatim as a single line. Do not add apologies, suggestions beyond what is specified, or additional context.
