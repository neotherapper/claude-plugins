---
name: eval
description: >
  This skill should be used when the user asks to score a post, evaluate a
  blog post, check their draft, run draftloom eval, or see how their writing
  scores. Trigger phrases: "draftloom eval", "score my post", "evaluate this
  draft", "check my blog post", "how does my writing score", "run eval on",
  "/draftloom:eval". Use this skill whenever the user wants to score an
  existing markdown file against SEO, hook, voice, and readability rubrics —
  even if they don't use the exact command name.
version: "0.1.0"
---

# Draftloom Eval Skill

Standalone scorer for an existing markdown file. Runs all 4 eval agents and presents a scored report, with an optional patch offer.

## Step 1: Get the file path

Ask: "Path to the markdown file you'd like to score?"

Validate the file exists. If not, ask again.

## Step 2: Select a profile (for voice matching)

If profiles exist in `.draftloom/profiles/`, ask: "Score voice against which profile? (name or 'none' for generic)"

If "none" or no profiles exist: voice-eval uses generic clarity and consistency rubric — does not attempt to load a profile JSON.

## Step 3: Create workspace

Derive slug from the filename (strip extension, normalise to slug format). Check if `posts/{slug}/` already exists. If yes, append `-eval` suffix.

Create `posts/{slug}/`. Copy the provided file to `posts/{slug}/draft.md`.

Write minimal `meta.json`:
```json
{
  "schema_version": "1.0",
  "title": "{filename}",
  "slug": "{slug}",
  "profile_id": "{selected or null}",
  "draft_status": "eval_only"
}
```

## Step 4: Dispatch orchestrator in eval-only mode

Dispatch `agents/orchestrator.md` with:
- Path: `posts/{slug}/`
- Profile JSON path (or null)
- Mode: "eval_only" (skip writer, skip brief, run 4 evals directly)

Load `skills/eval/references/eval-guide.md` for eval-only mode specifics.

## Step 5: Show scored report

When orchestrator signals eval complete, display:

```
Score report: {filename}

SEO          {score}/100  {✓ or ⚠}
Hook         {score}/100  {✓ or ⚠}
Voice        {score}/100  {✓ or ⚠}
Readability  {score}/100  {✓ or ⚠}

Aggregate (minimum): {aggregate}/100

{For each ⚠ dimension:}
  ⚠ {dimension}: {feedback}
     Sections: {sections_affected}
     Suggestion: {recommend}
```

## Step 6: Patch offer

If any dimension scored below 75:
- Ask: "Patch failing dimensions? (y/n)"
- If yes: dispatch writer agent in patch mode, run a second eval pass, show delta

If all dimensions ≥ 75:
- Show: "All dimensions passing." No patch offer.
