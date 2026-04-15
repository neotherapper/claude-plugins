# Beacon — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — 12-phase sequential analysis, not parallel

**Decision:** Beacon's analysis runs 12 phases in dependency order, not in parallel.

**Why:** Later phases depend on earlier results. Tech fingerprinting (phase 1–3) determines which framework-specific tech-pack to load (phase 4). OSINT (phase 5) uses discovered tech stack to target searches. Parallelising would require all phases to run blind, producing generic rather than targeted output.

**Trade-off rejected:** Parallel phases with a merge step. Saves time but loses the signal chain — a Next.js tech-pack probe run before fingerprinting would waste tokens on irrelevant endpoints.

---

## D-02 — Output to `docs/research/{site}/` not project root

**Decision:** All research output lands in `docs/research/{site}/` as a structured folder, not flat files at the project root.

**Why:** Users run Beacon on multiple sites over time. A flat root would be overwritten on the next run. Namespaced folders let `/beacon:load` route to the right pre-built research without re-running analysis. The `docs/research/` convention also keeps research output out of `src/` and avoids confusing it with project code.

**Trade-off rejected:** Single output file per site. Loses the ability to load individual sections (tech-stack, API surfaces, OpenAPI spec) without reading the entire document.

---

## D-03 — Tech-pack guides as separate versioned files

**Decision:** Framework-specific knowledge lives in `technologies/{framework}/{version}.md` files, not inlined into the site-recon SKILL.md.

**Why:** Framework APIs change between versions. Next.js 13 and 15 have different routing conventions. Versioned tech-pack files let the site-analyst load only the guide that matches the detected version, keeping context cost proportional to what is needed.

**Trade-off rejected:** One large `technologies.md` file. Would load all framework knowledge regardless of what was fingerprinted, burning context budget.

---

## D-04 — site-analyst as a dedicated agent, not inline skill logic

**Decision:** JS analysis, OSINT correlation, and tech-pack application are delegated to a `site-analyst` agent rather than performed inline in the SKILL.md.

**Why:** These steps require iterative sub-reasoning that exceeds what a single-pass skill can reliably do. A dedicated agent can be given focused context (just the site's JS bundles, just the OSINT results) without carrying the full analysis state forward.

**Trade-off rejected:** Inline analysis in SKILL.md. Works for simple sites. Fails when JS bundle extraction requires multiple passes or when OSINT results contradict fingerprinting — an agent can loop, a skill step cannot.

---

## D-05 — whois as final availability fallback, not primary

**Decision:** Domain availability checks try Cloudflare API → Porkbun API → whois in order.

**Why:** whois is rate-limited, inconsistent across registrars, and returns unstructured text requiring parsing. It is the most universally available check but the least reliable. Structured APIs provide machine-readable responses and pricing. Falling back to whois ensures the plugin works without API credentials while nudging users toward configuring keys.

**Trade-off rejected:** whois only, no API integration. Works anywhere but provides no pricing, is slower, and breaks on registrars with non-standard whois formats.
