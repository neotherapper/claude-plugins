# Workspace Schema

★ This is the source of truth for all files in `posts/{slug}/`. Every agent must read this before writing any file. No agent may create a file not listed here.

## Directory

```
posts/{slug}/
├── draft.md                — prose content of the post
├── brief.md                — locked brief (read-only once loop starts)
├── meta.json               — post metadata
├── scores.json             — aggregated scores per iteration
├── scoring-config.json     — per-workspace score weights (user-editable)
├── state.json              — current iteration and loop status
├── session.json            — checkpoint for session recovery
├── seo-eval.json           — SEO eval agent output (latest iteration)
├── hook-eval.json          — hook eval agent output (latest iteration)
├── voice-eval.json         — voice eval agent output (latest iteration)
├── readability-eval.json   — readability eval agent output (latest iteration)
├── distribution.json       — platform-specific copy
└── iterations.log          — append-only audit trail
```

---

## File contracts

### draft.md
**Owner:** writer agent (writes and patches)
**Readers:** all eval agents, distribution agent, orchestrator (hash check)
**Format:** Markdown prose. No frontmatter. Section headings match wireframe section names.
**Notes:** Writer patches only sections listed in `sections_affected` on iteration 2+. All other content preserved verbatim. `sections_affected` is written by each eval agent to its own eval JSON — see eval-output-spec.md.

---

### brief.md
**Owner:** draft skill (writes once after wireframe approval)
**Readers:** writer agent (reads on every iteration), orchestrator
**Format:** Markdown. See brief-questions.md for the exact structure.
**Notes:** `locked_brief: true` in state.json means this file must not be modified. Writer reads it as context only.

---

### meta.json
**Owner:** draft skill (creates), orchestrator (updates draft_status)
**Readers:** distribution agent, any agent needing post metadata
**Schema:**
```json
{
  "schema_version": "1.0",
  "title": "Why AI Tooling Matters Now",
  "slug": "why-ai-tooling-matters",
  "profile_id": "george-personal",
  "keywords": ["AI tooling", "developer tools"],
  "meta_description": null,
  "draft_status": "drafting",
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:30:00Z"
}
```
`draft_status` values: `drafting` · `iterating` · `passing` · `paused` · `abandoned` · `published` · `eval_only` (eval skill only — skip writer and brief)

---

### scores.json
**Owner:** orchestrator (writes after each iteration)
**Readers:** orchestrator (routing decisions), draft skill (final display)
**Schema:**
```json
{
  "schema_version": "1.0",
  "iteration": 2,
  "timestamp": "2026-04-15T10:45:00Z",
  "aggregate_score": 68,
  "seo": { "score": 78, "status": "pass" },
  "hook": { "score": 85, "status": "pass" },
  "voice": { "score": 68, "status": "fail" },
  "readability": { "score": 80, "status": "pass" }
}
```
`aggregate_score` = `min(seo, hook, voice, readability)`. Never the mean.
`draft_status` transitions to `passing` when all four per-dimension scores are ≥ 75 in the same iteration.

---

### scoring-config.json
**Owner:** draft skill (creates with defaults), user (may edit directly)
**Readers:** orchestrator (display/trend only — not used for pass/fail routing)
**Schema:**
```json
{
  "schema_version": "1.0",
  "weights": { "seo": 0.35, "hook": 0.30, "voice": 0.25, "readability": 0.10 }
}
```
Weights are cosmetic — pass criteria is always per-dimension threshold (75). Changing weights does not change routing.
**Notes:** Agents must not use these weights for routing or pass/fail decisions. Weights are cosmetic display values only. Changing them does not affect whether a draft passes.

---

### state.json
**Owner:** orchestrator (writes after each state change)
**Readers:** all agents (iteration and brief-lock state), draft skill (recovery)
**Schema:**
```json
{
  "current_iteration": 2,
  "locked_brief": true,
  "last_updated": "2026-04-15T10:45:00Z"
}
```
**Notes:** Loop status (`drafting`, `iterating`, `passing`, etc.) lives in `meta.json → draft_status`, not here. `state.json` is for iteration counter and brief-lock only. `locked_brief` is set to `true` by the draft skill immediately after writing `brief.md`, coinciding with the `brief_complete` checkpoint.

---

### session.json
**Owner:** draft skill (creates and updates checkpoints)
**Readers:** draft skill (recovery check on entry)
**Schema:**
```json
{
  "profile_id": "george-personal",
  "slug": "why-ai-tooling-matters",
  "checkpoint": "wireframe_approved",
  "brief_answered": true,
  "wireframe_approved": true,
  "created_at": "2026-04-15T10:00:00Z"
}
```
Checkpoint values in order: `profile_selected` · `brief_complete` · `wireframe_approved` · `eval_loop_start` · `distribution_complete`

---

### seo-eval.json / hook-eval.json / voice-eval.json / readability-eval.json
**Owner:** each respective eval agent (overwrites each iteration)
**Readers:** orchestrator (aggregation, routing), writer (patch context)
**Write protocol:** Write to `{name}-eval.tmp` first, then rename to `{name}-eval.json`. File presence = write complete. Never write directly to the `.json` extension.
**Schema:** See eval-output-spec.md for the full contract.

---

### distribution.json
**Owner:** distribution agent
**Readers:** draft skill (final display)
**Schema:**
```json
{
  "schema_version": "1.0",
  "draft_hash": "sha256:abc123...",
  "x_hook": "...",
  "linkedin_opener": "...",
  "email_subject": "...",
  "newsletter_blurb": "..."
}
```
`draft_hash` is the SHA-256 of `draft.md` at the time distribution ran. If orchestrator detects the hash has changed after distribution ran, it re-runs the distribution agent.

---

### iterations.log
**Owner:** writer (appends on write), orchestrator (appends on score)
**Readers:** writer (context — last 3 entries only), orchestrator (recovery)
**Format:** Append-only plain text. One entry per action:
```
2026-04-15T10:00:00Z  ITERATION_1  writer    draft.md written (823w)
2026-04-15T10:05:00Z  ITERATION_1  seo-eval  score=78 sections_affected=["meta_description"]
2026-04-15T10:05:00Z  ITERATION_1  hook-eval score=85
2026-04-15T10:05:00Z  ITERATION_1  voice-eval score=68 sections_affected=["intro","body_para_2"]
2026-04-15T10:05:00Z  ITERATION_1  readability-eval score=80
2026-04-15T10:05:01Z  ITERATION_1  orchestrator aggregate=68 routing=patch
2026-04-15T10:10:00Z  ITERATION_2  writer    patched intro,body_para_2
```
The orchestrator may compact entries older than 3 full iterations by appending a `SUMMARY:` sentinel line and rewriting the file. This is the only permitted destructive write. Full entries for the last 3 iterations must always be preserved verbatim.
