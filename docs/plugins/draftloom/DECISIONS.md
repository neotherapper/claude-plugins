# Draftloom — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — aggregate_score = minimum, not average

**Decision:** The final score shown to the user is `min(seo, hook, voice, readability)`, not the mean.

**Why:** An average lets a very high SEO score paper over a failing hook. A post scoring 90/90/90/40 is not a 77.5 post — it is a post with a broken hook that will not get read. The minimum forces every dimension to pass before the post advances.

**Trade-off rejected:** Weighted average with double-weight on hook. Still masks failures. Minimum is harsher but gives the writer an unambiguous signal.

---

## D-02 — File-based workspace, not conversation state

**Decision:** All inter-agent state lives in `posts/{slug}/*.json`, never in conversation history.

**Why:** Claude's context window is finite. A full iterative eval loop passing large JSON blobs between agents through conversation history would exhaust context in 2–3 iterations. File-based state survives context resets, enables session recovery, and lets agents run as independent subagents without shared memory.

**Trade-off rejected:** Passing scores as return values through orchestrator. Works for 1 iteration, breaks under session recovery and subagent dispatch patterns.

---

## D-03 — Atomic eval writes (tmp → rename)

**Decision:** Each eval agent writes to `{name}-eval.tmp` then renames to `{name}-eval.json` on completion. Orchestrator polls for file presence.

**Why:** If an agent crashes mid-write, a partial JSON file would cause the orchestrator to read corrupt data. The rename is atomic on POSIX systems — either the file exists and is complete, or it does not exist yet. File presence = write complete.

**Trade-off rejected:** Lock files or semaphores. More complex, adds failure modes, not necessary given POSIX rename atomicity.

---

## D-04 — Separate eval agent per dimension

**Decision:** seo-eval, hook-eval, voice-eval, readability-eval are separate agent files, run in parallel by the orchestrator.

**Why:** A single eval agent evaluating all 4 dimensions would serialize evaluation, doubling or quadrupling latency. Parallel dispatch means all 4 dimensions score simultaneously. Each agent also develops specialized prompting and rubric knowledge without contaminating the others.

**Trade-off rejected:** One eval agent with 4 tool calls. Removes parallelism. Increases prompt complexity. Harder to extend with a new dimension later.

---

## D-05 — Writer patches only sections_affected, not the full draft

**Decision:** On iteration 2+, the writer reads `sections_affected` arrays from failing eval JSONs and rewrites only those sections.

**Why:** Rewriting a passing section risks regressing its score. If hook passes at 82 but readability fails, regenerating the entire draft could drop the hook to 70. Surgical patching preserves what already works.

**Trade-off rejected:** Full redraft on every iteration. Simple to implement, but introduces score regression churn and wastes tokens.

---

## D-06 — 3 essential setup questions, 6 deferred

**Decision:** `/draftloom:setup` asks only 3 questions on first run. 6 additional profile fields are optional and deferred.

**Why:** A 9-question interview before writing a single word creates drop-off. The 3 essential questions (tone adjectives, style attributes, brand voice example) are the minimum for voice-eval to do meaningful comparison. The other 6 enrich results but are not blocking.

**Trade-off rejected:** Single-question setup (just tone). Too little signal for voice matching. Nine-question setup: too much friction.

---

## D-07 — Turso is optional redundancy, never the primary

**Decision:** All workspace state is always written to the local filesystem first. Turso writes are best-effort; a Turso failure must never halt or retry the eval loop.

**Why:** Turso adds cross-project analytics and persistence, but adding a network dependency to the critical path of a writing loop would make the plugin unusable offline or when the MCP server is unavailable. File-based state is always available.

**Trade-off rejected:** Turso as primary with local file cache. Inverts the reliability story — the durable store should not be the network.

---

## D-08 — SKILL.md capped at 1,500–2,000 words

**Decision:** Each SKILL.md targets 1,500–2,000 words. Detail moves to `references/` loaded on demand.

**Why:** Claude loads SKILL.md into context on every invocation. A 5,000-word skill file consumes context budget that should go to the user's draft. References are loaded only when the relevant step is reached — late-binding reduces constant context cost.

**Trade-off rejected:** Single large SKILL.md with all detail inline. Works for simple skills. At Draftloom's complexity (profile schema, workspace schema, scoring rubric, distribution templates) inline detail would consume 30–40% of context before any writing begins.

---

## D-09 — Readability added as 4th eval dimension

**Decision:** Readability (sentence length, paragraph breaks, subheadings, scanability) is a first-class eval dimension alongside SEO, hook, and voice.

**Why:** A post can have perfect SEO, a great hook, and authentic voice but still fail readers if it is a wall of text. Readability is the structural complement to the semantic dimensions. Posts that fail readability have high bounce rates regardless of other scores.

**Trade-off rejected:** Readability as a sub-score within SEO. SEO and readability have different audiences — SEO serves crawlers, readability serves humans. Conflating them produces rubrics that optimize for neither.
