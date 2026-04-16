# Paidagogos — Architecture

## Core design principle

Session state flows through files in `screen_dir/` — never through conversation history. `paidagogos:micro` is the only actor that generates lesson content. The router (`paidagogos`) detects intent and makes routing decisions explicit to the user. The visual server is a separate process that watches `screen_dir/` and serves the newest file — it has no direct connection to Claude.

---

## Skill flow

```
User
 │
 └─ /paidagogos {topic} ──────────────────────────────────────────────────────────
     Reads: PAIDAGOGOS_DEBUG env var, .paidagogos/prefs.json (V2)
     Scope check: topic has > 3 sub-concepts?
         ├── yes  → ask: "Full roadmap or one focused concept?"
         └── no   → route to paidagogos:micro
     Never silently reroutes. Routing decision always surfaced to user.
         │
         └─ paidagogos:micro ──────────────────────────────────────────────────────
             Reads: knowledge/{category}/_index.md (resource lookup)
             Generates: Lesson JSON (one-shot, full schema)
             Writes: screen_dir/lesson-{id}.html
             No agents dispatched. paidagogos:micro is the only actor.
                 │
                 └─ visual server (separate process) ─────────────────────────
                     Watches: screen_dir/ for newest .html file
                     Serves:  http://127.0.0.1:7337/
                     Reads:   state_dir/events (quiz interactions, JSON lines)
                     Auto-exits after 30 minutes of inactivity
                     Started with: paidagogos serve
```

---

## File contract

Every file has a single owner. No two components write to the same file.

| File | Owner | Notes |
|------|-------|-------|
| `screen_dir/lesson-{id}.html` | paidagogos:micro | Written per lesson. Visual server auto-serves newest file. |
| `screen_dir/waiting.html` | paidagogos router | Shown between lessons while a new lesson is being generated. |
| `state_dir/events` | visual server | Quiz interactions written as JSON lines. Append-only. |
| `.paidagogos/prefs.json` | paidagogos router | Expertise level + user preferences. V2 only — not read in V1. |

---

## How the visual server works

The visual server is a file-watcher HTTP server. It is a separate process, started independently with `paidagogos serve`, not managed by any skill.

**Startup:** Binds to `127.0.0.1` only. Default port 7337. If the port is in use, auto-increments to the next free port and logs the actual URL used.

**File watching:** On startup, the server watches `screen_dir/`. When any `.html` file is written (or overwritten), the server immediately serves it at the root path. No reload signal required — the browser is notified via a polling interval or SSE connection.

**Auto-exit:** The server exits automatically after 30 minutes with no lesson file activity. The user can restart it at any time with `paidagogos serve` — the server is stateless and resumes correctly.

**Restart detection:** Skills check whether the server is reachable before writing to `screen_dir/`. If the server is not running, the skill shows an error and does not write partial HTML.

**Privacy:** The visual server binds to `127.0.0.1` only. Lesson pages make no external network requests — all assets are bundled.

---

## Error handling

| Failure | Behaviour |
|---------|-----------|
| Port conflict | Auto-increment to next free port. Log actual URL used: `paidagogos serve: listening on http://127.0.0.1:7338` |
| Server not running when lesson is ready | Skip visual render. Show error: `"Visual server is not running — start it with 'paidagogos serve'"` |
| Lesson generation fails | Show error message. Do not write partial HTML to screen_dir. Nothing is written. |
| Knowledge vault lookup fails | Fall back to LLM-generated resource links. Mark each as `(AI-suggested, verify link)` |
| Browser does not open automatically | Log the URL. Instruct user to open it manually. |

---

## How to add a new skill

Follow the same pattern as draftloom:

1. Create `skills/{name}/SKILL.md` — purpose, invocation, inputs, outputs, constraints
2. Create `skills/{name}/references/` — any reference files the skill reads (schemas, templates)
3. Add the skill to the routing table in `skills/paidagogos/SKILL.md`
4. Add a feature file to `docs/plugins/paidagogos/specs/{name}.feature`
5. Update `docs/plugins/paidagogos/architecture.md` to include the new skill in the flow diagram
6. Update `docs/plugins/paidagogos/_index.md` skill table

Do not add skills that overlap in responsibility. Each skill has one job. The router is the only skill that makes decisions about other skills.

---

## Key rules

- **Never write partial lesson HTML.** If generation fails at any point, nothing is written to `screen_dir/`. A file's presence must mean it is fully valid.
- **Quiz is ON by default.** The user opts out, not in. If the user says "skip the quiz", the lesson is generated without quiz questions. The default is always to include them.
- **Scope classifier always surfaces the routing decision.** The router never silently sends the user to `paidagogos:micro`. If it routes, it says so. If it asks a clarifying question, it waits for the answer.
- **`PAIDAGOGOS_DEBUG=1` enables routing decision log.** When set, the router outputs its full classification reasoning before acting.
- **Lesson JSON is the canonical data shape.** The visual server reads it; the V2 file-based persistence layer will store it; the V3 MCP endpoint will serve it. Do not render HTML without generating valid Lesson JSON first.
- **All AI-generated content carries a caveat.** When Claude synthesises content outside documented sources, the lesson includes: `"This explanation is AI-generated — verify against official documentation."`
