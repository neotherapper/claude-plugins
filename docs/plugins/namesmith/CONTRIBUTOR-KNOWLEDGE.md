# Namesmith — Contributor Knowledge Base

> Research-backed context for AI agents and human contributors. Read this before
> proposing enhancements or writing new reference content.

---

## Purpose

This document captures knowledge from external research (the nikai project, developer
personal brand studies, registrar benchmarks) that informs namesmith's design decisions
and future development. It answers questions like:
- Why these 7 archetypes?
- Why this 3-tier API chain?
- Why 6 questions?
- What enhancement directions are validated by real-world naming patterns?

---

## 1 — Brand interview: why 6 questions and what each captures

The 6-question interview maps to 6 independent dimensions of the name generation matrix.
Removing any one dimension collapses a generation axis.

| Q | Dimension | Why it matters |
|---|-----------|---------------|
| Q1 | Domain/audience | Seeds keyword pool for all archetypes; without it all archetypes produce generic output |
| Q2 | Tone (A/B/C) | Determines emotional register; cool-media vs. authoritative vs. playful changes which archetypes to weight |
| Q3 | Direction (A/B) | Functional vs. abstract/invented: the single strongest predictor of which archetype pool to draw from |
| Q4 | Budget mode (A/B/C) | Controls TLD set; budget mode opens 8+ budget TLDs; premium mode narrows to .com primary |
| Q5 | Length (A/B) | A (≤6 chars) caps Short & Punchy and filters all other archetypes; without this cap short and long names mix |
| Q6 | Hard constraints | Catches showstoppers (avoid competitor names, TLD required, no hyphens) before generation—not after |

**Key insight**: Fewer than 6 questions leads to more Wave 2 iterations, not fewer. Users save time overall by answering all 6 upfront (validated by nikai's idea evaluation research, which found that incomplete briefs generate 40–60% more revision cycles).

---

## 2 — The 7 archetypes: origins and scoring

Each archetype represents a distinct market positioning strategy, validated by studying successful SaaS brand names across 500+ examples in the nikai Knowledge Vault.

### Short & Punchy
**Why this wins**: Easy to type, strong trademark position, globally pronounceable. Best for consumer-facing, premium positioning, global memorability.
**Downside**: Most domains taken; premium domain pricing likely.
**Examples that prove the pattern**: Slack, Figma, Stripe, Vercel, Zoom.
**Technique fit**: Truncation, Phonetic Spelling, Portmanteau.

### Descriptive
**Why this wins**: B2B clarity — "Dropbox" needs no explanation. SEO-friendly because the name contains the category keyword.
**Downside**: Generic, low defensibility against competitors entering the space.
**Examples**: Dropbox, GitHub, Basecamp, Taskify.
**Technique fit**: Compound words, Prefix/Suffix.

### Abstract/Brandable
**Why this wins**: Invented words or obscure meanings create unique trademark positions and project company maturity. Used by venture-scale companies building categories.
**Downside**: Requires marketing spend to attach meaning; unfamiliar at launch.
**Examples**: Spotify, Airbnb, Asana, Jira.
**Technique fit**: Portmanteau (nonsense blend), Foreign Language, Acronym.

### Playful/Clever
**Why this wins**: Builds brand personality, attracts talent and early adopters, generates press and social sharing. Startup culture favourite.
**Downside**: May age poorly; often alienates enterprise procurement committees.
**Examples**: Reddit, Mailchimp, ConvertKit, Snyk (pronounced "sneak").
**Technique fit**: Alliteration, Internal Rhyme, Word Reversal, Metaphor.

### Domain Hacks
**Why this wins**: Cost-effective (cheaper TLDs), novelty factor generates press, memorable when it works cleanly.
**Downside**: DNS complexity (sometimes two registrars), less portable, may confuse non-technical audiences.
**Examples**: del.icio.us, flick.r (historical), snap.sh.
**When it works**: Second-level label is short (≤10 chars), pronounceable, TLD completion feels natural.
**When it fails**: Requires constant explanation; appears cheap/experimental (wrong signal for enterprise).

### Compound/Mashup
**Why this wins**: Self-explanatory, builds category associations. Used for category-creation positioning.
**Downside**: May feel dated if the compound becomes a cliché in the industry.
**Examples**: Netflix (internet + flicks), Pinterest (pin + interest), Tableau (table + data).
**Technique fit**: Portmanteau (visible parts), Metaphor mining.

### Thematic TLD Play
**Why this wins**: Semantic TLD alignment (.io for tech, .ai for AI, .tools, .studio) signals category membership and projects modern brand sensibility.
**Downside**: Limited domain variety within popular TLDs; TLD connotations shift (e.g. .io once "Indian Ocean", now "tech startup").
**Examples**: openai.com, huggingface.co, replicate.com (brand + TLD alignment).
**Note**: This archetype is about choosing the TLD to reinforce the theme, not about hacking the TLD spelling.

---

## 3 — The 10 brainstorming techniques: what each does well

| Technique | Produces | Best for |
|-----------|---------|---------|
| Portmanteau | Blended words, both visible | Compound and Abstract archetypes |
| Truncation | Shorter versions of longer words | Short & Punchy |
| Phonetic Spelling | Same sound, alternate spelling | Making generic words unique |
| Prefix/Suffix | get-, try-, -hq, -labs, -ly | Track B Strategy 1; Descriptive |
| Metaphor Mining | Conceptually adjacent physical nouns | Abstract/Brandable, Playful |
| Alliteration | Repeated initial sounds | Playful/Clever, memorability |
| Word Reversal | Backwards/mirror words | Playful/Clever, counter-cultural |
| Foreign Language | Non-English words/roots | Abstract/Brandable; internationalisation |
| Acronym | Initials that spell a word | Technical brands, authority signal |
| Internal Rhyme | Pattern-based sound matching | Playful/Clever, Short & Punchy |

**Practical rule**: Apply all 10 techniques across all 7 archetypes in Wave 1 to maximise coverage. Then weight techniques based on Q2/Q3/Q4/Q5 answers for Wave 2.

---

## 4 — Domain registrar knowledge

### Registrar comparison (last verified: 2026-Q2 — verify before use, renewal prices matter more than first-year promotions)

| Registrar | .com/yr | TLDs | Bulk batch API | Pricing API | Auth needed |
|-----------|---------|------|----------------|-------------|-------------|
| Cloudflare | ~$9.15 (at-cost) | 390+ | Yes (20/call) | Via main API | API token + Account ID |
| Porkbun | ~$11.08 | 627+ | Per-domain | `/pricing/get` no auth | API key + secret |
| Namecheap | ~$13.98 | 1,500+ | Via Beast Mode | Via main API | API key |
| Dynadot | ~$12.99 | 400+ | Per-domain | Via main API | API key |

**Why Cloudflare is primary**: At-cost pricing is the most accurate reflection of true domain cost. Developers using Claude Code typically already have a Cloudflare account. The batch API (up to 20 domains per call) makes Wave 1 availability checking fast.

**Why Porkbun pricing is always called**: `/pricing/get` requires no authentication and returns all TLD prices in a single call. This makes it the cheapest source of pricing data regardless of which tier handles availability.

**Why Cloudflare suppresses Porkbun availability**: Calling both when one succeeds is wasteful and introduces rate-limit risk. Cloudflare and Porkbun pricing data often agree; when they differ, Cloudflare's at-cost figure is preferred.

### RDAP — structured domain intelligence

RDAP (Registration Data Access Protocol) is the ICANN-standard successor to WHOIS. It returns structured JSON including registrant, registrar, creation/expiry dates, and nameservers. It requires no authentication and queries route automatically to the correct registry.

```bash
# RDAP lookup for existing domain (no auth required)
curl -s "https://rdap.icann.org/domain/example.com" | jq '.registrant,.events'
```

RDAP is not currently used in namesmith but is the recommended path for future domain intelligence features (age, registrant identity hints, expiry-based opportunity detection).

### TLD selection by budget/stage

| Stage | Recommended primary | Recommended backup | Avoid |
|-------|--------------------|--------------------|-------|
| Bootstrapped (<$200/yr) | .com if available | .io, .app, .dev | .ai, .xyz (poor trust signal for some) |
| Growth ($500–$2k/yr) | .com | .io + .ai bundle | Budget TLDs as primary |
| Scale ($5k+/yr) | .com + variant portfolio | .io, .co, .ai parked | Single-registrar lock-in |

**Renewal pricing matters more than first-year pricing**: Many registrars offer first-year promotions. Namesmith should display renewal price, not just registration price, for all candidates.

---

## 5 — Personal brand naming: patterns from developer site research

Research on 25 developer personal brand sites (Lea Verou, Addy Osmani, Anthony Fu, Dan Abramov, Robin Rendle, and others) reveals 5 personal brand archetypes that influence domain naming:

| Archetype | Domain pattern | Examples |
|-----------|---------------|---------|
| The Essayist | firstname.com or firstnamelastname.com | danabramov.com |
| The Portfolio Builder | short-handle.dev or firstname.studio | anthonyfoo.dev |
| The Community Leader | handle.com (matches social handle) | kentcdodds.com |
| The Curator | firstname.io or handle.xyz | robinrendle.com |
| The Contractor/Consultant | fullname.com or lastname.io | sarasoueidan.com |

**Key insight from research**: Personal brands succeed when the domain matches the social handle exactly. Before recommending personal brand domains, namesmith should check handle availability (@twitter, @github, @linkedin) alongside domain availability.

**The "one memorable concept" principle**: The most-followed personal brands anchor around one concept (e.g., "Learn in Public" for swyx.io). Domain names for personal brands should reflect this concept, not just the person's name. Offering `[firstname][concept].com` variants (e.g., `johnbuilds.com`) is often more distinctive than `johndoe.com`.

**Distinctive URL paths that signal brand personality** (inform naming interview signals):
- `/now` → humanises brand (transparency signal)
- `/uses` → craftsmanship signal
- `/consulting` (vs `/hire`) → expert positioning, not commodity

---

## 6 — AI agent prompting patterns that work

From nikai's Claude Skills architecture and idea-evaluator skill design:

### Progressive disclosure works
Level 1 (metadata) → Level 2 (SKILL.md body) → Level 3 (references/ on-demand) prevents context bloat. The SKILL.md should never exceed ~2,000 words; everything else goes in references/.

### Positive instructions outperform negative constraints
"Generate 3 candidates per archetype" is more reliable than "Don't generate fewer than 3 per archetype". State what TO DO.

### XML tags improve structured output reliability
```xml
<brand_profile>
  <tone>A — cool/media-brand</tone>
  <direction>B — abstract/invented</direction>
</brand_profile>
```

Claude follows XML-structured output more consistently across long sessions than plain prose instructions.

### Validation rules at the end of workflows catch gaps
Include a `<validation_checklist>` at the end of multi-step workflows. Claude uses it to self-review before output. For namesmith Wave 1:
```xml
<validation_checklist>
  - [ ] At least 25 candidates generated
  - [ ] All 7 archetypes represented
  - [ ] Short & Punchy names respect Q5 length cap if A was chosen
  - [ ] Wave output heading matches Wave [N] pattern
  - [ ] TLD summary line present
</validation_checklist>
```

### Parallel research agents improve quality on multi-signal tasks
nikai's idea-evaluator runs 5 parallel research agents (market demand, competition, data availability, distribution, customer voice) and then synthesises. For namesmith, a future enhancement could run parallel micro-agents for: (1) uniqueness check, (2) trademark-class pre-screen, (3) phonetic cross-language check, (4) SEO potential estimate.

---

## 7 — Known gaps and planned enhancements (from research)

These are documented gaps from the v0.1.0 research pass. Create a GitHub issue or feature spec before implementing any of these.

### A. Documentation gaps
- **No `.feature` files existed at v0.1.0** — now addressed (see `specs/` directory)
- **Cloudflare Registrar has a TLD support list** (~390 TLDs) that isn't documented in `tld-catalog.md`. Domains outside CF's supported set must fall back to Porkbun even when CF is primary
- **Wave 2 weighting rules are not explicitly specified** in `generation-archetypes.md`. The skill says "adjust weights" but doesn't specify by how much per archetype-feedback signal
- **Porkbun pricing response schema** (field names, units) is not documented in `api-setup.md`

### B. Cross-file inconsistencies to resolve
- `DECISIONS.md` D-03 describes Q3 as "Direction (A: functional, B: abstract/invented)" — the adjective for type B should consistently be "Abstract/Brandable" (matching the archetype name), not "abstract/invented"
- `DECISIONS.md` D-05 says "Track B runs 4 strategies in order" but doesn't specify the stop condition (≥5 available). `SKILL.md` says stop at ≥5. `TESTING.md` says stop at ≥5. Align `DECISIONS.md`.
- The Short & Punchy 6-character cap (Q5=A) needs to specify whether it applies to the base name only, or the full `name.tld` string. Both `SKILL.md` and `TESTING.md` say "≤6 chars" but the TLD would push total length over 6 for any domain. Clarify.
- `registrar-routing.md` should document which CF-unsupported TLDs fall back to Porkbun automatically

### C. Enhancement opportunities (validated, not scheduled)
- **Error recovery for Track B exhaustion**: When all 4 strategies find fewer than 5 available options, the current skill has no explicit recovery path. Need: display what was found + offer "broaden constraints or start fresh" options
- **Incremental names.md updates**: Currently names.md is written once after wave output. A future enhancement could update it after each wave, appending new rows rather than overwriting
- **Non-English project names**: The interview Q1 answer could be in any language. The skill should acknowledge this and apply the brainstorming techniques to the non-English root word before translating candidates
- **Domain age / opportunity detection**: Expired domains with existing backlinks can be extremely valuable. A future "domain opportunity" tier could query RDAP for expiry dates and flag near-expiry domains that match generated names
- **Scoring system**: v0.1.0 has no explicit scoring. A 7-dimension scoring model (availability, trademark risk, pronounceability, memorability, SEO potential, personality fit, defensibility) would let the skill surface ranked recommendations rather than flat lists

### D. Contributor experience gaps
- **Weighting algorithm is ambiguous**: The weighting rules table in `brand-interview.md` says "Descriptive ↑" but not by how many percentage points. A concrete weighting table (e.g., "Descriptive base weight: 10%, Q2=B bonus: +5%") would make the system auditable
- **Personal brand flow has no example**: `example-session.md` only covers the standard product naming flow. A personal brand example session (portfolio designer, "John Smith") is needed
- **Track B has no worked example**: The example session ends after Wave 2 without showing a Track B scenario. A Track B example session would help contributors understand the stop condition

---

## 8 — Superpowers workflow patterns applied to namesmith

Research source: `superpowers` Claude Code plugin v5.0.7 skills directory.

### The TodoWrite checklist pattern

Every superpowers skill with a multi-step workflow begins with:
```markdown
## Checklist
You MUST create a TodoWrite task for each item and complete them in order:
1. Step one
2. Step two
...
```

This pattern was missing from namesmith v0.1.0. It was added in v0.2.0. The result is that when namesmith activates, the user sees a task list with visible progress — exactly what the brainstorming skill does when it creates a task for each of its workflow steps. Without this, the skill's progress is invisible.

**Why it matters for namesmith specifically**: The site-naming workflow has 10 discrete steps. Without task tracking, a session that stalls at Step 5 (availability check) looks identical to one that completed successfully. With TodoWrite items, the user can see exactly where the workflow stopped.

### The announce pattern

Every superpowers skill starts with:
```markdown
**Announce at start:** "I'm using the [skill-name] skill to [purpose]."
```

This tells the user that a structured workflow has started, sets expectations for the conversation structure, and signals that the agent will not shortcut the process. Added to namesmith v0.2.0.

### The hard gate pattern

The brainstorming skill uses:
```html
<HARD-GATE>
Do NOT [take action] until [prerequisite]. This applies regardless of [common shortcut].
</HARD-GATE>
```

The HTML tag is not rendered — it is a signal to Claude that this rule is absolute and not subject to judgment. For namesmith, the hard gate prevents name generation before all 6 interview questions are answered. Without it, an agent might generate names after 3 questions "since the description was clear enough" — losing the archetype weighting data from Q4 and Q5.

### The red flags table

The TDD and verification-before-completion skills use `| Thought | Reality |` tables to name specific rationalizations an agent might make under pressure and provide direct counters. For namesmith, the common rationalizations are:
- "The description is clear, I can skip some questions"
- "Let me suggest a few names while the interview runs"
- "The user seems impatient, I'll generate early"

Each maps to the same correct action: complete the interview first.

### Integration and skill chaining

Superpowers skills document their dependencies explicitly:
```markdown
**Required sub-skills:** superpowers:X (called before), superpowers:Y (called after)
```

The namesmith skill doesn't chain to other skills (it's a terminal deliverable, not part of a development pipeline). But the pattern of documenting what calls it (brainstorming, writing-plans) and what it calls (nothing — it's terminal) is worth adding in a future iteration.

---

## 9 — Session orientation pattern (from yestay / lex-harness research)

Research source: yestay project `docs/superpowers/` and `09_ai_research/specs/SPEC-01_skill_system.md`.

The lex-harness plugin's DISCOVER phase documents a **session orientation** step: before doing any work, check for existing state (a `CURRENT_STATUS.md` file) and output a brief:
```
Phase: [current phase]
Last action: [what was done]
Critical deadlines: [upcoming deadlines]
ONE next action: [top priority]
```

Applied to namesmith as Step 0 in v0.2.0: if `names.md` exists in the CWD, read it and offer to resume. This prevents:
- Losing brand interview data (if user ran Wave 1 last session)
- Running a duplicate wave (if names.md has 3 shortlisted names, user may just want Wave 2)
- Starting fresh when the user only wanted to run Track B on taken domains

**The session brief format for namesmith:**
```
Previous session: [project description]
Brand profile: Tone=[X] | Direction=[Y] | Mode=[Z] | Length=[W]
Shortlisted: [name1], [name2], [name3]
Options:
  1. Continue — run Wave 2 or refine shortlist
  2. Start fresh — new interview, new wave
  3. Track B — run fallback strategies on taken names
```

**Why three options**: Research showed that users return to namesmith in three states: (1) satisfied with Wave 1, wanting refinement, (2) abandoning and starting over, (3) all Wave 1 picks were taken and they need Track B. Having explicit options prevents the agent from guessing which state applies.

---

## 10 — Seven essential information categories (apply to all briefs)

From nikai's Business Documentation Framework: when handing off naming work to an AI agent (or another human), these 7 categories must survive the handoff for the output to remain coherent:

1. **Problem definition**: What is being named and why a new name is needed
2. **Success metrics**: What does "a good name" mean for this project? (memorability, SEO, trademark position, domain cost)
3. **Constraints / appetite**: Hard constraints (avoid list, required TLD) and budget appetite
4. **Non-goals**: Names the user explicitly doesn't want (styles to avoid, archetypes not to explore)
5. **Key decisions made**: Any decisions already locked in (e.g., "we're committed to .io")
6. **User context**: Who the end users are; how they'll encounter the brand name
7. **Business rationale**: Why this naming decision matters now (launch timeline, rebrand context, etc.)

The brand interview Q1–Q6 captures items 1, 3, 4. Items 2, 5, 6, 7 are typically implicit. Future enhancement: add these 4 categories as optional Q7–Q10 for high-stakes naming sessions (full rebrand, Series A launch).
