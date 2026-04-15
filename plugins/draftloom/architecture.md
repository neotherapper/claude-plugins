# Draftloom — Architecture

## Core design principle

All state flows through files in `posts/{slug}/` — never through conversation history. Agents are specialists that read specific files, write specific files, and signal completion atomically. The orchestrator is the only agent that reads multiple files and makes decisions.

---

## Agent roles and boundaries

```
User
 │
 ├─ /draftloom:setup ──────────────────────────────────────────────────────
 │   Reads: .draftloom/profiles/ (existing), .draftloom/config.json
 │   Writes: .draftloom/profiles/{name}.json, .draftloom/config.json
 │   No agents dispatched.
 │
 └─ /draftloom:draft ──────────────────────────────────────────────────────
     Reads: .draftloom/profiles/, posts/{slug}/session.json (if resuming)
     Writes: posts/{slug}/brief.md, meta.json, session.json
     Delegates to: orchestrator.md after wireframe approval
         │
         └─ orchestrator.md ──────────────────────────────────────────────
             Owns: eval loop, iteration counter, routing decisions
             Reads: all workspace files
             Writes: scores.json, state.json
             Dispatches (iteration 1):
                 └─ writer.md
                     Reads: brief.md only
                     Writes: draft.md, iterations.log
             Dispatches (iteration 2+):
                 └─ writer.md
                     Reads: brief.md + scores.json + draft.md + *-eval.json
                     Patches: sections_affected only
             Dispatches (in parallel, each iteration):
                 ├─ seo-eval.md → seo-eval.json
                 ├─ hook-eval.md → hook-eval.json
                 ├─ voice-eval.md → voice-eval.json
                 └─ readability-eval.md → readability-eval.json
             Dispatches (on all-pass or halt):
                 └─ distribution.md
                     Reads: draft.md, meta.json, profile JSON
                     Writes: distribution.json
```

---

## Workspace file contract

Defined in `skills/draft/references/workspace-schema.md`. Every file has a single owner and a defined schema version.

| File | Owner | Schema | Notes |
|------|-------|--------|-------|
| `draft.md` | writer | — | Prose only, no frontmatter |
| `brief.md` | draft skill | 9 sections | Locked (read-only) during iteration |
| `meta.json` | draft skill | v1.0 | draft_status: draft/review/published/paused/abandoned |
| `scores.json` | orchestrator | v1.0 | Aggregated from all eval JSONs |
| `scoring-config.json` | user | v1.0 | Per-workspace weights, copied from defaults on creation |
| `state.json` | orchestrator | v1.0 | current_iteration, locked_brief |
| `session.json` | draft skill | v1.0 | Checkpoint for recovery |
| `seo-eval.json` | seo-eval | v1.0 | Overwrite each iteration |
| `hook-eval.json` | hook-eval | v1.0 | Overwrite each iteration |
| `voice-eval.json` | voice-eval | v1.0 | Overwrite each iteration |
| `readability-eval.json` | readability-eval | v1.0 | Overwrite each iteration |
| `distribution.json` | distribution | v1.0 | draft_hash for staleness check |
| `iterations.log` | writer + orchestrator | text | Append-only, last 3 full + older summarised |

---

## Eval loop state machine

```
START
  │
  ▼
[iter=1] dispatch writer (brief only, no eval context)
  │
  ▼
dispatch 4 eval agents in parallel
  │
  ▼
poll until all 4 *-eval.json exist (atomic write = complete)
  │
  ▼
validate each JSON against eval-output-spec.md
  │ (skip dimension if malformed, log warning)
  ▼
aggregate → scores.json
  │
  ├── any dimension < 50 ──────► ESCALATE
  │                               │ ask user 4 structured questions
  │                               │ if declined → draft_status: "paused" → EXIT
  │                               │ if answered → feed to writer → continue
  │
  ├── any dimension 50–74 ──────► PATCH
  │                               │ dispatch writer with sections_affected
  │                               │ iter++ → back to eval dispatch
  │                               │ (max 3 iterations total)
  │
  ├── all dimensions ≥ 75 ──────► PASS → dispatch distribution → EXIT
  │
  └── iter=3 and failing ───────► LIMIT REACHED
                                  │ offer: publish anyway / extend / discard
                                  └── on publish → distribution → EXIT
```

---

## Eval agent output contract

Defined in `skills/draft/references/eval-output-spec.md`. All eval agents share this schema:

```json
{
  "schema_version": "1.0",
  "agent": "seo-eval",
  "iteration": 2,
  "timestamp": "ISO8601",
  "score": 78,
  "feedback": "Short human-readable description of the issue",
  "sections_affected": ["headline", "intro"],
  "suggestion_type": "rewrite | enhance | condense",
  "specifics": {
    "key": "dimension-specific structured data",
    "recommend": "Concrete rewrite instruction for the writer"
  }
}
```

`sections_affected` is the handoff to writer.md. It must name sections precisely (matching the wireframe labels) so the writer knows exactly where to edit.

---

## Backend strategy

```
PRIMARY: File system (posts/{slug}/*.json)
  - Always used
  - Git-trackable
  - Zero dependencies

SECONDARY: Turso MCP (optional)
  - Enabled via .draftloom/config.json turso_enabled: true
  - Agents write to files first, then sync to Turso
  - Turso failure logged but never blocks iteration
  - Useful for: cross-project analytics, team shared state

Turso tables:
  posts(id, slug, profile_id, title, draft_status, latest_aggregate_score, timestamps)
  scores(post_id, iteration, aggregate, seo, hook, voice, readability, timestamp)
  eval_events(post_id, iteration, agent, score, feedback, sections_affected)
```

---

## Key design decisions

**Why minimum not average for aggregate_score?**
A post with SEO=95 and voice=45 is not a good post. A weak dimension can't be papered over. Minimum enforces that every dimension must genuinely pass.

**Why separate *-eval.json files instead of one shared scores.json?**
Three eval agents writing to one file simultaneously causes race conditions and last-write-wins clobber. Separate files + orchestrator aggregation eliminates this entirely without any locking.

**Why atomic writes (tmp → rename)?**
File presence must mean "fully written and valid". Without atomic writes, the orchestrator might poll and read a partial file mid-write. Tmp-then-rename is atomic on all Unix filesystems.

**Why file-based over database-first?**
Public plugin — users have no external services configured by default. File system works everywhere, is Git-trackable, and is inspectable by the user. Turso upgrades this for power users without breaking the baseline.

**Why lock brief.md during iteration?**
If the user edits the brief mid-iteration, the writer and eval agents would be working against inconsistent requirements. Locking prevents silent context drift. If the user wants to change direction, they must halt and restart.
