# Learn — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — Reuse superpowers visual server pattern

**Status:** Accepted

**Context:** The plugin needs a local browser surface to render lesson cards with syntax-highlighted code, interactive quiz, and dark/light mode. Building a new server from scratch adds maintenance surface, setup friction, and implementation time.

**Decision:** Reuse the superpowers visual companion server pattern exactly — file-watcher, `screen_dir` / `state_dir`, HTML fragment writes. `server/start-server.sh` and `server/server.js` follow the same conventions as the superpowers companion.

**Consequences:** Zero reinvention. The server pattern is already proven in production. Contributors familiar with superpowers can modify the learn server without a learning curve. The constraint is that the pattern must not diverge from superpowers — any upgrade to the shared pattern must be applied to both.

---

## D-02 — One-shot Lesson JSON generation

**Status:** Accepted

**Context:** Lesson content could be generated section by section (concept first, then example, then quiz) allowing course-correction between steps. Alternatively, the full `Lesson` JSON can be generated in a single prompt.

**Decision:** One-shot. `learn:micro` generates the complete `Lesson` JSON in a single Claude call against a strict typed schema. No iterative assembly. No inter-step state.

**Consequences:** Fewer failure points — there is no partial-lesson state to recover from. Claude JSON output is reliable with a clearly specified schema. The trade-off is that if one section is poor, the whole lesson regenerates rather than just that section. This is acceptable in V1; section-level regeneration is a V2+ concern.

---

## D-03 — Quiz default ON with opt-out

**Status:** Accepted

**Context:** A quiz could be opt-in (user requests it) or opt-out (always present, user skips). Opt-in is safer — the user is never surprised. Opt-out maximises learning value by default.

**Decision:** Quiz is default ON. Users opt out, not in. The quiz is part of the lesson structure, not an add-on.

**Consequences:** Every lesson delivered through `learn:micro` includes 3 questions unless the user explicitly skips. This aligns with evidence-based pedagogy (retrieval practice improves retention). The trade-off is that users who only want a quick reference explanation must explicitly opt out — accepted, because the target use case is learning, not lookup.

**Trade-off rejected:** Opt-in quiz. Would result in most users never attempting the quiz, undermining the plugin's core value proposition.

---

## D-04 — File-based progress in V2, not V1 (session-only in V1)

**Status:** Accepted

**Context:** Persisting lesson history, quiz scores, and expertise level across sessions would make the plugin significantly more valuable. However, a progress file system adds schema decisions, migration concerns, and purge UX that are out of scope for a V1 demo.

**Decision:** V1 is session-only. No lesson history, no quiz score persistence, no cross-session expertise level memory. Expertise level defaults to `intermediate` on each new session unless the user states it inline. File-based progress (`learn:recall`, expertise persistence) ships in V2.

**Consequences:** V1 is demo-able and publishable without a data layer. Every session starts fresh — no stale state, no migration risk. The trade-off is that users must re-state their expertise level each session, which is a friction point accepted for V1 scope.

---

## D-05 — Lesson template order: Concept → Why → Example → Common mistakes → Generate → Quiz

**Status:** Accepted

**Context:** The teaching flow could be ordered many ways. Starting with examples is common in programming tutorials. Starting with the quiz forces recall before instruction (test-enhanced learning). Starting with the concept is the most conventional ordering.

**Decision:** Fixed template order: Concept → Why → Example → Common mistakes → Generate task → Quiz → Next. This order is mandatory — skills must not reorder or make sections optional (except quiz, which is user-opt-out only).

**Consequences:** The order follows a deliberate progression: understand → motivate → see it → avoid pitfalls → apply it → prove it. Common mistakes before the generate task means the user has been pre-empted on the most likely errors before they attempt the challenge. The fixed order also makes the lesson card layout deterministic, which simplifies the HTML template.

**Trade-off rejected:** Example before Concept. Code-first ordering is appealing for experienced developers but loses beginners who have no mental model to attach the example to.

---

## D-06 — Knowledge vault integration via file-read only in V1

**Status:** Accepted

**Context:** The knowledge vault (`knowledge/`) contains 500+ tool and methodology guides. Integrating them into lessons could mean: (a) prompt-stuffing full entries into context, (b) a runtime vault API, or (c) reading category index files to extract URLs and summaries.

**Decision:** File-read only. `learn:micro` reads `knowledge/{category}/_index.md` to find matching `detailed` entries and uses their URLs and summaries as resource links. `stub` entries are skipped. Full vault entry content is never loaded into lesson context. No runtime API in V1.

**Consequences:** Resource links in lessons are grounded in the knowledge vault without context cost. The constraint is that only `detailed` entries are usable — stubs produce no vault resource and fall back to LLM-generated links (marked `AI-suggested, verify link`). This is the correct trade-off: stubs have insufficient content to be useful, and prompt-stuffing full entries would blow the context budget.

**Trade-off rejected:** Prompt-stuffing full vault entries. For a lesson on a topic covered by a 2,000-word vault entry, this would consume significant context for marginally better resource descriptions.

---

## D-07 — Scope classifier threshold: >3 sub-concepts → ask user before routing

**Status:** Accepted

**Context:** The `/learn` router must decide when a topic is too broad for `learn:micro` and should offer a learning path instead. Any threshold is a heuristic — the question is where to draw it.

**Decision:** If the topic contains more than 3 distinct sub-concepts, the router asks the user: "This is a broad topic. Do you want a full roadmap or one focused concept to start with?" It never silently routes to path (V2+). In V1, the only outcome of "full roadmap" is a clarifying message and a prompt to narrow the topic.

**Consequences:** The threshold of 3 sub-concepts catches broad topics ("teach me machine learning", "teach me React") without catching reasonably scoped ones ("teach me CSS flexbox", "explain closures"). It keeps `learn:micro` as the primary path for the vast majority of plausible inputs. False positives (a topic incorrectly flagged as broad) result in one extra user interaction, not a broken lesson. The trade-off is that the sub-concept count is Claude's judgment call — it is not a deterministic classifier. This is acceptable for V1; a formal scope taxonomy is a V2 consideration.

**Trade-off rejected:** Always route single-word topics to `learn:micro`. Too coarse — "teach me ML" is a single-word topic that would produce a useless lesson if forced into `learn:micro` without scoping.
