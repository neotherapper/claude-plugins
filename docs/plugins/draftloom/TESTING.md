# Draftloom — Testing Guide

> How to validate Draftloom behaviour against its acceptance criteria.

Draftloom has no runtime code — it is an AI agent system. "Testing" means running the plugin in Claude Code and verifying observable outputs match the Gherkin scenarios in `docs/plugins/draftloom/specs/`.

---

## Feature files

| File | What it covers |
|------|---------------|
| `specs/setup.feature` | Profile creation, editing, storage, multi-profile listing |
| `specs/draft.feature` | Full draft workflow: brief, wireframe, eval loop, session recovery |
| `specs/eval.feature` | Standalone scoring, patching, agent resilience |

---

## Running a scenario

1. Open a project in Claude Code with Draftloom installed
2. Identify the scenario to test (copy the `Scenario:` title)
3. Set up the `Given` preconditions manually (create files, profiles, etc.)
4. Run the `When` step as a natural language command
5. Verify each `Then` assertion against actual files and Claude output

**Example — "Aggregate score reported as minimum of all dimensions":**

```
Given  scores: seo=82, hook=91, voice=68, readability=78
When   /draftloom:eval completes
Then   posts/my-post/scores.json → aggregate_score: 68
       Claude output shows voice flagged as weakest dimension
```

---

## File-output assertions

Most `Then` clauses map to filesystem checks. After a run, verify:

```
posts/{slug}/
├── draft.md          — non-empty prose
├── brief.md          — locked brief from interview
├── meta.json         — title, slug, profile_id, draft_status, timestamps
├── scores.json       — aggregate_score + 4 dimension objects
├── seo-eval.json     — schema_version, score, feedback, sections_affected
├── hook-eval.json    — same schema
├── voice-eval.json   — same schema
├── readability-eval.json — same schema
├── distribution.json — x_hook, linkedin_opener, email_subject, newsletter_blurb
├── state.json        — current_iteration, locked_brief
├── session.json      — checkpoint for recovery
└── iterations.log    — append-only audit trail
```

Check these files exist and contain the expected fields using `cat` or Read.

---

## Eval agent contract validation

Every `*-eval.json` must pass this schema check:

```json
{
  "schema_version": "1.0",
  "agent": "<name>",
  "iteration": <number>,
  "timestamp": "<ISO-8601>",
  "score": <0-100>,
  "feedback": "<string>",
  "sections_affected": ["<section>"],
  "suggestion_type": "rewrite|restructure|enhance|keep",
  "specifics": { ... }
}
```

Missing any required field = validation failure. See `architecture.md` for the full contract.

---

## Score routing — what to verify

| Condition | Expected behaviour |
|-----------|-------------------|
| aggregate_score < 50 | Claude halts, asks user to revise brief |
| 50 ≤ aggregate_score < 75 | Writer patches sections_affected from failing evals |
| aggregate_score ≥ 75 | Orchestrator finalises and hands off to distribution agent |

Verify `state.json → current_iteration` increments with each patch loop.

---

## Resilience scenarios

These require deliberate fault injection:

**Malformed eval JSON:**
1. Let an eval run start
2. Before it completes, overwrite `hook-eval.json` with `{"score": "bad"}`
3. Verify orchestrator reports hook as "unavailable" without crashing others

**Agent timeout:**
1. Disable one eval agent temporarily (rename its `.md` file)
2. Run `/draftloom:eval`
3. Verify the dimension is marked "unavailable" and the other 3 still score

---

## Session recovery

1. Start `/draftloom:draft` through the wireframe step
2. Kill the session (close terminal)
3. Reopen and run `/draftloom:draft` again
4. Verify Claude detects `session.json` and offers to resume
5. Verify `brief.md` is not re-asked

---

## Regression checklist before any PR

- [ ] `/draftloom:setup` creates a valid profile JSON
- [ ] `/draftloom:draft` completes a full loop and writes `distribution.json`
- [ ] `/draftloom:eval` on a standalone file writes `scores.json`
- [ ] aggregate_score equals the minimum across all 4 dimensions
- [ ] Writer in patch mode only modifies sections listed in `sections_affected`
- [ ] Turso failure does not block the eval loop
- [ ] Session recovery resumes without re-asking the brief
