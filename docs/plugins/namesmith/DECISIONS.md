# Namesmith — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — Skill, not a command

**Decision:** Namesmith is implemented as a skill (`site-naming`), not a slash command. It is triggered by natural language descriptions of the naming problem, not by typing `/namesmith`.

**Why:** Domain naming starts with a conversation, not a command invocation. The user describes what they are building; the skill detects context (project files, personal brand signals) before the interview even starts. A command trigger would force the user to already know they need the tool, missing the ambient detection cases.

**Trade-off rejected:** `/namesmith:start` slash command. More explicit, but loses the conversational entry point and requires separate personal brand and project-file detection logic outside the skill.

---

## D-02 — Brand interview before generation (not concurrent)

**Decision:** All 6 interview questions are answered before any name generation begins.

**Why:** Each answer materially changes the generation weights. Q2 (tone) and Q3 (direction) together determine which archetypes to emphasise; Q4 (budget mode) biases the TLD set; Q5 (length) caps name character counts. Running generation before the full profile is locked produces names that must be discarded — a worse user experience than a 2-minute interview.

**Trade-off rejected:** Generate a quick first batch after Q1, refine on Q2–Q6. Feels faster, but the first batch is almost always thrown away, increasing total session length.

---

## D-03 — 6 interview questions, exactly

**Decision:** The brand interview asks exactly 6 questions:
1. **Q1 — What are you building?** (open-ended, extracts domain + audience)
2. **Q2 — Personality/Tone** (A: cool/media-brand, B: authoritative, C: playful/community)
3. **Q3 — Direction** (A: functional, B: abstract/invented)
4. **Q4 — Budget mode** (A: budget TLDs, B: balanced, C: premium .com)
5. **Q5 — Name length** (A: ≤6 chars, B: expressive 7+)
6. **Q6 — Hard constraints** (no hyphens, specific TLD required, avoid list, etc.)

**Why:** Each question captures one independent dimension. Removing any question collapses one axis of the generation matrix — Q5 removal causes short and long names to be mixed with no way to filter; Q6 removal produces suggestions the user immediately rejects due to undiscovered constraints. Empirically, fewer than 6 questions leads to more Wave 2 iterations, not fewer.

**Trade-off rejected:** 3-question interview. Faster to reach Wave 1, but users spend more time in refinement loops than they save.

---

## D-04 — 7 archetypes × 10 techniques = explicit generation matrix

**Decision:** Generation applies all 10 naming techniques across 7 named archetypes (Short & Punchy, Descriptive, Abstract/Brandable, Playful/Clever, Domain Hacks, Compound/Mashup, Thematic TLD Play), weighted by brand interview answers.

**Why:** Free-form AI generation clusters around the obvious. The explicit matrix ensures every strategic territory is covered in every wave — a user who picks Q2=Playful still gets a handful of Abstract candidates for comparison, which often surfaces the best name. Named archetypes also give users vocabulary to articulate feedback ("more like the abstract ones, fewer compound").

**Trade-off rejected:** Pure creative generation with no archetype structure. Produces creative output but inconsistent coverage. Users cannot point to what they want more or less of.

---

## D-05 — Three-wave system with Track B fallback

**Decision:** Name generation runs in waves (Wave 1: 25–35, Wave 2: 20+ refined, Wave 3: deep TLD scan across 1,441+ IANA TLDs) rather than producing all candidates upfront. Track B activates when all top picks are taken.

**Why:** Availability check is the bottleneck — running it on 100+ names in one batch is slow and most results are immediately discarded. Waves allow the user to express preference after seeing 25 names, so Wave 2 is targeted rather than exhaustive. Wave 3 (deep TLD scan) is expensive and only needed in hard cases.

**Track B** runs 4 strategies in order when all Wave N picks are taken: (1) close variations with get-/try-/-hq suffixes, (2) synonym exploration, (3) creative reconstruction from scratch, (4) domain hacks from tld-catalog.

**Trade-off rejected:** Generate 100 names then check all at once. Higher upfront latency, produces more noise, and cannot incorporate user feedback mid-session.

---

## D-06 — Personal brand detection as a pre-interview branch

**Decision:** Before running the standard 6-question interview, the skill scans the user's description for personal brand signals (keywords: "portfolio", "freelance", "my name", "personal site"; patterns: human first/last name as subject). If detected, it runs a specialised name pattern set and offers to continue to the standard interview.

**Why:** Personal branding has a completely different naming strategy — `firstname.dev`, `firstnamelastname.com`, `f+lastname.io` — that does not benefit from the archetype matrix. Routing to the standard interview first wastes time; the best names are often the simplest pattern checks.

**Trade-off rejected:** Always run the full interview first. Works, but produces archetype-based suggestions for a use case that is better served by structured name patterns.

---

## D-07 — Progressive disclosure: lean SKILL.md + 6 reference files

**Decision:** SKILL.md is capped at 2,000 words and contains only orchestration logic. All reference content (interview questions, archetype descriptions, TLD catalog, registrar URLs, API setup, post-shortlist checklist) lives in separate files loaded on demand via `$CLAUDE_PLUGIN_ROOT`.

**Why:** A skill that loads fully into context at every trigger is wasteful — post-shortlist content is only needed at the end of a session, TLD catalog only when generating Domain Hacks or budget mode. Progressive disclosure keeps the base context cost low and loads expensive references only when they are needed.

**Load gates (when each file loads):**
- `brand-interview.md` — Step 2 (personal brand) or Step 3 (interview)
- `generation-archetypes.md` — Step 4 (Wave 1), Step 8 (Wave 2/3/Track B)
- `tld-catalog.md` — Step 4, when Mode=A or Domain Hacks/Thematic TLD Play archetypes
- `registrar-routing.md` — Step 6 (format output)
- `api-setup.md` — Step 5, only when no API env vars detected
- `post-shortlist.md` — Step 9, only after user confirms final shortlist

**Trade-off rejected:** Single SKILL.md with all content inline. Simpler to maintain, but exceeds 5,000 words, loading unnecessary context on every trigger.

---

## D-08 — Cloudflare Registrar API as primary availability check

**Decision:** Domain availability is checked via Cloudflare Registrar API first (`POST /accounts/{id}/registrar/domain-check`, up to 20 per batch call), with Porkbun API second and whois/DNS as the final fallback.

**Why:** Cloudflare provides real-time availability and at-cost pricing in a single batch call. Users who run Claude Code for development work typically already have a Cloudflare account. The API is well-documented and the at-cost pricing is the most accurate pricing available.

**Porkbun pricing endpoint** (`/pricing/get`) requires no authentication and is always called for TLD price data — it operates independently of the availability check tier.

**Trade-off rejected:** Porkbun as primary. Porkbun's availability check requires a free API key and is per-domain (no batching). The no-auth pricing endpoint is a better fit for Porkbun's role.

---

## D-09 — Output to `names.md` (Markdown), not JSON

**Decision:** The shortlist persists to `names.md` with three sections: Shortlisted table (name, price, status, rationale), Considered/Taken table (name, status, alternative), and Brand Interview recap.

**Why:** `names.md` is human-readable without tooling. The rationale column captures the "why" from the conversation verbatim, which JSON cannot express naturally. The brand interview recap makes the file self-contained — opening it weeks later tells you the full context without re-reading the session.

**Trade-off rejected:** `names.json` for machine-readability. No downstream tooling currently consumes this output programmatically. YAGNI.

---

## D-10 — Post-shortlist checklist as a separate reference file

**Decision:** Pronunciation test, social handle availability, trademark search, and registration strategy are in `references/post-shortlist.md`, loaded only when the user confirms their final shortlist.

**Why:** Post-shortlist steps are irrelevant before a shortlist exists. Loading them early wastes context. The checklist is also long enough (5 sections, real trademark search URLs, social platform list) that keeping it inline in SKILL.md would blow the word budget.

**Trade-off rejected:** Inline post-shortlist steps in SKILL.md. Simpler loading, but adds ~400 words to every skill invocation even when the user only wants to browse name suggestions.
