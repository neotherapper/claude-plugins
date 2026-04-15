# Namesmith — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — Single entry point `/namesmith`, not sub-commands

**Decision:** Namesmith exposes one command that runs the full workflow, rather than separate commands for interview, generation, and availability checking.

**Why:** Naming is a linear workflow — you cannot check availability before you have names, and you should not generate names before you understand the brand. Splitting into sub-commands would require users to remember the sequence and carry state between sessions. One command owns the state machine.

**Trade-off rejected:** `/namesmith:interview`, `/namesmith:generate`, `/namesmith:check`. More granular, but creates accidental entry points that skip the brand context step and produce worse names.

---

## D-02 — 7 archetypes × 10 techniques = explicit generation matrix

**Decision:** The generation phase applies all 10 naming techniques to each of the 7 archetypes explicitly, rather than using free-form AI generation.

**Why:** Free-form generation produces creative but inconsistent coverage. By making the matrix explicit in `generation-archetypes.md`, the skill ensures every wave covers all strategic territory. A user can see exactly what archetype a name comes from, which helps them articulate why they like or dislike it.

**Trade-off rejected:** Pure creative generation with no archetype structure. Faster to prompt, but produces clustering around obvious styles and leaves strategic gaps.

---

## D-03 — Cloudflare API as primary availability check

**Decision:** Domain availability is checked via Cloudflare Registrar API first, with Porkbun and whois as fallbacks.

**Why:** Cloudflare provides real-time availability and pricing in a single authenticated call. It covers the most common TLDs and is the most reliable structured source for users who already have a Cloudflare account (a common profile for technical users running Claude Code).

**Trade-off rejected:** Porkbun first. Porkbun's no-auth pricing endpoint is more accessible but does not provide real-time availability for all TLDs. Cloudflare is the better primary for users who authenticate.

---

## D-04 — Output to `names.md`, not JSON

**Decision:** The shortlist is persisted to `names.md` (Markdown), not `names.json`.

**Why:** `names.md` is human-readable without tooling. Users browse it in their editor or file manager. It also allows prose rationale alongside the shortlist, which JSON cannot express naturally. The brand profile section (reusing interview answers) fits naturally in Markdown.

**Trade-off rejected:** `names.json` for machine-readability. No downstream tooling currently consumes this output programmatically. YAGNI — optimise for the actual consumer (a human reading the file).

---

## D-05 — 6 interview questions, not fewer

**Decision:** The brand interview asks 6 structured questions before generation begins.

**Why:** Each question captures a dimension that materially affects generation quality: (1) brand personality, (2) target audience, (3) domain budget mode, (4) TLD constraints, (5) avoid list (competitor names, trademarked terms), (6) tone. Removing any question degrades one archetype cluster. Empirically, fewer than 6 questions produces names that feel generic.

**Trade-off rejected:** 3-question interview. Reduces time-to-names but generates mismatched results — users spend more time in Wave 2 refinement than they save in the interview.
