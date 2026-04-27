---
name: paidagogos-micro
description: >
  Use when the user wants to learn a specific concept, requests a lesson, or
  wants to explore something interactively or visually. Triggers on: "learn",
  "teach me", "explain", "how does X work", "I don't understand X", "walk me
  through X", "show me X visually", "animate X", "with sliders", "plot X".
  Also triggers when the user names a topic they're confused about even without
  using the word "learn" — e.g. "I keep mixing up SQL joins" or "I want to
  properly understand derivatives". Produces a structured lesson page (standard
  topics) or a live interactive page with sliders and visualisations (math,
  physics, geometry, statistics) — rendered in the browser via visual-kit.
  Invoke this skill for any learning intent, even indirect ones.
---

# paidagogos:micro

Generates a SurfaceSpec JSON file that visual-kit renders in the browser. Two modes: **standard** (structured lesson page) and **interactive** (live HTML with sliders/canvas/SVG). The chat response is always a short URL-only confirmation — no lesson content in chat.

---

## Pre-flight checks

Run all three checks before generating anything. Do not skip.

### Check 1 — Server running

Read `<workspace>/.visual-kit/server/state/server-info`.

- If `status` is `"running"`: extract `port`, carry it forward.
- Otherwise, auto-start — do NOT ask the user:
  1. Run `visual-kit serve --project-dir <workspace>` as a background Bash command (`run_in_background: true`).
  2. Poll the state file every 500 ms for up to 10 s until `status` equals `"running"`.
  3. Extract `port` and continue.
  4. If timeout elapses: halt. See **Error handling → Server failed to auto-start**.

### Check 2 — Expertise level

Detect level in order:
1. Inline statement — "I'm a beginner / advanced" → use it
2. Nothing stated → default to `intermediate`

`{level}` must be `"beginner"`, `"intermediate"`, or `"advanced"`. Anything else: halt and ask.

### Check 3 — Topic classification

Classify before reading any files — it determines the entire pipeline.

**`interactive`** when the topic is:
- A math concept that benefits from visual manipulation: equations, geometry, transformations, functions, calculus (limits, derivatives, integrals), statistics distributions
- A physics or chemistry concept with a parametric relationship (Ohm's law, projectile motion, gas laws)
- Anything the user described as "interactive", "with sliders", "show me visually", "animate", or "plot"

**`standard`** for everything else: programming, languages, history, processes, best practices, tools, frameworks, design patterns.

When uncertain, default to `standard`.

Store as `{mode}`.

---

## Standard pipeline (`{mode}` = `"standard"`)

### S1 — Read reference files

Read all three before generating content. Do not rely on memory from prior sessions.

1. `references/lesson-schema.md` — canonical `Lesson` SurfaceSpec schema, field rules, valid example
2. `references/teaching-guide.md` — content rules per section, level guidelines, quiz rules
3. `references/vault-integration.md` — vault lookup contract for `resources[]`

### S2 — Vault lookup

Attempt to source `resources[]` from the nikai Knowledge Vault following `references/vault-integration.md` exactly. If it fails for any reason, continue silently — see **Error handling → Vault lookup fails**.

### S3 — Generate lesson SurfaceSpec

Generate a JSON object conforming to `vk://schemas/lesson.v1.json` and applying all rules from `references/lesson-schema.md` and `references/teaching-guide.md`. Those files are authoritative — do not improvise field shapes.

Minimum required sections: `concept`, `why`, `code` (or prose equivalent), `mistakes`, `generate`, `quiz`, `resources`, `next`.

### S4 — Validate

Before writing, verify:
- `surface` = `"lesson"`, `version` = `1`
- `mistakes.items` has 2–3 entries
- `quiz.items` has exactly 3 entries, one of each: `multiple_choice`, `fill_blank`, `explain`
- `resources.items` has at least 1 entry with `type: "docs"`
- `estimated_minutes` is between 1 and 60

Any failure: halt, do not write. See **Error handling → Schema validation failed**.

### S5 — Write and respond

Slug: topic → lowercase, hyphens, strip non-alphanumeric. Example: `"CSS Flexbox"` → `css-flexbox`.

Write to `<workspace>/.paidagogos/content/<slug>.json`, pretty-printed, 2-space indent.

Respond with:

```
Lesson ready: {topic} ({level})
→ Open http://localhost:{port}/p/paidagogos/{slug}

Estimated time: {estimated_minutes} minutes

When you're ready: {next}
```

---

## Interactive pipeline (`{mode}` = `"interactive"`)

Skip reference file reads and vault lookup — they do not apply.

### I1 — Generate free-interactive SurfaceSpec

Generate a JSON object conforming to `vk://schemas/free-interactive.v1.json`:

```json
{
  "surface": "free-interactive",
  "version": 1,
  "title": "<topic> — interactive",
  "html": "<full standalone HTML document>"
}
```

The `html` value must be a complete, self-contained HTML document:
- Inline CSS and vanilla JS only — no external CDN dependencies
- Interactive controls (sliders, inputs, buttons) wired to live output (Canvas, SVG, or DOM updates)
- The concept in action — not a static diagram
- Brief explanatory text describing what the controls do
- Clean layout; no chat-style prose

Validate: `surface` = `"free-interactive"`, `version` = `1`, `html` is non-empty.

### I2 — Write and respond

Slug: same rule as standard mode, but append `-interactive`. Example: `"(a+b)²"` → `ab2-interactive`.

Write to `<workspace>/.paidagogos/content/<slug>.json`.

Respond with:

```
Interactive lesson ready: {topic}
→ Open http://localhost:{port}/p/paidagogos/{slug}
```

---

## Notes (both modes)

- If the browser is already open to this URL, it auto-reloads via SSE when the file is overwritten. On a new topic the user must open it manually.
- Never include lesson content, quiz answers, or resource links in the chat response. All content lives in the browser page.

---

## Error handling

| Condition | User message | Action |
|---|---|---|
| Server failed to auto-start | `"Could not start visual-kit automatically. Verify the binary is installed: run \`which visual-kit\`."` | Halt. Re-check PATH and report the actual error from the background process. |
| Schema validation failed | `"Lesson generation failed. Try a more specific topic."` | Halt. Do not write the file. |
| Content write fails | `"Could not write lesson file. Check visual-kit is running."` | Halt. Do not present content in chat. |
| Vault lookup fails | *(no message)* | Continue. Use AI-suggested resources for `resources[]`. |

Show error messages verbatim. No apologies, no extra suggestions.
