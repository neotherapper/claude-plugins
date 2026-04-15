# Namesmith — Testing Guide

> How to validate Namesmith behaviour against its acceptance criteria.

Namesmith has no runtime application code — it is an AI agent system. "Testing" means running the plugin in Claude Code and verifying observable outputs match the Gherkin scenarios in `docs/plugins/namesmith/specs/`.

---

## Feature files

| File | What it covers |
|------|---------------|
| `specs/namesmith.feature` | Full workflow: interview → generation → availability → names.md |

---

## Running a scenario

1. Open a project in Claude Code with Namesmith installed
2. Identify the scenario to test (copy the `Scenario:` title)
3. Provide the `Given` preconditions (API credentials, brand context)
4. Run `/namesmith` and answer the 6 interview questions with the scenario's inputs
5. Verify each `Then` assertion against actual files and Claude output

---

## Output assertions

After a complete `/namesmith` run, verify `names.md` exists at the project root and contains:

```
# Names — {brand}

## Brand profile
- Personality: ...
- Audience: ...
- TLD constraints: ...

## Shortlist
| Name | TLD | Available | Price | Archetype | Rationale |
|------|-----|-----------|-------|-----------|-----------|
| ... | ... | ✓/✗ | $X.xx | Short & Punchy | ... |

## Full candidates
(all waves listed here)
```

---

## Generation coverage

After Wave 1, verify names appear from all 7 archetypes:

| Archetype | Minimum candidates |
|-----------|--------------------|
| Short & Punchy | ≥ 3 |
| Descriptive | ≥ 3 |
| Abstract/Brandable | ≥ 3 |
| Playful/Clever | ≥ 3 |
| Domain Hacks | ≥ 3 |
| Compound/Mashup | ≥ 3 |
| Thematic TLD Play | ≥ 3 |

Total Wave 1: 25–35 candidates.

---

## Availability check validation

**With Cloudflare credentials configured:**
1. Verify each shortlist entry shows `Available: ✓` or `Available: ✗`
2. Verify price is shown for available domains
3. Verify Porkbun fallback is not invoked when CF succeeds

**Without credentials (whois fallback):**
1. Remove API credentials from plugin settings
2. Run `/namesmith` through to availability check
3. Verify whois is invoked and results shown (even if slower / less structured)
4. Verify Claude warns that pricing is unavailable in whois mode

---

## Wave iteration validation

1. Complete Wave 1
2. Tell Claude you want "more playful options"
3. Verify Wave 2 runs with narrowed brief
4. Verify Wave 2 candidates do not repeat Wave 1 names

**Track B (fully taken results):**
1. Force all Wave 1 names to show as unavailable (use a very common word)
2. Verify Claude offers Track B — alternative TLD exploration or new archetypes
3. Verify Track B runs without repeating the full brand interview

---

## Regression checklist before any PR

- [ ] All 6 interview questions asked in the correct order
- [ ] Wave 1 produces 25–35 candidates across all 7 archetypes
- [ ] Availability check runs for all shortlisted names
- [ ] `names.md` written with shortlist, rationale, and brand profile
- [ ] Wave 2 refinement narrows results without full re-interview
- [ ] Cloudflare → Porkbun → whois fallback chain works correctly
- [ ] Track B offered when all Wave 1 names unavailable
