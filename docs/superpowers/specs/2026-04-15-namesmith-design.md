# Namesmith Plugin — Design Spec

**Date:** 2026-04-15
**Status:** Approved
**Author:** Georgios Pilitsoglou

---

## Overview

Namesmith is a standalone Claude Code plugin that helps users find available, well-named domains for their projects. It differentiates from all existing tools through a structured brand personality interview that shapes generation strategy before a single name is produced, then generates names across 7 archetypes using 10 proven techniques, checks availability and pricing via a 3-tier API stack, and persists a shortlist to `names.md` in the project directory.

**Target users:** Developers, indie hackers, and builders who need to name a project, product, or startup.

**Plugin name:** `namesmith`
**Location in repo:** `plugins/namesmith/`
**Version:** `0.1.0`

---

## Problem Statement

Existing domain naming tools (domain-name-brainstormer, domain-puppy, domain-finder-mcp) share a common weakness: they take a flat project description and immediately generate names. None of them conduct a brand positioning interview before generation. This means the output is generic — it does not reflect whether the user wants something cool and media-brand like Letterboxd, authoritative like Linear, or playful like Notion. Namesmith fills this gap.

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
[2] Brand Interview (6 questions, one at a time)
        │
        ▼
[3] Wave 1 Generation (25–35 names across 7 archetypes, weighted by interview)
        │
        ▼
[4] API Check (check-domains.sh → CF → Porkbun → whois/MCP fallback)
    + get-prices.sh (Porkbun no-auth pricing, always runs)
        │
        ▼
[5] Output — available names with price + "Why" rationale, top 3 recommendation
    → writes names.md in CWD
        │
        ▼
[6] Feedback loop
    └── "Anything catching your eye, or should I run Wave 2?"
    └── Wave 2 refines based on feedback (more like X, avoid Y)
    └── Track B if all top picks taken
```

---

## Component Inventory

```
namesmith/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── site-naming/
│       ├── SKILL.md
│       ├── references/
│       │   ├── brand-interview.md
│       │   ├── generation-archetypes.md
│       │   ├── tld-catalog.md
│       │   ├── api-setup.md
│       │   └── post-shortlist.md
│       └── scripts/
│           ├── check-domains.sh
│           └── get-prices.sh
└── README.md
```

**No agents, hooks, or MCP server.** The skill calls REST APIs directly via shell scripts. This keeps the plugin dependency-free for users who only have a Cloudflare or Porkbun account, and degrades gracefully to whois for users with no API keys.

---

## Section 1: Skill Trigger

**File:** `skills/site-naming/SKILL.md`

**Trigger description (frontmatter):**
> Invoke when the user asks for help naming a site, product, project, or startup — or needs to find an available domain. Trigger phrases: "find me a domain", "name my project", "site name for", "what should I call", "available domains for", "I have an idea about X find me a name", "domain for [concept]", "naming [project]". Also triggers when user describes a project idea and mentions needing a web presence.

---

## Section 2: Brand Interview

Six questions, one per message. Multiple-choice where possible to reduce friction.

| # | Question | Format |
|---|----------|--------|
| Q1 | What are you building? (one-liner or keywords) | Open |
| Q2 | Personality: **a)** Cool/media-brand (Figma, Letterboxd, Vercel) **b)** Authoritative/benchmark (Linear, Bloomberg, Stripe) **c)** Playful/community (Discord, Notion) | A/B/C |
| Q3 | Direction: **a)** Functional — name says what it does (DevAtlas, CodeShip) **b)** Abstract/invented — memorable non-word (Lumora, Vercel) | A/B |
| Q4 | Budget mode: **a)** Budget (open to .icu/.xyz, cheapest viable) **b)** Balanced (mix of .com/.io/.dev) **c)** Premium (.com strongly preferred) | A/B/C |
| Q5 | Name length: **a)** Short & punchy (≤6 chars: Figma, Driv) **b)** Expressive (7+: Letterboxd, Cloudflare) | A/B |
| Q6 | Hard constraints? (must include word, avoid hyphens, specific TLD required, etc.) | Open or "none" |

Interview answers directly weight the generation archetypes:
- Tone=A + Direction=B → heavy Abstract/Brandable + Domain Hack weighting
- Tone=B + Direction=A → heavy Descriptive + Compound weighting
- Mode=A → TLD catalog skews to cheap extensions (.icu, .xyz, .top, .online)
- Mode=C → TLD catalog skews to .com, with .io/.dev as secondaries
- Length=A → Short & Punchy archetype weighted 2×

**Project file detection:** Before Q1, if `README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, or `go.mod` exists in CWD, offer:
> "I can read your project files to better understand what you're building — want me to?"
If accepted, extract project name, description, and keywords to pre-fill Q1 context.

---

## Section 3: Name Generation

### Wave System

- **Wave 1 (default):** 25–35 candidates across all 7 archetypes
- **Wave 2 (after feedback):** 20+ new candidates, refined toward user preferences
- **Wave 3 (on request):** Deep dive, unlimited

### 7 Generation Archetypes

| Archetype | Examples | Primary Techniques |
|-----------|----------|--------------------|
| Short & Punchy | Vex, Driv, Navo, Pique | Truncation, phonetic spelling |
| Descriptive | CodeShip, DeployFast, BuildStack | Compound, keyword-rich |
| Abstract/Brandable | Lumora, Zentrik, Covalent | Portmanteau, metaphor mining, word reversal |
| Playful/Clever | GitWhiz, ByteMe, NullPointerBeer | Wordplay, alliteration, internal rhyme |
| Domain Hacks | bra.in, gath.er, cra.sh, plu.sh | ccTLD catalog (22 entries, see tld-catalog.md) |
| Compound/Mashup | CloudForge, PixelNest, DataMint | Two-word merge, prefix/suffix patterns |
| Thematic TLD Play | build.studio, launch.ai, code.run | Project-type TLD matrix (12 categories, see tld-catalog.md) |

### 10 Generation Techniques (encoded in generation-archetypes.md)

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
3. **Creative reconstruction** — step back entirely, generate concept-based names from scratch
4. **Domain hacks** — use ccTLD to complete the word (see catalog)

---

## Section 4: API Check Stack

### check-domains.sh

Accepts a list of domains as arguments. Batches up to 20 per call (Cloudflare limit).

```
Priority order:
1. CF_API_TOKEN + CF_ACCOUNT_ID set
   → POST /accounts/{id}/registrar/domain-check
   → Returns: availability + Cloudflare at-cost price per domain

2. PORKBUN_API_KEY + PORKBUN_SECRET set
   → POST https://api.porkbun.com/api/json/v3/domain/checkDomain/{domain}
   → Returns: availability (avail: yes/no) + price per year

3. Neither set
   → whois {domain} (grep "No match|NOT FOUND|Status: free")
   → If whois returns "unknown" AND mcp__domain_availability__check_domain is available, retry via MCP
   → Availability only, no price from either

Output format (one line per domain):
  available|taken|unknown <domain> <price_usd_or_na>
```

### get-prices.sh

Accepts TLD list as arguments. Always runs — requires no auth.

```
POST https://api.porkbun.com/api/json/v3/pricing/get
→ Returns registration/renewal/transfer prices per TLD in USD
→ Output: one line per TLD — <tld> <registration_price> <renewal_price>
```

### Environment Variable Setup (documented in api-setup.md)

```bash
# Cloudflare (preferred — at-cost pricing, no markup)
export CF_API_TOKEN="your_token"
export CF_ACCOUNT_ID="your_account_id"   # from dash.cloudflare.com URL

# Porkbun (alternative — competitive pricing)
export PORKBUN_API_KEY="your_key"
export PORKBUN_SECRET="your_secret"

# Neither set → whois fallback (availability only, Porkbun reference prices always shown)
```

---

## Section 5: Output Format

### In-conversation output

```
## Wave 1 Results — [project description]

**Top Picks**
✅ namesmith.dev   $12/yr  — Functional + dev-audience TLD, says what you do, memorable
✅ nameforge.io    $35/yr  — Strong compound, .io signals tech startup credibility

**Short & Punchy**
✅ navo.co          $25/yr  — Two syllables, clean, no meaning baggage
❌ navo.com         taken   → check aftermarket or try navo.io

**Abstract/Brandable**
✅ lumora.app       $14/yr  — Invented word, soft sound, modern feel

**Domain Hacks**
✅ na.me             $8/yr  — Minimal, clever, instantly memorable

---
12 of 34 checked available.
Anything catching your eye, or should I run Wave 2?
```

### names.md (written to CWD)

```markdown
# Name Shortlist — [project description]
_Generated: YYYY-MM-DD | Mode: balanced | Tone: cool/media-brand | Direction: abstract_

## Shortlisted
| Name | Price/yr | Checked | Notes |
|------|----------|---------|-------|
| namesmith.dev | $12 | ✅ available | Top pick |

## Considered / Taken
| Name | Status | Alternative |
|------|--------|-------------|
| navo.com | ❌ taken | navo.io available |

## Brand Interview
- Building: ...
- Tone: cool/media-brand
- Direction: abstract/invented
- Mode: balanced
- Length: short & punchy
- Constraints: none
```

---

## Section 6: Reference Files

| File | Contents |
|------|----------|
| `brand-interview.md` | 6 questions with answer→weighting mapping, guidance on how answers shape generation |
| `generation-archetypes.md` | 7 archetypes with descriptions, 10 techniques with examples, weighting rules per interview answer |
| `tld-catalog.md` | Cheap TLDs (≤$5/yr), trendy TLDs, 12 thematic categories by project type, full domain hack catalog (22 ccTLDs) |
| `api-setup.md` | Env var setup for Cloudflare and Porkbun, how to get API keys, fallback behavior explanation |
| `post-shortlist.md` | Checklist after shortlisting: say it out loud, check social handles, verify trademark, register .com + secondary TLD, act fast |

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

## What This Is Not

- Not a domain registrar — it helps you find and shortlist names, not purchase them
- Not a trademark checker — post-shortlist checklist reminds users to verify
- Not a brand identity tool — name generation only, no logo/color suggestions
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

## Open Questions / Future Work

- v0.2: Social handle availability check (Twitter/X, GitHub, npm)
- v0.2: Aftermarket price check (Sedo) for taken desirable domains
- v0.3: Trademark conflict detection via USPTO/TMView API
- v0.3: Multi-session registry — global `~/.namesmith/registry.md` for serial builders
