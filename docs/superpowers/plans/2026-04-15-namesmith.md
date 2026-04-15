# Namesmith Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `namesmith` Claude Code plugin — a brand-interview-first domain naming tool with 7 generation archetypes, 3-tier API availability checking (Cloudflare → Porkbun → whois), and per-project `names.md` persistence.

**Architecture:** Single skill plugin (`site-naming`) with a lean SKILL.md orchestration file, 6 reference files loaded progressively, 2 shell scripts for API checks, and 1 worked example. No agents, hooks, or MCP server.

**Tech Stack:** Bash (scripts), Markdown (all skill/reference files), Cloudflare Registrar API, Porkbun API v3, whois CLI, curl, jq

---

## File Map

| File | Responsibility |
|------|---------------|
| `plugins/namesmith/.claude-plugin/plugin.json` | Plugin manifest — name, version, author, keywords |
| `plugins/namesmith/skills/site-naming/SKILL.md` | Lean orchestration — 9-step flow, load gates, script references (~1,700 words) |
| `plugins/namesmith/skills/site-naming/references/brand-interview.md` | 6 interview questions, weighting rules, personal brand branch |
| `plugins/namesmith/skills/site-naming/references/generation-archetypes.md` | 7 archetypes, 10 techniques, wave rules, Track B |
| `plugins/namesmith/skills/site-naming/references/tld-catalog.md` | Cheap/trendy/thematic TLDs, 22-entry domain hack catalog |
| `plugins/namesmith/skills/site-naming/references/registrar-routing.md` | Per-TLD registrar table, registration URL patterns |
| `plugins/namesmith/skills/site-naming/references/api-setup.md` | Env var setup, API key instructions, fallback chain |
| `plugins/namesmith/skills/site-naming/references/post-shortlist.md` | Post-shortlist checklist |
| `plugins/namesmith/skills/site-naming/examples/example-session.md` | Complete worked session end-to-end |
| `plugins/namesmith/skills/site-naming/scripts/check-domains.sh` | 3-tier availability checker — outputs `available\|taken\|redemption\|unknown <domain> <price>` |
| `plugins/namesmith/skills/site-naming/scripts/get-prices.sh` | Porkbun no-auth TLD pricing — outputs `<tld> <reg_price> <renewal_price>` |
| `plugins/namesmith/README.md` | Plugin overview, installation, API setup, usage |
| `marketplace.json` | Add namesmith entry to marketplace |

---

## Task 1: Plugin Scaffold

**Files:**
- Create: `plugins/namesmith/.claude-plugin/plugin.json`
- Create: `plugins/namesmith/skills/site-naming/references/.gitkeep`
- Create: `plugins/namesmith/skills/site-naming/examples/.gitkeep`
- Create: `plugins/namesmith/skills/site-naming/scripts/.gitkeep`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p plugins/namesmith/.claude-plugin
mkdir -p plugins/namesmith/skills/site-naming/references
mkdir -p plugins/namesmith/skills/site-naming/examples
mkdir -p plugins/namesmith/skills/site-naming/scripts
```

- [ ] **Step 2: Write plugin.json**

Create `plugins/namesmith/.claude-plugin/plugin.json`:

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

- [ ] **Step 3: Verify structure**

```bash
find plugins/namesmith -type d
```

Expected output:
```
plugins/namesmith
plugins/namesmith/.claude-plugin
plugins/namesmith/skills
plugins/namesmith/skills/site-naming
plugins/namesmith/skills/site-naming/references
plugins/namesmith/skills/site-naming/examples
plugins/namesmith/skills/site-naming/scripts
```

- [ ] **Step 4: Commit**

```bash
git add plugins/namesmith/
git commit -m "feat(namesmith): plugin scaffold — manifest + directory structure"
```

---

## Task 2: SKILL.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Create `plugins/namesmith/skills/site-naming/SKILL.md` with the following content (imperative style, ~1,700 words, third-person frontmatter):

```markdown
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

# Site Naming

Help users discover, evaluate, and shortlist available domain names through a structured brand interview, multi-archetype generation, and live availability + pricing checks.

## Step 1: Project File Detection

Check for any of these files in the current working directory:
`README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`

If found, offer once: "I noticed you have project files here — want me to read them to better understand what you're building before we start?"

If accepted, read the file(s). Extract: project name, description, key features, target audience. Use this context to pre-fill Q1 of the brand interview.

## Step 2: Personal Brand Detection

Before running the standard interview, scan the user's description for personal brand signals:
- Keywords: "portfolio", "freelance", "my name", "personal site", "consulting"
- Pattern: a human first/last name as the primary subject

If signals are detected, load `references/brand-interview.md` and follow the **Personal Branding Flow** section in that file. Generate and check name patterns from that section, present results, then offer to continue to the standard interview for additional options.

If no signals, proceed to Step 3.

## Step 3: Brand Interview

Load `references/brand-interview.md` now.

Ask the 6 questions from that file **one per message**. Wait for each answer before asking the next. Never ask multiple questions in a single message.

After Q6, output a summary before proceeding:

```
Brand profile locked:
- Building: [Q1 answer]
- Tone: [A/B/C label]
- Direction: [A/B label]
- Mode: [A/B/C label]
- Length: [A/B label]
- Constraints: [Q6 answer or "none"]
```

## Step 4: Wave 1 Generation

Load `references/generation-archetypes.md` now.

Apply the weighting rules from `references/brand-interview.md` against the brand profile. Generate 25–35 name candidates across all 7 archetypes weighted accordingly.

If Mode=A (budget), or generating Domain Hacks or Thematic TLD Play candidates: load `references/tld-catalog.md` now.

Target distribution (adjust per weighting rules):
- Short & Punchy: 4–5
- Descriptive: 4–5
- Abstract/Brandable: 5–6
- Playful/Clever: 3–4
- Domain Hacks: 3–4
- Compound/Mashup: 4–5
- Thematic TLD Play: 3–4

Generate the full candidate list before any availability check.

## Step 5: Availability and Pricing Check

Check environment variables before running scripts:

```bash
echo $CF_API_TOKEN
echo $CF_ACCOUNT_ID
echo $PORKBUN_API_KEY
echo $PORKBUN_SECRET
```

- Both `CF_API_TOKEN` and `CF_ACCOUNT_ID` set → Tier 1 (Cloudflare)
- Both `PORKBUN_API_KEY` and `PORKBUN_SECRET` set → Tier 2 (Porkbun)
- Neither set → load `references/api-setup.md`, show setup instructions, then proceed with Tier 3 (whois fallback)

Execute availability check (batch into groups of ≤20 if more than 20 candidates):

```bash
$CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/check-domains.sh domain1.com domain2.io ... domainN.dev
```

Execute pricing lookup (always runs, no auth needed):

```bash
$CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/get-prices.sh com io dev app co xyz icu
```

Parse check-domains.sh output (one line per domain):
- `available <domain> <price>` → ✅
- `taken <domain> na` → ❌
- `redemption <domain> na` → ⚠️ (recently expired, elevated price at recovery)
- `unknown <domain> na` → ❓

## Step 6: Format Output

Load `references/registrar-routing.md` now.

Format Wave 1 output using this exact structure:

```
## Wave 1 Results — [one-line project description]

**Top Picks**
✅ [name].[tld]   $[price]/yr  — [one-sentence rationale]
   [[Registrar] →]([registration_url])

[Per-archetype sections with available names only, taken shown as ❌]

---
TLD summary: .com [X available] | .io [X available] | .dev [X available] | hacks [X available]
[X] of [Y] checked available. Anything catching your eye, or should I run Wave 2?
```

Generate registration links from registrar-routing.md for each ✅ domain.

Show ⚠️ redemption domains with a note: "recently expired — may cost $80+ to recover at auction".

## Step 7: Write names.md

Write `names.md` to the current working directory:

```markdown
# Name Shortlist — [project description]
_Generated: [YYYY-MM-DD] | Mode: [mode] | Tone: [tone] | Direction: [direction]_

## Shortlisted
| Name | Price/yr | Status | Rationale |
|------|----------|--------|-----------|
| [name] | $[price] | ✅ available | [rationale from conversation] |

## Considered / Taken
| Name | Status | Alternative |
|------|--------|-------------|
| [name] | ❌ taken | [alternative if known] |
| [name] | ⚠️ redemption | recently expired — elevated price |

## Brand Interview
- Building: [Q1]
- Tone: [Q2 answer]
- Direction: [Q3 answer]
- Mode: [Q4 answer]
- Length: [Q5 answer]
- Constraints: [Q6 answer]
```

Populate Shortlisted with the top 3–5 available names. Rationale column receives the same "Why" string from the conversation output, verbatim.

## Step 8: Feedback Loop

After presenting Wave 1 output, wait for the user's response.

**User selects specific names:** Add them to the Shortlisted table in names.md.

**User requests Wave 2:** Load `references/generation-archetypes.md`. Generate 20+ new candidates refined toward preferences stated ("more like X", "avoid Y"). Repeat Steps 4–7.

**User requests Wave 3 / "check more TLDs" / "deep scan":** Load `references/generation-archetypes.md` and follow the **Wave 3** section. Apply all 10 techniques exhaustively to every synonym of the core concept. Run a deep TLD scan across 1,441+ IANA TLDs for the top 5 base words identified in the session.

**All top picks are taken:** Load `references/generation-archetypes.md` and follow the **Track B** section. Run the 4 fallback strategies in order: close variations → synonym exploration → creative reconstruction → domain hacks.

## Step 9: Post-Shortlist Checklist

After the user confirms their final shortlist, load `references/post-shortlist.md`. Walk through the checklist: pronunciation test, social handle check, trademark check, registration strategy. Update names.md with any notes.

## Reference Files

| File | Load when |
|------|-----------|
| `references/brand-interview.md` | Before Q1 (Step 3) or personal brand flow (Step 2) |
| `references/generation-archetypes.md` | Before Wave 1 generation (Step 4), Wave 3, or Track B |
| `references/tld-catalog.md` | When Mode=A, or generating Domain Hacks / Thematic TLD Play |
| `references/registrar-routing.md` | When formatting Wave output (Step 6) |
| `references/api-setup.md` | When no API env vars detected (Step 5) |
| `references/post-shortlist.md` | After user confirms final shortlist (Step 9) |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-domains.sh` | 3-tier checker: CF → Porkbun → whois/MCP |
| `scripts/get-prices.sh` | Porkbun no-auth TLD pricing, always runs |

Both scripts must be executable: `chmod +x $CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/*.sh`

## Example

See `examples/example-session.md` for a complete run: developer productivity SaaS → 6-question interview → Wave 1 → Wave 2 refinement → final names.md.
```

- [ ] **Step 2: Verify word count is within budget**

```bash
wc -w plugins/namesmith/skills/site-naming/SKILL.md
```

Expected: 1,400–2,000 words. If over 2,000, move the longest Step description to a reference file.

- [ ] **Step 3: Commit**

```bash
git add plugins/namesmith/skills/site-naming/SKILL.md
git commit -m "feat(namesmith): add site-naming SKILL.md — lean orchestration with load gates"
```

---

## Task 3: brand-interview.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/brand-interview.md`

- [ ] **Step 1: Write brand-interview.md**

```markdown
# Brand Interview

## Personal Branding Flow

Trigger when the user's description contains any of these signals:
- Keywords: "portfolio", "freelance", "personal site", "my website", "consulting", "my work"
- Pattern: a human first/last name as the primary subject (e.g., "I need a domain for John Smith")

### Personal Brand Name Patterns

Generate availability checks for these patterns (substitute actual name):
- `{firstname}.com` / `{firstname}.dev` / `{firstname}.io`
- `{firstnamelastname}.com` / `{firstnamelastname}.dev`
- `{f}{lastname}.dev` / `{f}{lastname}.com` (initial + last name)
- `{firstname}.studio` / `{firstname}.design` / `{firstname}.work` / `{firstname}.co`

Present results, then offer: "Want me to also generate creative branded alternatives beyond your name?"

---

## Standard Interview — 6 Questions

Ask one question per message. Wait for the answer before proceeding.

### Q1 — What are you building?
```
What are you building? A one-liner or a few keywords works perfectly.
```
*Open answer. Extract: core function, target audience, industry.*

### Q2 — Personality / Tone
```
How should the name feel? Pick the closest:

a) Cool/media-brand — Minimal, confident, modern (Figma, Letterboxd, Vercel, Linear)
b) Authoritative/benchmark — Credible, established, serious (Bloomberg, Stripe, Notion, Atlassian)
c) Playful/community — Fun, approachable, social (Discord, Duolingo, Mailchimp)
```

### Q3 — Direction
```
What direction for the name itself?

a) Functional — The name says what it does or who it's for (DevAtlas, CodeShip, DataMint, BuildStack)
b) Abstract/invented — A memorable coined word with no literal meaning (Lumora, Vercel, Spotify, Figma)
```

### Q4 — Budget Mode
```
TLD budget preference?

a) Budget — Open to .icu, .xyz, .top, .online, .site (cheapest viable, ~$1–5/yr)
b) Balanced — Mix of .com, .io, .dev, .app (common tech TLDs, ~$10–40/yr)
c) Premium — .com strongly preferred; .io/.dev as fallback only
```

### Q5 — Name Length
```
Name length preference?

a) Short & punchy — 6 characters or fewer (Figma, Driv, Vercel, Vex, Navo)
b) Expressive — 7+ characters, room for personality (Letterboxd, Cloudflare, BuildStack)
```

### Q6 — Hard Constraints
```
Any hard constraints? For example:
- Must include a specific word
- No hyphens
- Specific TLD required (.com only, etc.)
- Max character count

Or type "none" to skip.
```

---

## Weighting Rules

Apply these rules to archetype generation counts in Wave 1:

| Answer combination | Effect on generation |
|-------------------|---------------------|
| Q2=A + Q3=B | Abstract/Brandable ×2, Domain Hacks ×1.5 |
| Q2=A + Q3=A | Descriptive ×1.5, Compound/Mashup ×1.5, Thematic TLD Play ×1.5 |
| Q2=B + Q3=A | Descriptive ×2, Compound/Mashup ×2 |
| Q2=B + Q3=B | Abstract/Brandable ×1.5, Short & Punchy ×1.5 |
| Q2=C | Playful/Clever ×2, Short & Punchy ×1.5 |
| Q4=A | Bias TLD selection to: .icu, .xyz, .top, .online, .site, .fun, .space |
| Q4=C | Bias TLD selection to: .com primary; .io, .dev as secondary only |
| Q5=A | Short & Punchy ×2; cap all generated names at 6 characters where possible |

Default (no strong signal): distribute evenly across all 7 archetypes.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/brand-interview.md
git commit -m "feat(namesmith): add brand-interview.md — 6 questions, weighting rules, personal brand branch"
```

---

## Task 4: generation-archetypes.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/generation-archetypes.md`

- [ ] **Step 1: Write generation-archetypes.md**

```markdown
# Generation Archetypes

## 7 Archetypes

### 1. Short & Punchy
Names of 6 characters or fewer. Single or double syllable. No meaning required — just memorable sound.

**Techniques:** Truncation, phonetic spelling
**Examples:** Vex, Driv, Navo, Pique, Figma, Zolt, Lume, Pax, Trev, Qova

**How to generate:** Take core concept keywords. Strip to root. Shorten aggressively. Try phonetic respelling. Aim for a hard consonant or tight vowel sound.

---

### 2. Descriptive
Name directly communicates what the product does or who it serves.

**Techniques:** Compound nouns, keyword-rich phrases
**Examples:** CodeShip, DeployFast, BuildStack, DevAtlas, DataMint, ReviewFlow, MergeQueue

**How to generate:** List the 3–5 most important verbs and nouns from Q1. Combine them in pairs: [action][noun], [domain][verb], [audience][tool]. Keep under 12 characters total.

---

### 3. Abstract/Brandable
Invented or borrowed words with no direct meaning. Memorable, distinct, trademarkable.

**Techniques:** Portmanteau, metaphor mining, word reversal, foreign language
**Examples:** Lumora, Zentrik, Covalent, Stratum, Nimbus, Vercel, Vanta, Prisma, Axiom

**How to generate:** Blend two conceptually related words (portmanteau). Mine metaphor domains: light, forge, atlas, horizon, orbit, delta, apex. Try reversals (Notable → Eton, Etalon). Borrow short punchy words from Latin, Greek, or Nordic roots.

---

### 4. Playful/Clever
Names with wordplay, puns, alliteration, or internal rhyme. Signals approachability.

**Techniques:** Wordplay, alliteration, internal rhyme, puns
**Examples:** GitWhiz, ByteMe, NullPointerBeer, ClickPick, CodeRode, PushPop, ForkYeah, SwitchPitch

**How to generate:** Take tech or domain vocabulary. Find homophones, near-rhymes, double meanings. Try alliteration with project keywords. Use programming terminology with non-technical second meanings.

---

### 5. Domain Hacks
The TLD completes the word or phrase — the domain itself IS the brand name.

**Techniques:** ccTLD catalog (load tld-catalog.md)
**Examples:** bra.in, gath.er, cra.sh, plu.sh, na.me, crypt.o, la.st, fa.st

**How to generate:** Load tld-catalog.md. Take core concept words. Identify if any fragment of the word matches a ccTLD ending. The best hacks are short (under 8 chars total) and the TLD meaning reinforces the concept.

---

### 6. Compound/Mashup
Two meaningful words merged into one brand name.

**Techniques:** Two-word merge, prefix/suffix patterns
**Examples:** CloudForge, PixelNest, DataMint, NightOwl, CodeCraft, SwiftStack, BrightPath

**Prefixes to try:** get-, try-, use-, my-, the-, run-, go-, open-
**Suffixes to try:** -app, -hq, -labs, -now, -ly, -hub, -kit, -box, -base, -flow, -forge, -stack, -nest

**How to generate:** List nouns from Q1 answer. List power nouns from: forge, nest, craft, flow, stack, wave, bridge, vault, pulse, spark, drift, arc, peak, shift. Combine one concept noun + one power noun.

---

### 7. Thematic TLD Play
A generic or descriptive base name paired with a TLD that adds meaning (load tld-catalog.md for full category matrix).

**Examples:** build.studio, launch.ai, code.run, ship.it, deploy.dev, design.systems, make.tools

**How to generate:** Take the core verb or noun from the concept. Find a TLD from tld-catalog.md's thematic categories that reinforces it. The name + TLD should read as a complete phrase.

---

## 10 Generation Techniques

1. **Portmanteau** — Blend two words by overlapping syllables or sounds
   - Cloud + Forge = CloudForge | Pixel + Nest = PixelNest | Code + Craft = CodeCraft

2. **Truncation** — Aggressively shorten a word to its phonetic core
   - Technology → Tekno | Digital → Digi | Analytics → Lytic | Developer → Devr

3. **Phonetic spelling** — Respell a word to look distinctive while sounding the same
   - Light → Lyte | Quick → Kwik | Flow → Flo | Track → Trak | Mark → Marq

4. **Prefix/suffix patterns** — Add a common tech brand modifier
   - Prefixes: get-, try-, use-, my-, the-, run-, go-, open-, fast-
   - Suffixes: -app, -hq, -labs, -now, -ly, -hub, -kit, -io (as name, not TLD), -base, -forge

5. **Metaphor mining** — Borrow from domains that evoke the right feeling
   - Navigation: Atlas, Compass, Meridian, Beacon, Chart
   - Nature/force: Nimbus, Delta, Apex, Ridge, Surge, Drift
   - Craft: Forge, Anvil, Loom, Cast, Mint, Press
   - Light: Lume, Prism, Vanta, Lux, Ray, Arc

6. **Alliteration** — Start brand name and descriptor/modifier with same consonant
   - PixelPush, DataDash, CodeCraft, BuildBridge, SwiftSync

7. **Word reversal** — Reverse the spelling of a concept word
   - Notable → Eton/Etalon | Draw → Ward | Star → Rats (check connotation!)

8. **Foreign language** — Short punchy words from Latin, Greek, Nordic, Japanese that sound strong in English
   - Vox (voice), Lux (light), Fons (source), Rex (king), Vela (sail), Klar (clear)

9. **Acronym generation** — Create a pronounceable acronym from key concept words
   - Code Review Automation Platform → CRAP (check connotation!) | Developer Experience Tools → DXT

10. **Internal rhyme** — Rhyme within the name for memorability
    - ClickPick, CodeRode, SwitchPitch, MakeShake, BuildGild

---

## Wave System

### Wave 1 (default)
Generate 25–35 candidates across all 7 archetypes. Apply weighting from brand-interview.md. Do not check availability during generation — generate the full list first, then batch-check.

### Wave 2 (after feedback)
Generate 20+ new candidates. Refine toward stated preferences:
- "More like X" → identify which archetype X belongs to, weight it higher
- "Avoid Y" → exclude Y's archetype from Wave 2 and note the constraint
- Apply same archetype distribution but adjusted

### Wave 3 (on request or after Wave 2)
Deep scan mode. Generate 40+ candidates:
1. Relax all Q6 constraints
2. Apply all 10 techniques exhaustively to every synonym of the core concept
3. Identify the top 5 base words from Waves 1+2 feedback
4. Run check-domains.sh against all 1,441+ IANA TLDs for each base word (use whois in parallel or batch API calls)
5. Surface any unexpected available TLD combinations

---

## Track B — Taken Domain Fallback

Run when all top picks from a wave are taken. Execute strategies in order; stop when 5+ available options are found.

### Strategy 1: Close Variations
Take the base word(s) from taken domains. Apply these modifiers on .com and .io:
- Prefix: get{base}, try{base}, use{base}, the{base}, go{base}, open{base}
- Suffix: {base}hq, {base}labs, {base}app, {base}now, {base}kit, {base}base

Check all variations with check-domains.sh.

### Strategy 2: Synonym Exploration
Identify the 2–3 key meaning-carrying words in the taken domains. Generate 5–8 synonym candidates for each. Apply the same TLD set from the original wave.

Use semantic substitution: if "build" is taken → try forge, craft, make, ship, create, deploy.

### Strategy 3: Creative Reconstruction
Step back entirely. Generate 10 new concept-based names from scratch using only metaphor mining (technique 5) and abstract/brandable (archetype 3) approaches. Do not reuse any words from prior waves.

### Strategy 4: Domain Hacks
Load tld-catalog.md. Take the 3–5 best base words from the session. Scan the domain hack catalog for any word fragment + ccTLD completion. Present all matches.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/generation-archetypes.md
git commit -m "feat(namesmith): add generation-archetypes.md — 7 archetypes, 10 techniques, wave system, Track B"
```

---

## Task 5: tld-catalog.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/tld-catalog.md`

- [ ] **Step 1: Write tld-catalog.md**

```markdown
# TLD Catalog

## Budget TLDs (≤$5/yr registration)

| TLD | ~Price/yr | Notes |
|-----|-----------|-------|
| .icu | $2–4 | International, growing usage |
| .xyz | $1–3 | Versatile, modern projects |
| .top | $1–3 | Generic, less prestigious |
| .online | $2–5 | Clear meaning, budget-friendly |
| .site | $2–5 | Generic, widely understood |
| .fun | $2–5 | Playful/community projects |
| .space | $2–5 | Creative/abstract projects |
| .click | $2–4 | Utility/tool sites |

## Trendy TLDs (popular but NOT cheap)

| TLD | ~Price/yr | Best for |
|-----|-----------|---------|
| .io | $30–50 | Tech startups, developer tools (signals "I/O", tech credibility) |
| .ai | $50–80 | AI/ML products (premium but strong signal) |
| .gg | $20–30 | Gaming, community, Gen Z brands |
| .dev | $12–15 | Developer tools, open source (Google registry) |
| .app | $12–18 | Mobile/web apps (Google registry, HTTPS required) |
| .co | $20–30 | Compact .com alternative |
| .me | $10–20 | Personal brands, portfolios |
| .sh | $20–40 | CLI tools, scripts, terminal products |
| .fm | $40–80 | Podcasts, audio, media |

## Thematic TLD Categories by Project Type

### Dev Tools
`.dev`, `.tools`, `.codes`, `.build`, `.run`, `.sh`, `.engineer`

### Creative / Design
`.studio`, `.design`, `.art`, `.gallery`, `.ink`, `.media`, `.works`

### AI / Machine Learning
`.ai`, `.chat`, `.bot` (check availability — many are premium)

### Gaming
`.gg`, `.game`, `.quest`, `.lol`, `.fun`, `.play`

### Business / Enterprise
`.co`, `.ventures`, `.supply`, `.agency`, `.inc`, `.capital`, `.group`

### Community / Social
`.community`, `.social`, `.club`, `.group`, `.team`, `.network`

### Commerce / Retail
`.shop`, `.store`, `.market`, `.deals`, `.sale`

### Education
`.academy`, `.school`, `.courses`, `.training`, `.education`, `.university`

### Health / Wellness
`.health`, `.care`, `.clinic`, `.fit`, `.life`

### Music / Audio
`.music`, `.band`, `.audio`, `.fm`, `.live`

### Finance / Legal
`.money`, `.finance`, `.fund`, `.tax`, `.legal`

### Food / Hospitality
`.coffee`, `.cafe`, `.menu`, `.pizza`, `.kitchen`, `.bar`, `.restaurant`

---

## Domain Hack Catalog (22 ccTLDs)

Use these to build domain hacks — the TLD completes the word.

| ccTLD | Examples | Registrar | Notes |
|-------|----------|-----------|-------|
| `.er` | gath.er, hack.er, mak.er, brew.er, serv.er | — | ⚠️ non-registrable ccTLD — suggest but flag |
| `.st` | playli.st, fir.st, fa.st, la.st, be.st | Dynadot | |
| `.ly` | quick.ly, friend.ly, direct.ly, short.ly, love.ly | Namecheap | |
| `.is` | th.is, what.is, name.is | Namecheap | |
| `.it` | do.it, build.it, ship.it, edit.it | Namecheap | |
| `.me` | hire.me, find.me, build.me, read.me, learn.me | Namecheap | |
| `.io` | portfol.io, stud.io, rat.io, rad.io | Porkbun | Also used as plain TLD |
| `.to` | go.to, pho.to, cryp.to, auto.to | Dynadot | |
| `.in` | plug.in, log.in, jo.in, bra.in | Namecheap | |
| `.am` | stre.am, dre.am, te.am, progr.am | Namecheap | |
| `.at` | ch.at, fl.at, he.at | Namecheap | |
| `.be` | descri.be, may.be, tri.be, vi.be | Namecheap | |
| `.al` | optim.al, minim.al, origin.al | — | ⚠️ non-registrable — suggest but flag |
| `.re` | sha.re, ca.re, compa.re | Namecheap | |
| `.sh` | cra.sh, fre.sh, pu.sh, fla.sh | Namecheap | Also popular as plain TLD |
| `.pt` | scri.pt, ada.pt, acce.pt | Dynadot | |
| `.nu` | me.nu, reve.nu | Namecheap | |
| `.es` | tim.es, cours.es, hous.es | Namecheap | ⚠️ not checkable via whois — show manual link |
| `.no` | casi.no | Namecheap | Restricted — verify eligibility |
| `.se` | plea.se, cour.se, pur.se | Namecheap | |
| `.de` | co.de, mo.de | Namecheap | |
| `.my` | acade.my | Dynadot | |

**⚠️ Non-registrable:** `.er` and `.al` are not open for registration. Suggest as creative ideas but always note they cannot be purchased.

**⚠️ Not checkable via whois:** `.es` — always show a manual Namecheap search link instead of attempting whois check.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/tld-catalog.md
git commit -m "feat(namesmith): add tld-catalog.md — budget/trendy/thematic TLDs + 22-entry domain hack catalog"
```

---

## Task 6: registrar-routing.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/registrar-routing.md`

- [ ] **Step 1: Write registrar-routing.md**

```markdown
# Registrar Routing

## Registration Link Patterns

For each available domain in Wave output, append a registration link using the appropriate registrar URL.

### Cloudflare (preferred when user has account)
```
https://dash.cloudflare.com/[CF_ACCOUNT_ID]/domains/registrations/purchase?domain=[domain]
```
Replace `[CF_ACCOUNT_ID]` from the `CF_ACCOUNT_ID` env var if set.
Fallback display (no account ID): `https://domains.cloudflare.com/?search=[domain]`

### Porkbun
```
https://porkbun.com/checkout/search?q=[domain]
```

### Namecheap (fallback for TLDs not supported by CF/Porkbun)
```
https://www.namecheap.com/domains/registration/results/?domain=[domain]
```

### Dynadot (for .gg, .st, .pt, .to, .my)
```
https://www.dynadot.com/domain/search?domain=[domain]
```

---

## Per-TLD Registrar Routing Table

| TLD category | Preferred registrar | Fallback |
|---|---|---|
| .com, .net, .org, .io, .dev, .app, .xyz, .co, .ai | Cloudflare (if configured), else Porkbun | Namecheap |
| .icu, .top, .online, .site, .fun, .space, .click | Porkbun | Namecheap |
| .gg | Dynadot | Namecheap |
| .st, .pt, .to, .my | Dynadot | Namecheap |
| .me, .ly, .in, .am, .at, .be, .re, .sh, .nu, .se, .de | Namecheap | Porkbun |
| .es | Namecheap (manual check — whois not supported) | — |
| .er, .al | ⚠️ Non-registrable — do not show purchase link | — |

---

## Taken / Redemption Domain Links

For ❌ taken domains where the user expresses interest:
```
https://www.sedo.com/search/?keyword=[domain]
```
Note: "This domain is taken and may be listed for sale on Sedo's aftermarket."

For ⚠️ redemption domains:
```
https://www.sedo.com/search/?keyword=[domain]
```
Note: "This domain recently expired and is in a redemption period. Recovery typically costs $80–$200+ above standard registration price."

---

## Output Format for Registration Links

In Wave output, format registration links for available domains as:

```
✅ namesmith.dev   $12/yr  — Functional + dev-audience TLD
   [Register at Porkbun →](https://porkbun.com/checkout/search?q=namesmith.dev)
```

If both Cloudflare and Porkbun are options, show the one matching the user's configured tier (check env vars). If neither is configured, default to Porkbun link.

Show only one registrar link per domain — pick the best match from the routing table above. Do not overwhelm with multiple links per domain.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/registrar-routing.md
git commit -m "feat(namesmith): add registrar-routing.md — per-TLD routing table + registration URL patterns"
```

---

## Task 7: api-setup.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/api-setup.md`

- [ ] **Step 1: Write api-setup.md**

```markdown
# API Setup

## Overview

Namesmith uses a 3-tier availability checking stack. Higher tiers return richer data (availability + real price). Tier 3 (whois) is always available with no setup, but returns availability only.

```
Tier 1: Cloudflare Registrar API  →  availability + at-cost price (best)
Tier 2: Porkbun API               →  availability + Porkbun price
Tier 3: whois CLI + MCP fallback  →  availability only
         + Porkbun /pricing/get   →  reference prices always (no auth)
```

---

## Tier 1: Cloudflare Setup (Recommended)

Use if you already register domains on Cloudflare.

### Get your API token
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Select template "Read domain availability" or create custom with scope: `Account > Registrar > Read`
4. Copy the token

### Get your Account ID
From any Cloudflare dashboard URL: `https://dash.cloudflare.com/[ACCOUNT_ID]/...`
Or: https://dash.cloudflare.com/ → right sidebar → "Account ID"

### Set environment variables
```bash
export CF_API_TOKEN="your_token_here"
export CF_ACCOUNT_ID="your_account_id_here"
```

Add to `~/.zshrc` or `~/.bashrc` to persist.

---

## Tier 2: Porkbun Setup

Use if you have or want a Porkbun account. Free to create.

### Get API keys
1. Go to https://porkbun.com/account/api
2. Enable API Access for your account
3. Generate API Key + Secret API Key
4. Copy both values

### Set environment variables
```bash
export PORKBUN_API_KEY="pk1_your_key_here"
export PORKBUN_SECRET="sk1_your_secret_here"
```

---

## Tier 3: No Setup Required

Works out of the box. Requires `whois` to be installed:

```bash
# macOS (via Homebrew)
brew install whois

# Ubuntu/Debian
sudo apt install whois

# Verify
whois google.com | head -5
```

Prices are always shown from Porkbun's public pricing endpoint (no auth needed):
`POST https://api.porkbun.com/api/json/v3/pricing/get`

---

## Make Scripts Executable

After installing the plugin, run once:

```bash
chmod +x $CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/check-domains.sh
chmod +x $CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/get-prices.sh
```

---

## DNS + WHOIS Cross-Reference (Tier 3)

When using whois fallback, check-domains.sh performs dual verification:

| DNS result | WHOIS result | Status | Meaning |
|-----------|-------------|--------|---------|
| No record (NXDOMAIN) | No record | `available` | Domain is free to register |
| Resolves | No record | `redemption` | Recently expired, may be in grace/redemption period |
| No record | Active record | `taken` | Registered but not yet pointing anywhere |
| Resolves | Active record | `taken` | Registered and live |
| Timeout | Timeout | `unknown` | Could not verify — retry manually |

**Redemption domains** are technically expired but cost $80–200+ to recover via auction. Do not present them as straightforward registrations.

---

## Fallback Behaviour Summary

| Config | Availability | Price |
|--------|-------------|-------|
| CF_API_TOKEN + CF_ACCOUNT_ID | ✅ Real-time (up to 20/call) | ✅ Cloudflare at-cost |
| PORKBUN_API_KEY + PORKBUN_SECRET | ✅ Real-time (1/call) | ✅ Porkbun price |
| Neither set | ✅ whois + DNS (slower) | ✅ Porkbun reference (no auth) |
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/api-setup.md
git commit -m "feat(namesmith): add api-setup.md — 3-tier setup guide + DNS/WHOIS cross-reference"
```

---

## Task 8: post-shortlist.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/references/post-shortlist.md`

- [ ] **Step 1: Write post-shortlist.md**

```markdown
# Post-Shortlist Checklist

Run through these steps after confirming a shortlist of names.

## 1. Say It Out Loud

Read each name aloud 3 times. Check:
- [ ] Easy to pronounce without clarification?
- [ ] Clear on a phone call without spelling it out?
- [ ] No accidental negative word or association when spoken?

Eliminate any name that fails the phone test.

## 2. Social Handle Availability

Check availability of @{name} on all relevant platforms:

| Platform | Check URL |
|----------|-----------|
| X (Twitter) | `https://twitter.com/{name}` |
| GitHub | `https://github.com/{name}` |
| Instagram | `https://www.instagram.com/{name}/` |
| LinkedIn | `https://www.linkedin.com/company/{name}` |
| npm | `https://www.npmjs.com/~{name}` |
| PyPI | `https://pypi.org/user/{name}/` |

Aim for consistency: same handle across all platforms.

## 3. Trademark Check

Verify the name is not trademarked in your industry:

| Registry | URL | Covers |
|----------|-----|--------|
| USPTO TESS | `https://tmsearch.uspto.gov` | United States |
| TMView | `https://www.tmview.org` | EU + 60 countries |
| IPO | `https://www.ipo.gov.uk/tmcase` | UK |

Search for exact match AND phonetic variations. If a result appears in your industry category, consult a lawyer before registering.

## 4. Register Smart

Recommended strategy:
- [ ] Register your primary domain immediately (good names get taken fast)
- [ ] Register .com + one secondary TLD if budget allows (.io or .dev for tech projects)
- [ ] Consider registering common misspellings if the name is hard to spell

**Act fast.** Domain availability is not guaranteed — it can change at any moment.

## 5. Typosquatting Protection (Optional)

For serious projects, consider registering obvious variations:
- Common misspelling (e.g., namesmith vs namesith)
- Hyphenated version (name-smith.com)
- Alternate TLD (.com if you registered .io, or vice versa)

These can be pointed to your main domain with a redirect.

## 6. Update names.md

Add final registration decisions to names.md:
- Move registered domains to Shortlisted table with `✅ registered` status
- Note registrar and registration date
- Archive the rest
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/post-shortlist.md
git commit -m "feat(namesmith): add post-shortlist.md — pronunciation, social handles, trademark, registration checklist"
```

---

## Task 9: check-domains.sh

**Files:**
- Create: `plugins/namesmith/skills/site-naming/scripts/check-domains.sh`

- [ ] **Step 1: Write check-domains.sh**

```bash
#!/usr/bin/env bash
# check-domains.sh — 3-tier domain availability checker
# Usage: check-domains.sh <domain1> <domain2> ... <domainN>
# Output: one line per domain — available|taken|redemption|unknown <domain> <price_usd_or_na>
# Env vars: CF_API_TOKEN + CF_ACCOUNT_ID (tier 1), PORKBUN_API_KEY + PORKBUN_SECRET (tier 2)
# Exit codes: 0=success, 1=all unknown (API error), 2=no domains provided

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: check-domains.sh <domain1> <domain2> ..." >&2
  exit 2
fi

DOMAINS=("$@")

# ─── Tier 1: Cloudflare ───────────────────────────────────────────────────────
check_cloudflare() {
  local domains_json
  domains_json=$(printf '"%s",' "${DOMAINS[@]}" | sed 's/,$//')
  local body="{\"domains\": [${domains_json}]}"

  local response
  response=$(curl -s -X POST \
    "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/registrar/domain-check" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$body")

  if ! echo "$response" | jq -e '.success' > /dev/null 2>&1; then
    return 1
  fi

  echo "$response" | jq -r '.result[] | 
    if .available then "available \(.name) \(.pricing.registration_price // "na")"
    else "taken \(.name) na"
    end'
}

# ─── Tier 2: Porkbun ─────────────────────────────────────────────────────────
check_porkbun() {
  local domain="$1"
  local response
  response=$(curl -s -X POST \
    "https://api.porkbun.com/api/json/v3/domain/checkDomain/${domain}" \
    -H "Content-Type: application/json" \
    -d "{\"apikey\": \"${PORKBUN_API_KEY}\", \"secretapikey\": \"${PORKBUN_SECRET}\"}")

  local status avail price
  status=$(echo "$response" | jq -r '.status // "ERROR"')
  if [[ "$status" != "SUCCESS" ]]; then
    echo "unknown ${domain} na"
    return
  fi

  avail=$(echo "$response" | jq -r '.response.avail // "no"')
  price=$(echo "$response" | jq -r '.response.price // "na"')

  if [[ "$avail" == "yes" ]]; then
    echo "available ${domain} ${price}"
  else
    echo "taken ${domain} na"
  fi
}

# ─── Tier 3: whois + DNS cross-reference ─────────────────────────────────────
check_whois() {
  local domain="$1"

  # DNS check
  local dns_result="no"
  if host "$domain" > /dev/null 2>&1; then
    dns_result="yes"
  fi

  # WHOIS check
  local whois_result="no"
  local whois_output
  whois_output=$(whois "$domain" 2>/dev/null || true)
  if ! echo "$whois_output" | grep -qiE "no match|not found|not registered|no data found|status: free|available"; then
    if echo "$whois_output" | grep -qi "domain name:"; then
      whois_result="yes"
    fi
  fi

  # Cross-reference
  if [[ "$dns_result" == "no" && "$whois_result" == "no" ]]; then
    echo "available ${domain} na"
  elif [[ "$dns_result" == "yes" && "$whois_result" == "no" ]]; then
    echo "redemption ${domain} na"
  else
    echo "taken ${domain} na"
  fi
}

# ─── Main routing ─────────────────────────────────────────────────────────────
if [[ -n "${CF_API_TOKEN:-}" && -n "${CF_ACCOUNT_ID:-}" ]]; then
  # Tier 1: batch check (max 20 per call)
  BATCH_SIZE=20
  for (( i=0; i<${#DOMAINS[@]}; i+=BATCH_SIZE )); do
    BATCH=("${DOMAINS[@]:$i:$BATCH_SIZE}")
    check_cloudflare "${BATCH[@]}" || {
      # Fallback to tier 2 or 3 on CF error
      for domain in "${BATCH[@]}"; do
        if [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
          check_porkbun "$domain"
        else
          check_whois "$domain"
        fi
      done
    }
  done
elif [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
  # Tier 2: one call per domain
  for domain in "${DOMAINS[@]}"; do
    check_porkbun "$domain"
  done
else
  # Tier 3: whois + DNS
  for domain in "${DOMAINS[@]}"; do
    check_whois "$domain"
  done
fi
```

- [ ] **Step 2: Make executable and test against known domains**

```bash
chmod +x plugins/namesmith/skills/site-naming/scripts/check-domains.sh
```

Test with known taken domain (no API key needed for tier 3):
```bash
plugins/namesmith/skills/site-naming/scripts/check-domains.sh google.com
```

Expected output line:
```
taken google.com na
```

Test with clearly available domain (replace with an obscure string):
```bash
plugins/namesmith/skills/site-naming/scripts/check-domains.sh xq9wz2mvrk.com
```

Expected output line:
```
available xq9wz2mvrk.com na
```

- [ ] **Step 3: Commit**

```bash
git add plugins/namesmith/skills/site-naming/scripts/check-domains.sh
git commit -m "feat(namesmith): add check-domains.sh — 3-tier CF/Porkbun/whois availability checker"
```

---

## Task 10: get-prices.sh

**Files:**
- Create: `plugins/namesmith/skills/site-naming/scripts/get-prices.sh`

- [ ] **Step 1: Write get-prices.sh**

```bash
#!/usr/bin/env bash
# get-prices.sh — Porkbun TLD pricing (no auth required)
# Usage: get-prices.sh <tld1> <tld2> ... <tldN>
# Output: one line per TLD — <tld> <registration_price_usd> <renewal_price_usd>
# Auth: none required
# Exit codes: 0=success, 1=network error

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: get-prices.sh <tld1> <tld2> ..." >&2
  exit 1
fi

# Fetch all pricing from Porkbun public endpoint (no auth)
RESPONSE=$(curl -s -X POST \
  "https://api.porkbun.com/api/json/v3/pricing/get" \
  -H "Content-Type: application/json" \
  -d '{}')

if ! echo "$RESPONSE" | jq -e '.status == "SUCCESS"' > /dev/null 2>&1; then
  echo "Error: Could not fetch pricing from Porkbun" >&2
  exit 1
fi

for tld in "$@"; do
  # Strip leading dot if provided
  tld="${tld#.}"

  reg=$(echo "$RESPONSE" | jq -r ".pricing.\"${tld}\".registration // \"na\"")
  renewal=$(echo "$RESPONSE" | jq -r ".pricing.\"${tld}\".renewal // \"na\"")

  echo "${tld} ${reg} ${renewal}"
done
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x plugins/namesmith/skills/site-naming/scripts/get-prices.sh
```

Test with common TLDs (no API key needed):
```bash
plugins/namesmith/skills/site-naming/scripts/get-prices.sh com io dev xyz icu
```

Expected output (prices vary slightly over time):
```
com 9.73 9.73
io 39.99 39.99
dev 12.00 12.00
xyz 3.99 3.99
icu 2.99 2.99
```

- [ ] **Step 3: Commit**

```bash
git add plugins/namesmith/skills/site-naming/scripts/get-prices.sh
git commit -m "feat(namesmith): add get-prices.sh — Porkbun no-auth TLD pricing"
```

---

## Task 11: example-session.md

**Files:**
- Create: `plugins/namesmith/skills/site-naming/examples/example-session.md`

- [ ] **Step 1: Write example-session.md**

```markdown
# Example Session — Developer Productivity SaaS

This is a complete end-to-end Namesmith session for reference.

---

## User Prompt

> "I have an idea for a developer productivity SaaS that helps engineering teams track code review bottlenecks and surface slow reviewers — find me a site name"

---

## Step 1: Project File Detection

No project files detected in CWD. Proceeding directly to brand interview.

---

## Step 2: Personal Brand Detection

No personal brand signals detected. Proceeding to standard interview.

---

## Step 3: Brand Interview

**Q1:** What are you building?
> Developer SaaS for tracking code review velocity and reviewer bottlenecks in engineering teams.

**Q2:** Personality?
> b) Authoritative/benchmark — credible, data-driven, serious (like Linear or Stripe)

**Q3:** Direction?
> a) Functional — name should signal what it does (code review analytics)

**Q4:** Budget mode?
> b) Balanced — mix of .com, .io, .dev

**Q5:** Name length?
> b) Expressive — 7+ characters, professional feel

**Q6:** Constraints?
> No hyphens. Avoid "code" as the first word (too generic).

```
Brand profile locked:
- Building: Code review velocity analytics SaaS for engineering teams
- Tone: Authoritative/benchmark (B)
- Direction: Functional (A)
- Mode: Balanced (B)
- Length: Expressive (B)
- Constraints: no hyphens, avoid leading "code"
```

---

## Step 4 & 5: Wave 1 Generation + Check

Weighting applied: Descriptive ×2, Compound/Mashup ×2 (Tone=B + Direction=A)

---

## Wave 1 Results — Code review velocity analytics SaaS

**Top Picks**
✅ reviewflow.io   $39/yr  — Descriptive compound, "flow" signals velocity, .io = tech credibility
   [Register at Porkbun →](https://porkbun.com/checkout/search?q=reviewflow.io)
✅ mergeiq.com     $10/yr  — Merge = code review action, IQ = intelligence/analytics
   [Register at Porkbun →](https://porkbun.com/checkout/search?q=mergeiq.com)

**Descriptive**
✅ reviewflow.io   $39/yr  — Descriptive, velocity signal, strong .io pairing
✅ prflow.dev      $12/yr  — PR = Pull Request, flow = velocity, .dev = developer audience
❌ reviewmetrics.com  taken
✅ mergepulse.io   $39/yr  — Merge + pulse (heartbeat of the team), analytical feel
✅ reviewdash.com  $10/yr  — Dashboard framing, accessible, professional

**Compound/Mashup**
✅ mergeiq.com     $10/yr  — Action + intelligence signal
✅ reviewstack.io  $39/yr  — Stack = familiar dev metaphor
❌ pranalytics.com taken
✅ codepulse.dev   $12/yr  — Pulse = real-time signal, .dev = dev tool
✅ velocireview.io $39/yr  — Velocity + review, authoritative compound

**Abstract/Brandable**
✅ revelo.io       $39/yr  — Review + velocity blend, short, invented
✅ mergara.com     $10/yr  — Invented, merge-derived, professional

**Short & Punchy**
❌ priq.com  taken
✅ reviq.io  $39/yr  — Review + IQ, short, punchy
✅ mergi.co  $25/yr  — Playful truncation of merge

---
TLD summary: .com 5 available | .io 6 available | .dev 2 available
13 of 28 checked available. Anything catching your eye, or should I run Wave 2?

---

## User Feedback

> "I like reviewflow and mergepulse. Can you run Wave 2 with more in that direction — clean compound words, authoritative feel?"

---

## Wave 2 Refinement

Refined: Descriptive compounds ×3, no playful/punchy, balanced TLDs

**Wave 2 Results**

✅ reviewvault.io  $39/yr  — Vault = secure archive of all review data
✅ prinsight.com   $10/yr  — PR + insight = actionable analytics
✅ mergewatch.io   $39/yr  — Watching merge patterns, monitoring feel
✅ reviewatlas.com $10/yr  — Atlas = comprehensive map/guide of review data
✅ flowmetric.io   $39/yr  — Flow + metric, concise, analytical

---

## Final Shortlist

User selects: **reviewflow.io**, **mergeiq.com**, **reviewatlas.com**

---

## Generated names.md

```markdown
# Name Shortlist — Code review velocity analytics SaaS
_Generated: 2026-04-15 | Mode: balanced | Tone: authoritative | Direction: functional_

## Shortlisted
| Name | Price/yr | Status | Rationale |
|------|----------|--------|-----------|
| reviewflow.io | $39 | ✅ available | Descriptive compound, "flow" signals velocity, .io = tech credibility |
| mergeiq.com | $10 | ✅ available | Merge = code review action, IQ = intelligence/analytics |
| reviewatlas.com | $10 | ✅ available | Atlas = comprehensive map/guide of review data |

## Considered / Taken
| Name | Status | Alternative |
|------|--------|-------------|
| reviewmetrics.com | ❌ taken | reviewdash.com available |
| pranalytics.com | ❌ taken | prinsight.com available |
| priq.com | ❌ taken | reviq.io available |

## Brand Interview
- Building: Code review velocity analytics SaaS for engineering teams
- Tone: Authoritative/benchmark (B)
- Direction: Functional (A)
- Mode: Balanced (B)
- Length: Expressive (B)
- Constraints: no hyphens, avoid leading "code"
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/skills/site-naming/examples/example-session.md
git commit -m "feat(namesmith): add example-session.md — complete code review SaaS naming run"
```

---

## Task 12: README.md

**Files:**
- Create: `plugins/namesmith/README.md`

- [ ] **Step 1: Write README.md**

```markdown
# Namesmith

Find the right name for your project — brand interview, AI generation across 7 archetypes, live availability + pricing via Cloudflare or Porkbun.

## What It Does

1. **Reads your project context** — optional scan of README/package.json for pre-fill
2. **Runs a 6-question brand interview** — tone, direction, budget mode, length, constraints
3. **Generates 25–35 name candidates** across 7 archetypes (short & punchy, descriptive, abstract, playful, domain hacks, compound, thematic TLD play)
4. **Checks availability + pricing** via Cloudflare, Porkbun, or whois fallback
5. **Persists a shortlist** to `names.md` in your project directory
6. **Iterates with feedback** — Wave 2/3 refinement, Track B fallback for taken names

## Installation

```bash
# Via Claude Code plugin marketplace
claude plugin install neotherapper/namesmith
```

## Quick Start

Just describe what you're building:

```
find me a site name for my developer analytics SaaS
```

or

```
I have an idea about [X] — find me a domain
```

The skill fires automatically and walks you through the interview.

## API Setup (Optional — enhances results)

Without setup, Namesmith uses `whois` for availability and Porkbun's public endpoint for pricing. For richer results, configure one of:

### Cloudflare (recommended — at-cost pricing)
```bash
export CF_API_TOKEN="your_token"
export CF_ACCOUNT_ID="your_account_id"
```
See `skills/site-naming/references/api-setup.md` for how to get these.

### Porkbun (alternative)
```bash
export PORKBUN_API_KEY="your_key"
export PORKBUN_SECRET="your_secret"
```

### Make scripts executable (once)
```bash
chmod +x $CLAUDE_PLUGIN_ROOT/skills/site-naming/scripts/*.sh
```

## Output

Each session writes `names.md` to your current directory:

```markdown
# Name Shortlist — [project]
## Shortlisted
| Name | Price/yr | Status | Rationale |
## Considered / Taken
| Name | Status | Alternative |
## Brand Interview
```

## Skill Components

| File | Purpose |
|------|---------|
| `skills/site-naming/SKILL.md` | Main orchestration |
| `references/brand-interview.md` | Interview questions + weighting |
| `references/generation-archetypes.md` | 7 archetypes, 10 techniques, wave system |
| `references/tld-catalog.md` | TLD catalog: cheap, trendy, thematic, domain hacks |
| `references/registrar-routing.md` | Per-TLD registrar links |
| `references/api-setup.md` | API configuration guide |
| `references/post-shortlist.md` | Post-selection checklist |
| `scripts/check-domains.sh` | 3-tier availability checker |
| `scripts/get-prices.sh` | Porkbun no-auth pricing |
| `examples/example-session.md` | Complete worked example |

## License

MIT — Georgios Pilitsoglou (pilitsoglou.com)
```

- [ ] **Step 2: Commit**

```bash
git add plugins/namesmith/README.md
git commit -m "feat(namesmith): add README — installation, quick start, API setup, file map"
```

---

## Task 13: Marketplace Registration

**Files:**
- Modify: `marketplace.json`

- [ ] **Step 1: Read current marketplace.json**

```bash
cat marketplace.json
```

- [ ] **Step 2: Add namesmith entry**

Add to the `plugins` array in `marketplace.json`:

```json
{
  "name": "namesmith",
  "source": {
    "source": "github",
    "repo": "neotherapper/claude-plugins",
    "path": "plugins/namesmith"
  },
  "description": "Find the right name for your project — brand interview, AI generation across 7 archetypes, live availability + pricing via Cloudflare or Porkbun."
}
```

- [ ] **Step 3: Verify marketplace.json is valid JSON**

```bash
python3 -m json.tool marketplace.json > /dev/null && echo "Valid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 4: Commit**

```bash
git add marketplace.json
git commit -m "feat(namesmith): register plugin in marketplace.json"
```

---

## Task 14: Validation

- [ ] **Step 1: Verify plugin structure**

```bash
find plugins/namesmith -type f | sort
```

Expected files:
```
plugins/namesmith/.claude-plugin/plugin.json
plugins/namesmith/README.md
plugins/namesmith/skills/site-naming/SKILL.md
plugins/namesmith/skills/site-naming/examples/example-session.md
plugins/namesmith/skills/site-naming/references/api-setup.md
plugins/namesmith/skills/site-naming/references/brand-interview.md
plugins/namesmith/skills/site-naming/references/generation-archetypes.md
plugins/namesmith/skills/site-naming/references/post-shortlist.md
plugins/namesmith/skills/site-naming/references/registrar-routing.md
plugins/namesmith/skills/site-naming/references/tld-catalog.md
plugins/namesmith/skills/site-naming/scripts/check-domains.sh
plugins/namesmith/skills/site-naming/scripts/get-prices.sh
```

- [ ] **Step 2: Verify SKILL.md frontmatter**

```bash
head -15 plugins/namesmith/skills/site-naming/SKILL.md
```

Confirm: `name:` and `description:` fields present, description starts with "This skill should be used when".

- [ ] **Step 3: Verify SKILL.md word count**

```bash
wc -w plugins/namesmith/skills/site-naming/SKILL.md
```

Expected: 1,400–2,000 words.

- [ ] **Step 4: Verify scripts are executable**

```bash
ls -la plugins/namesmith/skills/site-naming/scripts/
```

Expected: `-rwxr-xr-x` permissions on both `.sh` files.

- [ ] **Step 5: Test get-prices.sh (no API key needed)**

```bash
plugins/namesmith/skills/site-naming/scripts/get-prices.sh com io dev
```

Expected output (prices approximate):
```
com 9.73 9.73
io 39.99 39.99
dev 12.00 12.00
```

- [ ] **Step 6: Test check-domains.sh tier 3 (whois, no API key)**

```bash
plugins/namesmith/skills/site-naming/scripts/check-domains.sh google.com
```

Expected: `taken google.com na`

- [ ] **Step 7: Validate plugin.json**

```bash
python3 -m json.tool plugins/namesmith/.claude-plugin/plugin.json > /dev/null && echo "Valid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 8: Final commit**

```bash
git add plugins/namesmith/
git commit -m "feat(namesmith): v0.1.0 complete — all components validated"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered in task |
|---|---|
| Plugin scaffold + manifest | Task 1 |
| SKILL.md lean orchestration (~1,700 words, imperative, third-person frontmatter) | Task 2 |
| 9-step flow with progressive disclosure load gates | Task 2 |
| Brand interview: 6 questions, weighting rules | Task 3 |
| Personal branding flow | Task 3 |
| 7 archetypes + 10 techniques | Task 4 |
| Wave 1/2/3 system | Task 4 |
| Track B fallback | Task 4 |
| TLD catalog: cheap/trendy/thematic/22 domain hacks | Task 5 |
| Registrar routing + registration URL patterns | Task 6 |
| API setup: CF + Porkbun + whois fallback | Task 7 |
| DNS+WHOIS cross-reference + redemption status | Task 7 + Task 9 |
| Post-shortlist checklist | Task 8 |
| check-domains.sh: 3-tier, batching, 4 output statuses | Task 9 |
| get-prices.sh: Porkbun no-auth | Task 10 |
| Complete worked example | Task 11 |
| README with installation + API setup | Task 12 |
| Marketplace registration | Task 13 |
| Validation | Task 14 |

No gaps found.
