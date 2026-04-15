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

Use this skill to score any existing Markdown file — not just posts created by Draftloom. It creates a minimal workspace, runs all 4 eval agents (SEO, hook, voice, readability) in parallel via the orchestrator in eval-only mode, and presents a scored report. If any dimension fails, a single patch round is offered.

The 4 eval dimensions and their pass thresholds are defined in `skills/draft/references/scoring-rubric.md`. Voice scoring works with or without a profile — without a profile, it evaluates generic clarity and consistency rather than tone-matching.

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
  "keywords": [],
  "meta_description": null,
  "draft_status": "eval_only",
  "created_at": "{ISO-8601 UTC timestamp}",
  "updated_at": "{ISO-8601 UTC timestamp}"
}
```

## Step 4: Dispatch orchestrator in eval-only mode

Dispatch `agents/orchestrator.md` with:
- Path: `posts/{slug}/`
- Profile JSON path (or null)
- Mode: "eval_only" (skip writer, skip brief, run 4 evals directly)

Load `references/eval-guide.md` for eval-only mode specifics.

## Step 5: Show scored report

When orchestrator signals eval complete, display (✓ = score ≥ 75, ⚠ = score < 75):

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

---

## Reference files

- **`references/eval-guide.md`** — eval-only mode orchestrator behaviour, voice-eval fallback rubric when no profile is selected, patch mode flow with before/after delta display (load at Step 4)
- **`skills/draft/references/scoring-rubric.md`** — pass threshold (≥ 75), per-dimension rubrics (SEO, Hook, Voice, Readability), routing rules (load if surfacing routing decisions to the user)
