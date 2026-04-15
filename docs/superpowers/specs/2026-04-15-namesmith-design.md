# Namesmith Plugin — Design Spec

**Date:** 2026-04-15
**Status:** Approved (v2 — post-audit)
**Author:** Georgios Pilitsoglou

---

## Overview

Namesmith is a standalone Claude Code plugin that helps users find available, well-named domains for their projects. It differentiates from all existing tools through a structured brand personality interview that shapes generation strategy before a single name is produced, then generates names across 7 archetypes using 10 proven techniques, checks availability and pricing via a 3-tier API stack, and persists a shortlist to `names.md` in the project directory.

**Target users:** Developers, indie hackers, and builders who need to name a project, product, startup, or personal brand.

**Plugin name:** `namesmith`
**Location in repo:** `plugins/namesmith/`
**Version:** `0.1.0`

---

## Problem Statement

Existing domain naming tools (domain-name-brainstormer, domain-puppy, domain-finder-mcp) share a common weakness: they take a flat project description and immediately generate names. None conduct a brand positioning interview before generation. The output is generic — it does not reflect whether the user wants something cool and media-brand like Letterboxd, authoritative like Linear, or playful like Notion. Namesmith fills this gap.

---

## Architecture & Flow

```
User prompt (naming intent detected)
        │
        ▼
[1] Project File Detection
    └── If README.md / package.json / pyproject.toml / Cargo.toml / go.mod exists
        → offer to read for context (supplements brand interview)
        │
        ▼
[2] Personal Brand Detection
    └── If description suggests personal portfolio/freelance → branch to personal branding flow
        Otherwise → continue to standard brand interview
        │
        ▼
[3] Brand Interview (6 questions, one at a time)
    Load references/brand-interview.md before Q1
        │
        ▼
[4] Wave 1 Generation (25–35 names across 7 archetypes, weighted by interview)
    Load references/generation-archetypes.md before generation
    Load references/tld-catalog.md when archetype = Domain Hacks / Thematic TLD Play, or Mode=A
        │
        ▼
[5] API Check (scripts/check-domains.sh → CF → Porkbun → whois+MCP fallback)
    + scripts/get-prices.sh (Porkbun no-auth pricing, always runs)
    Load references/api-setup.md if no API env vars are detected
        │
        ▼
[6] Output — available names with TLD summary, price, "Why" rationale, top picks
    Load references/registrar-routing.md to attach registration links
    → Write names.md in CWD
        │
        ▼
[7] Feedback loop
    └── "Anything catching your eye, or should I run Wave 2?"
    └── Wave 2 — refine based on feedback
    └── Wave 3 (on request) — deep TLD scan + exhaustive technique pass
    └── Track B — when top picks taken
    └── Load references/post-shortlist.md after user confirms shortlist
```

---

## Component Inventory

```
namesmith/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── site-naming/
│       ├── SKILL.md                          ← lean orchestration (~1,800 words)
│       ├── references/
│       │   ├── brand-interview.md            ← 6 questions, weighting rules, personal brand branch
│       │   ├── generation-archetypes.md      ← 7 archetypes, 10 techniques, Track B, Wave 3
│       │   ├── tld-catalog.md                ← cheap/trendy/thematic/domain-hack catalogs
│       │   ├── registrar-routing.md          ← per-TLD registrar links + pricing context  ← NEW
│       │   ├── api-setup.md                  ← env var setup, API key instructions, fallback logic
│       │   └── post-shortlist.md             ← checklist: social handles, trademark, act fast
│       ├── examples/
│       │   └── example-session.md            ← complete run: interview → Wave 1 → names.md  ← NEW
│       └── scripts/
│           ├── check-domains.sh              ← 3-tier availability check, outputs available|taken|redemption|unknown
│           └── get-prices.sh                 ← Porkbun no-auth pricing, always runs
└── README.md
```

**No agents, hooks, or MCP server.** The skill calls REST APIs directly via shell scripts. Dependency-free for users with a Cloudflare or Porkbun account, degrades gracefully to whois for users with no API keys.

---

## SKILL.md Design Contract

### Word budget

SKILL.md body: **target 1,700 words, hard cap 2,000 words.** All detailed content belongs in references/. The body contains only orchestration logic, step sequence, and "load X when Y" pointers.

### Writing style

- Frontmatter description: **third-person** ("This skill should be used when the user asks...")
- Body: **imperative/verb-first** throughout. No "you should", "users can", passive constructions.
- Correct: "Run the brand interview.", "Generate Wave 1 candidates.", "Execute check-domains.sh."
- Incorrect: "You should run the brand interview.", "The user can generate names."

### Frontmatter (exact)

```yaml
---
name: site-naming
description: >
  This skill should be used when the user asks for help naming a site, product,
  project, startup, or personal brand — or needs to find an available domain.
  Trigger phrases: "find me a domain", "name my project", "site name for",
  "what should I call", "available domains for", "I have an idea about X find me a name",
  "domain for [concept]", "naming [project]", "domain for my portfolio",
  "find me a site name", "help me name this". Also triggers when the user describes
  a project idea and mentions needing a web presence.
version: 0.1.0
---
```

### Progressive disclosure — load gates

All reference files are loaded conditionally, never eagerly:

| File | Load condition |
|------|---------------|
| `references/brand-interview.md` | Before Q1 of the brand interview |
| `references/generation-archetypes.md` | Before Wave 1 generation begins |
| `references/tld-catalog.md` | When archetype = Domain Hacks or Thematic TLD Play, OR when Mode=A (budget) |
| `references/registrar-routing.md` | When formatting the Wave 1 output (to attach registration links) |
| `references/api-setup.md` | When neither CF_API_TOKEN nor PORKBUN_API_KEY is set |
| `references/post-shortlist.md` | After user confirms final shortlist names |

---

## Section 1: Brand Interview

**Lives in: `references/brand-interview.md`**

### Personal Brand Detection (before Q1)

If Q1 answer or project description contains signals of a personal brand (freelancer, portfolio, consultant, "my name", "personal site", first/last name mentioned), branch to personal branding flow:

Generate these patterns first, then offer to continue to main archetype generation:
- `{firstname}.com` / `{firstname}.dev` / `{firstname}.io`
- `{firstnamelastname}.com` / `{firstnamelastname}.dev`
- `{initiallastname}.dev` / `{initiallastname}.com`
- `{firstname}.studio` / `{firstname}.design` / `{firstname}.work`

### Standard Interview — 6 Questions

One question per message. Multiple-choice where possible.

| # | Question | Format |
|---|----------|--------|
| Q1 | What are you building? (one-liner or keywords) | Open |
| Q2 | Personality: **a)** Cool/media-brand (Figma, Letterboxd, Vercel) **b)** Authoritative/benchmark (Linear, Bloomberg, Stripe) **c)** Playful/community (Discord, Notion) | A/B/C |
| Q3 | Direction: **a)** Functional — name says what it does (DevAtlas, CodeShip) **b)** Abstract/invented — memorable non-word (Lumora, Vercel) | A/B |
| Q4 | Budget mode: **a)** Budget (open to .icu/.xyz, cheapest viable) **b)** Balanced (mix of .com/.io/.dev) **c)** Premium (.com strongly preferred) | A/B/C |
| Q5 | Name length: **a)** Short & punchy (≤6 chars: Figma, Driv) **b)** Expressive (7+: Letterboxd, Cloudflare) | A/B |
| Q6 | Hard constraints? (must include word, avoid hyphens, specific TLD required, etc.) | Open or "none" |

### Interview → Weighting Rules

| Answer combination | Generation weighting |
|-------------------|---------------------|
| Tone=A + Direction=B | Abstract/Brandable 2×, Domain Hacks 1.5× |
| Tone=B + Direction=A | Descriptive 2×, Compound/Mashup 2× |
| Tone=C | Playful/Clever 2×, Short & Punchy 1.5× |
| Mode=A | TLD catalog skews cheap (.icu, .xyz, .top, .online, .site) |
| Mode=C | TLD catalog skews .com primary, .io/.dev secondary only |
| Length=A | Short & Punchy archetype weighted 2× |

---

## Section 2: Name Generation

**Lives in: `references/generation-archetypes.md`**

### Wave System

- **Wave 1 (default):** 25–35 candidates across all 7 archetypes, weighted by interview answers
- **Wave 2 (after feedback):** 20+ new candidates refined toward stated preferences ("more like X, avoid Y")
- **Wave 3 (on request or after Wave 2):** 40+ candidates — relax all Q6 constraints, apply all 10 techniques exhaustively to every synonym of the core concept, run a deep TLD scan across 1,441+ IANA TLDs for top 5 base words

### 7 Generation Archetypes

| Archetype | Examples | Primary Techniques |
|-----------|----------|--------------------|
| Short & Punchy | Vex, Driv, Navo, Pique | Truncation, phonetic spelling |
| Descriptive | CodeShip, DeployFast, BuildStack | Compound, keyword-rich |
| Abstract/Brandable | Lumora, Zentrik, Covalent | Portmanteau, metaphor mining, word reversal |
| Playful/Clever | GitWhiz, ByteMe, NullPointerBeer | Wordplay, alliteration, internal rhyme |
| Domain Hacks | bra.in, gath.er, cra.sh, plu.sh | ccTLD catalog (22 entries — load tld-catalog.md) |
| Compound/Mashup | CloudForge, PixelNest, DataMint | Two-word merge, prefix/suffix patterns |
| Thematic TLD Play | build.studio, launch.ai, code.run | Project-type TLD matrix (12 categories — load tld-catalog.md) |

### 10 Generation Techniques

1. **Portmanteau** — blend two words (Cloud + Forge = CloudForge)
2. **Truncation** — shorten a word (Technology → Tekno)
3. **Phonetic spelling** — respell for style (Light → Lyte, Quick → Kwik)
4. **Prefix/suffix patterns** — get-, try-, use-, my-, the-, -app, -hq, -labs, -now, -ly, -ify, -hub
5. **Metaphor mining** — Atlas, Nimbus, Vertex, Forge, Drift, Beacon
6. **Alliteration** — PixelPush, DataDash, CodeCraft
7. **Word reversal** — Etalon from Notable
8. **Foreign language** — short punchy words that sound great in English
9. **Acronym generation** — from project description initials
10. **Internal rhyme** — ClickPick, CodeRode, SwitchPitch

### Track B (Taken Domain Fallback)

When top picks are taken, run 4 strategies in order:
1. **Close variations** — prefix/suffix modifiers (`get{base}`, `{base}hq`, `{base}labs`) on .com + .io
2. **Synonym exploration** — replace key words with synonyms, 5–8 candidates
3. **Creative reconstruction** — generate concept-based names from scratch
4. **Domain hacks** — use ccTLD to complete the word (load tld-catalog.md)

---

## Section 3: API Check Stack

**Scripts live in: `skills/site-naming/scripts/`**

### check-domains.sh

**Header comment required:**
```bash
#!/usr/bin/env bash
# Usage: check-domains.sh <domain1> <domain2> ... <domainN>
# Output: one line per domain — available|taken|redemption|unknown <domain> <price_usd_or_na>
# Env vars: CF_API_TOKEN + CF_ACCOUNT_ID (tier 1), PORKBUN_API_KEY + PORKBUN_SECRET (tier 2)
# Exit codes: 0=success, 1=all unknown (API error), 2=no domains provided
```

**Priority order (batches up to 20 per Cloudflare call):**

```
Tier 1: CF_API_TOKEN + CF_ACCOUNT_ID set
  → POST /accounts/{id}/registrar/domain-check
  → Returns: availability + Cloudflare at-cost price

Tier 2: PORKBUN_API_KEY + PORKBUN_SECRET set
  → POST https://api.porkbun.com/api/json/v3/domain/checkDomain/{domain}
  → Returns: avail:yes/no + price per year

Tier 3: Neither set
  → whois {domain} (grep "No match|NOT FOUND|Status: free")
  → If whois returns unknown AND mcp__domain_availability__check_domain is available → retry via MCP
  → DNS + WHOIS cross-reference:
      DNS resolves + WHOIS no record → "redemption" (recently expired, elevated price)
      DNS no record + WHOIS active → "taken" (registered, not yet live)
      Both clean → "available"
  → Availability only (no price from whois/MCP)
```

**Output status values:** `available` · `taken` · `redemption` · `unknown`

### get-prices.sh

**Header comment required:**
```bash
#!/usr/bin/env bash
# Usage: get-prices.sh <tld1> <tld2> ... <tldN>
# Output: one line per TLD — <tld> <registration_price_usd> <renewal_price_usd>
# Auth: none required
# Exit codes: 0=success, 1=network error
```

```
POST https://api.porkbun.com/api/json/v3/pricing/get
→ Returns registration/renewal/transfer prices per TLD in USD
→ Always runs regardless of which tier handles availability checking
→ Provides price reference even when tier 3 (whois) is used
```

---

## Section 4: Output Format

### In-conversation output

```
## Wave 1 Results — [project description]

**Top Picks**
✅ namesmith.dev   $12/yr  — Functional + dev-audience TLD, says what you do, memorable
   [Register at Cloudflare →] or [Porkbun →]
✅ nameforge.io    $35/yr  — Strong compound, .io signals tech startup credibility

**Short & Punchy**
✅ navo.co          $25/yr  — Two syllables, clean, no meaning baggage
❌ navo.com         taken   → check aftermarket
⚠️ navo.net         redemption  → recently expired, may cost $80+ to recover

**Abstract/Brandable**
✅ lumora.app       $14/yr  — Invented word, soft sound, modern feel

**Domain Hacks**
✅ na.me             $8/yr  — Minimal, clever, instantly memorable

---
TLD summary: .com taken | .io 2 available | .dev 3 available | ccTLD hacks 4 available
12 of 34 checked available. Anything catching your eye, or should I run Wave 2?
```

**Registration links** (from registrar-routing.md): append a `[Register →]` link for each available domain pointing to the correct registrar URL for that TLD.

### names.md (written to CWD)

```markdown
# Name Shortlist — [project description]
_Generated: YYYY-MM-DD | Mode: balanced | Tone: cool/media-brand | Direction: abstract_

## Shortlisted
| Name | Price/yr | Status | Rationale |
|------|----------|--------|-----------|
| namesmith.dev | $12 | ✅ available | Functional + dev-audience TLD, says what you do |

## Considered / Taken
| Name | Status | Alternative |
|------|--------|-------------|
| navo.com | ❌ taken | navo.io available |
| navo.net | ⚠️ redemption | recently expired — elevated price |

## Brand Interview
- Building: ...
- Tone: cool/media-brand (A)
- Direction: abstract/invented (B)
- Mode: balanced (B)
- Length: short & punchy (A)
- Constraints: none
```

Note: `Rationale` column receives the archetype "Why" string from the in-conversation output verbatim.

---

## Section 5: Reference Files Specification

### brand-interview.md
- 6 questions with full wording and answer options
- Interview → archetype weighting mapping table
- Personal branding branch: detection signals + generation patterns

### generation-archetypes.md
- 7 archetypes with descriptions, examples, and primary techniques per archetype
- 10 technique definitions with worked examples
- Weighting rules keyed to interview answer combinations
- Wave system: Wave 1/2/3 candidate counts and refinement rules
- Track B: 4 fallback strategies with instructions

### tld-catalog.md
- Cheap TLDs (≤$5/yr): .icu, .xyz, .top, .online, .site, .fun, .space
- Trendy (not cheap) TLDs: .io (~$35), .ai (~$60), .gg (~$25), .dev (~$12)
- 12 thematic categories by project type: dev tools, creative, AI, gaming, business, community, commerce, education, health, music, finance, food
- Full domain hack catalog (22 ccTLDs): word fragment + TLD = complete word

### registrar-routing.md ← NEW
- Per-TLD-category registrar recommendation table
- URL patterns for direct registration links:
  - Cloudflare: `https://dash.cloudflare.com/{account_id}/domains/registrations/purchase?domain={domain}`
  - Porkbun: `https://porkbun.com/checkout/search?q={domain}`
  - Namecheap (fallback for TLDs CF/Porkbun don't support): `https://www.namecheap.com/domains/registration/results/?domain={domain}`
- Redemption domain guidance (Sedo aftermarket link pattern)
- Notes: which registrars carry which ccTLDs (Dynadot for .gg/.st/.pt, Porkbun for most)

### api-setup.md
- Environment variable setup instructions (Cloudflare + Porkbun)
- How to get Cloudflare API token and account ID
- How to get Porkbun API key + secret
- Fallback chain explanation (what works with zero config)
- `chmod +x scripts/check-domains.sh scripts/get-prices.sh` instruction
- DNS + WHOIS cross-reference explanation (redemption status)

### post-shortlist.md
- Checklist: say it out loud, check social handles (@name on X/GitHub/npm/Instagram)
- Trademark check: USPTO TESS, TMView (EU)
- Register both .com and one secondary TLD if budget allows
- Act fast: good domains get taken quickly
- Variations worth registering (typosquatting protection)

---

## Section 6: Examples

### examples/example-session.md

A complete worked example covering:
1. User prompt: "I have an idea for a developer productivity SaaS that helps teams track code review bottlenecks — find me a site name"
2. Project file detection offer
3. All 6 interview Q&As with sample answers
4. Wave 1 output block (full, with TLD summary and registration links)
5. User feedback ("I like nameforge, more like that")
6. Wave 2 refinement output
7. Resulting `names.md` content

---

## Plugin Manifest

```json
{
  "name": "namesmith",
  "version": "0.1.0",
  "description": "Find the right name for your project — brand interview, AI generation across 7 archetypes, live availability + pricing via Cloudflare or Porkbun.",
  "author": {
    "name": "Georgios Pilitsoglou",
    "url": "https://pilitsoglou.com",
    "github": "neotherapper"
  },
  "homepage": "https://github.com/neotherapper/claude-plugins/tree/main/plugins/namesmith",
  "repository": "https://github.com/neotherapper/claude-plugins",
  "license": "MIT",
  "keywords": ["naming", "domains", "branding", "site-name", "domain-availability"]
}
```

---

## Audit Gap Resolutions

All 14 gaps from the post-approval audit are addressed:

| # | Gap | Resolution |
|---|-----|------------|
| 1 | SKILL.md word budget | SKILL.md design contract added: target 1,700 words, hard cap 2,000 |
| 2 | No progressive disclosure gating | Load gates table added to SKILL.md design contract |
| 3 | Second-person style in spec | Writing style contract added; body imperative-only |
| 4 | Trigger description wrong person | Frontmatter rewritten in third-person |
| 5 | post-shortlist.md + api-setup.md orphaned | Both now have explicit load conditions |
| 6 | No examples/ directory | examples/example-session.md added to inventory |
| 7 | Scripts not documented as executable | Header comment block spec added to Section 3 |
| 8 | Registrar routing table missing | registrar-routing.md added as 6th reference file |
| 9 | Personal branding flow missing | Personal brand detection + generation branch added to Section 1 |
| 10 | Deep TLD scan not surfaced | Wave 3 now includes 1,441+ IANA TLD deep scan |
| 11 | TLD category summary missing | TLD summary footer added to output format |
| 12 | DNS+WHOIS dual verification unspecified | Cross-reference logic + redemption status added to Section 3 |
| 13 | Wave 3 undefined | Wave 3 fully defined in Section 2 |
| 14 | "Why" rationale not wired to names.md | Notes column renamed to Rationale, wired explicitly |

---

## What This Is Not

- Not a domain registrar — helps find and shortlist names, not purchase them
- Not a trademark checker — post-shortlist.md reminds users to verify
- Not a brand identity tool — naming only, no logo/color suggestions
- Not an MCP server — uses direct REST API calls via shell scripts

---

## Existing Tools Reviewed

| Tool | Gap addressed by Namesmith |
|------|---------------------------|
| domain-name-brainstormer | No brand interview, no persistence |
| domain-puppy | Shallow 3-question interview, no brand positioning |
| domain-finder-mcp | No interview, requires MCP server install |
| mcp-domain-availability | Checking only, no generation |

---

## Future Work (v0.2+)

- v0.2: Aftermarket price check (Sedo) for taken desirable domains
- v0.2: Social handle availability check (X, GitHub, npm, PyPI, Homebrew)
- v0.3: Trademark conflict detection via USPTO TESS / TMView API
- v0.3: Multi-session registry — global `~/.namesmith/registry.md` for serial builders
