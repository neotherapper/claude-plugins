# Learn — Features

## v1.0 — Ships now

### Routing

- [x] `/learn {topic}` — entry point with intent detection and routing
- [x] Scope classifier: broad topic (>3 sub-concepts) → ask user before routing
- [x] Router surfaces routing decision to user — never silent reroute
- [x] `LEARN_DEBUG=1` routing decision log

### Lesson generation

- [x] `/learn:micro {topic}` — single-concept structured lesson
- [x] One-shot `Lesson` JSON generation with strict typed schema
- [x] Expertise level detection — beginner / intermediate / advanced via first-use prompt
- [x] Expertise level override inline: "teach me X, I'm a beginner"
- [x] Default level: `intermediate` when not set

### Lesson template

- [x] Concept — clear, jargon-minimal explanation (2–3 sentences)
- [x] Why — real-world motivation ("You'll use this when...")
- [x] Example — code or prose with syntax highlighting
- [x] Common mistakes — 2–3 concrete mistakes learners make
- [x] Generate task — production challenge ("Write a flex container that...")
- [x] Quiz — 3 questions, inline, default ON (user opts out)
- [x] "What to explore next" — one suggested follow-on concept at lesson end

### Quiz

- [x] Inline quiz: 3 questions, default ON — user opts out, not in
- [x] Question types: `multiple_choice`, `fill_blank`, `explain`
- [x] Quiz answer evaluation with explanation — not just pass/fail
- [x] Quiz skip with clear error message when visual server is not running

### Visual server

- [x] File-watcher server: `screen_dir` / `state_dir` pattern (same as superpowers visual companion)
- [x] Lesson card renders in browser: concept, why, syntax-highlighted example, common mistakes, generate task, quiz, resource links
- [x] Code block copy button on every code block
- [x] Dark / light mode via OS preference (`prefers-color-scheme`)
- [x] No external CDN calls — all assets bundled in `server/templates/`
- [x] Default port 7337, configurable via `LEARN_PORT` env var
- [x] Port conflict → auto-increment to next free port, log actual URL

### Knowledge vault integration

- [x] Reads `knowledge/{category}/_index.md` for resource links
- [x] `detailed` entries used as curated resources; `stub` entries skipped
- [x] LLM-generated fallback links marked as `(AI-suggested, verify link)`

### Safety & errors

- [x] AI-generated content caveat on all lesson content
- [x] Error state: visual server down → quiz skipped with explicit user-facing message
- [x] Server fail → terminal-rendered lesson with warning
- [x] Browser doesn't open → log URL, instruct user to open manually

---

## v2.0 — Next cycle

### Progress & recall

- [ ] `learn:recall` — resume a previous lesson or pick up where session left off
- [ ] File-based progress store: lesson history, quiz scores, expertise level per topic
- [ ] Single-command data purge (`learn:purge`) for all locally stored data

### Deeper pedagogy

- [ ] `learn:explain` — Feynman technique: user explains concept back, Claude evaluates
- [ ] `learn:quiz` — standalone quiz mode against any previously learned concept
- [ ] Standalone quiz scoring with pass threshold and retry

### Curriculum

- [ ] `learn:path` — multi-concept curriculum with dependency ordering
- [ ] Spaced repetition scheduling for concept review prompts
- [ ] "What to learn next" recommendations based on lesson history

### Infrastructure

- [ ] Expertise level persisted to preferences file (not re-asked each session)
- [ ] Optional MCP memory backend for cross-session analytics (V4)
- [ ] `learn:path` and `learn:recall` registered in plugin manifest

---

## Routing decision table (v1)

| User input | Scope check | Routes to |
|------------|------------|-----------|
| "teach me CSS flexbox" | Single concept | `learn:micro` |
| "teach me CSS" | >3 sub-concepts | Ask: "Full roadmap or one focused concept?" |
| "explain closures in JS" | Single concept | `learn:micro` |
| "how does TCP/IP work" | Single concept | `learn:micro` |
| "teach me machine learning" | >3 sub-concepts | Ask: "Full roadmap or one focused concept?" |
| "I want to learn React" | >3 sub-concepts | Ask: "Full roadmap or one focused concept?" |
| "create a quiz on promises" | Not a lesson intent | Explain V1 scope, suggest "teach me promises" |

---

## Lesson template (teaching flow)

```
1. Concept         — 2–3 sentences, jargon-minimal, no assumed prior knowledge
2. Why             — Real-world motivation. "You'll use this when..."
3. Example         — Code block (syntax highlighted) or prose for non-code concepts
4. Common mistakes — 2–3 concrete errors learners typically make
5. Generate task   — A production prompt the user can act on immediately
6. Quiz            — 3 inline questions; default ON; opt-out only
7. Next            — One suggested follow-on concept
```

Template order is fixed. Skills must not reorder sections or make any section optional except Quiz (user opt-out only).
