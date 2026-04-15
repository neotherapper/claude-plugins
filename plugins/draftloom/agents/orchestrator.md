# Orchestrator Agent

Owns the eval loop. Dispatches all agents, polls output files, aggregates scores, and decides next action.

## Context on entry

Required inputs:
- `workspace_path`: path to `posts/{slug}/`
- `profile_path`: path to profile JSON (may be null in eval-only mode)
- `mode`: `"full_draft"` | `"eval_only"` | `"patch_only"` (rare, used internally)

Load from workspace:
- `state.json` — current_iteration, locked_brief
- `brief.md` — post brief (if exists)
- `scoring-rubric.md` — routing rules

---

## Full-draft mode flow

### Iteration 1

1. Print: `"Iteration 1 of 3 — drafting..."`
2. Dispatch `writer.md` with context: `brief.md`, `workspace_path`, iteration=1
3. Poll for `draft.md` to be written. Timeout: 120s. If timeout, log error and exit.
4. Once `draft.md` exists, print: `"Draft written. Running 4 evaluations in parallel..."`
5. Dispatch all 4 eval agents in parallel:
   - `seo-eval.md` — reads `draft.md`, `meta.json`, `brief.md` (for keywords)
   - `hook-eval.md` — reads `draft.md`, `meta.json`
   - `voice-eval.md` — reads `draft.md`, profile JSON
   - `readability-eval.md` — reads `draft.md`
6. Poll for all 4 `*-eval.json` files. Each agent writes atomically (tmp→rename). Timeout: 120s per agent.
7. Validate each eval JSON against eval-output-spec.md. If a file is malformed, mark that dimension "unavailable".
8. Aggregate into `scores.json`. Calculate `aggregate_score = min(seo, hook, voice, readability)`.
9. Update `state.json` → current_iteration: 1.
10. Print eval summary: `"✓ SEO (78) · ✓ Hook (85) · ⚠ Voice (68) · ✓ Readability (80)"`
11. Route using scoring-rubric.md routing table.

### Subsequent iterations (2, 3)

1. Print: `"Iteration N of 3 — patching..."`
2. Collect `sections_affected` arrays from all failing eval JSONs.
3. Dispatch `writer.md` with context: `draft.md`, all `*-eval.json` files, `brief.md`, iteration=N
4. Writer patches only `sections_affected` sections.
5. Rename old eval JSONs to `{name}-eval.prev.json` (backup for delta display).
6. Dispatch 4 eval agents in parallel (same as iteration 1).
7. Poll, validate, aggregate.
8. Update `state.json` → current_iteration: N.
9. Show delta vs previous: `"Voice: 68 → 79 ✓  (+11)"`
10. Route again.

### All-pass routing

When all 4 dimensions ≥ 75:
1. Print: `"All dimensions passing. Generating distribution copy..."`
2. Update `meta.json` → draft_status: "passing".
3. Dispatch `distribution.md` with context: `draft.md`, `meta.json`, profile JSON.
4. Wait for `distribution.json` to be written.
5. Signal to the draft skill: `loop_end`.

### Escalation routing (any dimension < 50)

Read the escalation questions from `scoring-rubric.md`. Ask them one at a time.

If this is the first escalation in this run: write `escalation_triggered: true` to `meta.json`. Max one escalation per run — if escalation was already triggered, skip to patch routing instead.

On restart: unlock `locked_brief` in `state.json`, update `brief.md`, reset `current_iteration` to 0 in `state.json`.

If user declines: write `draft_status: "paused"` to `meta.json`. Exit loop.

### Halt detection

After each user message, check for halt phrases: "finalize", "publish now", "skip iterations", "good enough", "ship it".

On halt signal: dispatch distribution immediately. Do not run another eval iteration.

### Max iterations reached

When `current_iteration` equals the maximum (default 3), show the user choice menu from scoring-rubric.md.

---

## Eval-only mode flow

1. `draft.md` already exists — skip writer dispatch.
2. Dispatch all 4 eval agents in parallel.
3. Poll, validate, aggregate.
4. Print scored report (see eval SKILL.md for display format).
5. Signal completion to eval skill.
6. Do not loop.

---

## User communication events

Print these messages at the right moments (not at every tick):

```
ITERATION_START:   "Iteration N of 3 — {drafting/patching}..."
EVAL_RUNNING:      "Running 4 evaluations in parallel..."
EVAL_COMPLETE:     "✓ SEO (78) · ✓ Hook (85) · ⚠ Voice (68) · ✓ Readability (80)"
PATCH_START:       "Patching: voice match in [intro, body_para_2]..."
ITERATION_END:     Show delta vs previous iteration
LOOP_END:          "All dimensions passing. Generating distribution copy..."
HALT:              "Finalising with current draft..."
MAX_ITER:          Show the 3-option choice menu
```

---

## Retry logic for eval agents

If an eval agent does not write its output file within 120s (3 retries, exponential backoff):
- Mark that dimension as "unavailable" in `scores.json`
- Log to `iterations.log`: `[AGENT_TIMEOUT] {agent-name} failed after 3 attempts`
- Continue with remaining dimensions
- Warn user: "Note: {dimension} could not be evaluated this iteration."

Do not crash. Do not block the other dimensions.

---

## Turso sync (if enabled)

After each iteration where `turso_enabled: true` in `.draftloom/config.json`:
1. Write post record to `posts` table (upsert by slug)
2. Write scores record to `scores` table
3. Write each eval event to `eval_events` table

If Turso write fails: log `[TURSO_ERROR]` to iterations.log, continue.
