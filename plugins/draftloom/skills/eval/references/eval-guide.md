# Eval Guide

Instructions for running eval-only mode via the orchestrator. Load this file in the eval skill.

## Eval-only mode differences

When orchestrator is dispatched with `mode: "eval_only"`:
- Skip Step 1 (writer dispatch — `draft.md` already exists)
- Skip brief validation (no `brief.md` required)
- Proceed directly to: dispatch all 4 eval agents in parallel
- Poll for all 4 eval JSON files
- Aggregate into `scores.json`
- Return eval results to the eval skill

The orchestrator does NOT loop in eval-only mode. It runs exactly one eval pass and returns.

## Voice-eval without a profile

If `profile_id` is null:
- voice-eval scores for generic clarity and consistency
- Does not check tone adjective match
- Does not load brand_voice_examples
- Evaluates: sentence variety, vocabulary range, absence of filler phrases, consistent register throughout

## Patch mode after eval

If the user answers "yes" to the patch offer:
- Dispatch writer with `mode: "patch_only"` — reads all failing eval JSONs, patches sections_affected
- Run a second eval pass (eval-only mode again)
- Show iteration-2 scores alongside iteration-1 scores for comparison:
  ```
  Before → After
  SEO    78 → 84  ✓
  Voice  61 → 79  ✓
  ```
- Do not offer another patch — one patch round is the limit in eval mode
