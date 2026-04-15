# Namesmith — Testing Guide

> How to validate Namesmith behaviour against its acceptance criteria.

Namesmith has no runtime application code — it is an AI agent system. "Testing" means running the plugin in Claude Code and verifying observable outputs match the scenarios below. Gherkin feature specs live in `docs/plugins/namesmith/specs/` (to be written).

---

## Prerequisites

```bash
# Install plugin locally
cc --plugin-dir /path/to/plugins/namesmith

# For Tier 1 (Cloudflare) testing
export CF_API_TOKEN="your-token"
export CF_ACCOUNT_ID="your-account-id"

# For Tier 2 (Porkbun) testing
export PORKBUN_API_KEY="pk1_..."
export PORKBUN_SECRET="sk1_..."

# For Tier 3 (whois fallback) — ensure whois is installed
brew install whois   # macOS
```

---

## Script smoke tests (run before any session)

```bash
# Both must exit 2 with no args
plugins/namesmith/skills/site-naming/scripts/check-domains.sh 2>&1 | head -1
# Expected: "Usage: check-domains.sh <domain1> [domain2] ..."

plugins/namesmith/skills/site-naming/scripts/get-prices.sh 2>&1 | head -1
# Expected: "Usage: get-prices.sh <tld1> [tld2] ..."

# Syntax check
bash -n plugins/namesmith/skills/site-naming/scripts/check-domains.sh
bash -n plugins/namesmith/skills/site-naming/scripts/get-prices.sh
# Expected: no output (clean)

# Both must be executable
ls -l plugins/namesmith/skills/site-naming/scripts/
# Expected: -rwxr-xr-x for both files
```

---

## Skill trigger validation

Verify the skill activates on these phrases (without any other context):

| Phrase | Should trigger |
|--------|---------------|
| "find me a domain for my project" | ✅ |
| "name my new SaaS" | ✅ |
| "what should I call this CLI tool?" | ✅ |
| "domain for my portfolio" | ✅ (personal brand flow) |
| "I need a site name for a code review tool" | ✅ |
| "help me name this" | ✅ |
| "what is the weather today" | ❌ should not trigger |

---

## Brand interview validation

Run: ask "find me a domain for my project — it's a task management app for freelancers"

1. Verify Step 1: Skill offers to read project files if any exist in CWD
2. Verify Step 2: No personal brand signals detected → proceeds to interview
3. Verify Q1 is the first question asked
4. Answer each question — verify only ONE question is asked per message (never multiple)
5. After Q6, verify the brand profile summary appears:

```
Brand profile locked:
- Building: [your Q1 answer]
- Tone: [A/B/C label]
- Direction: [A/B label]
- Mode: [A/B/C label]
- Length: [A/B label]
- Constraints: [your Q6 answer or "none"]
```

---

## Personal brand flow validation

Run: "I need a domain for my personal website — I'm John Smith, a freelance designer"

1. Verify skill detects personal brand signals ("personal website", "freelance", name pattern)
2. Verify it loads personal brand patterns — checks `johnsmith.com`, `johnsmith.dev`, `john.studio`, etc.
3. Verify it presents availability results for name patterns
4. Verify it offers: "Want me to also generate creative branded alternatives beyond your name?"
5. **Accept path:** verify standard interview starts at Q2 (Q1 pre-filled with "John Smith")
6. **Decline path:** verify it proceeds to Step 5 (availability check) then Step 6 (output) — does NOT jump straight to formatting without checking availability

---

## Wave 1 generation coverage

After completing the full interview, verify Wave 1 output:

| Archetype | Minimum candidates |
|-----------|--------------------|
| Short & Punchy | ≥ 3 (≤6 chars each if Q5=A) |
| Descriptive | ≥ 3 |
| Abstract/Brandable | ≥ 3 |
| Playful/Clever | ≥ 3 |
| Domain Hacks | ≥ 2 |
| Compound/Mashup | ≥ 3 |
| Thematic TLD Play | ≥ 2 |

**Total Wave 1:** 25–35 candidates.

**Weighting check:** Set Q2=B + Q3=A. Verify Descriptive and Compound/Mashup have noticeably more candidates than other archetypes.

---

## Availability check validation

### Tier 1 — Cloudflare (with CF_API_TOKEN + CF_ACCOUNT_ID set)
1. Complete Wave 1 interview
2. Verify `check-domains.sh` is invoked
3. Verify output shows `✅ available`, `❌ taken` statuses with prices
4. Verify batching: if >20 candidates, script called with ≤20 per invocation
5. Verify Porkbun is NOT invoked when CF responds successfully

### Tier 2 — Porkbun (with PORKBUN_API_KEY + PORKBUN_SECRET set, no CF vars)
1. Unset `CF_API_TOKEN` and `CF_ACCOUNT_ID`
2. Complete Wave 1
3. Verify Porkbun check is invoked per domain
4. Verify `get-prices.sh` also runs (it always runs regardless of tier)

### Tier 3 — whois fallback (no API keys set)
1. Unset all four API env vars
2. Verify skill loads `api-setup.md` and shows setup instructions before proceeding
3. Verify whois is invoked and results shown
4. Verify price shows as `na` for all domains (no pricing in whois mode)
5. Verify `❓ unknown` status is possible output when whois returns no match

---

## Output format validation

After availability check, verify Wave results output:

```
## Wave [N] Results — [project description]

**Top Picks**
✅ [name].[tld]   $[price]/yr  — [one-sentence rationale]
   [[Registrar] →]([registration_url])

...

---
TLD summary: .com [X available] | .io [X available] | .dev [X available] | hacks [X available]
[X] of [Y] checked available. Anything catching your eye, or should I run Wave 2?
```

Verify:
- Registration links point to the correct registrar for each TLD (Cloudflare for .com when CF configured, Porkbun for .io, Namecheap for .ly, Dynadot for .gg)
- ⚠️ redemption domains show a note about elevated recovery cost
- TLD summary line is present

---

## `names.md` schema validation

After wave output, verify `names.md` is written to the current working directory with exactly this structure:

```markdown
# Name Shortlist — [project description]
_Generated: [YYYY-MM-DD] | Mode: [mode] | Tone: [tone] | Direction: [direction]_

## Shortlisted
| Name | Price/yr | Status | Rationale |
|------|----------|--------|-----------|
| [name] | $[price] | ✅ available | [rationale verbatim from conversation] |

## Considered / Taken
| Name | Status | Alternative |
|------|--------|-------------|
| [name] | ❌ taken | [alternative if known] |

## Brand Interview
- Building: [Q1]
- Tone: [Q2 answer]
- Direction: [Q3 answer]
- Mode: [Q4 answer]
- Length: [Q5 answer]
- Constraints: [Q6 answer]
```

Verify:
- Shortlisted contains 3–5 available names (not all candidates)
- Rationale column text matches verbatim what appeared in the conversation output
- Brand Interview section fully populated

---

## Wave iteration validation

### Wave 2
1. After Wave 1, say "I want more options like the abstract ones, fewer compound names"
2. Verify Wave 2 generates 20+ NEW candidates (no repeats from Wave 1)
3. Verify generation is biased toward Abstract/Brandable archetype

### Wave 3 (deep scan)
1. After Wave 1, say "check more TLDs" or "deep scan"
2. Verify skill loads `generation-archetypes.md` Wave 3 section
3. Verify it attempts to scan multiple TLDs for the top base words

### Track B (all top picks taken)
When all Wave 1 top picks are taken, verify the 4 strategies run in order:

1. **Close variations** — generates `get{base}`, `{base}hq`, `{base}labs` etc. on .com/.io
2. **Synonym exploration** — finds meaning-equivalent words for taken bases
3. **Creative reconstruction** — generates 10 new names using only metaphor mining + abstract archetypes
4. **Domain hacks** — scans tld-catalog.md domain hack catalog for base word fragments

Verify Track B stops as soon as 5+ available options are found.

---

## Post-shortlist checklist validation

After the user says "I'll go with [name]" or confirms a final shortlist:

1. Verify `post-shortlist.md` is loaded
2. Verify the checklist covers all 5 sections: pronunciation, social handles, trademark, registration strategy, names.md update
3. Verify `names.md` is updated with handle and trademark findings
4. Verify the trademark section names USPTO, EUIPO, and WIPO search URLs

---

## Regression checklist before any PR

- [ ] Skill triggers on all expected natural language phrases
- [ ] Personal brand detection works (portfolio/freelance/name signals)
- [ ] Exactly 6 interview questions asked, one per message
- [ ] Brand profile summary output after Q6
- [ ] Wave 1 produces 25–35 candidates across all 7 archetypes
- [ ] Archetype weighting responds to Q2+Q3+Q4+Q5 answers
- [ ] `check-domains.sh` called with batches of ≤20
- [ ] `get-prices.sh` always runs (auth-free)
- [ ] `names.md` written with correct schema (3 sections)
- [ ] Registration links use correct registrar per TLD
- [ ] Wave 2 doesn't repeat Wave 1 candidates
- [ ] Track B runs all 4 strategies in order, stops at 5+ available
- [ ] Post-shortlist checklist loads after shortlist confirmed
- [ ] Env var check shows `set`/`not set` (never the actual token value)
