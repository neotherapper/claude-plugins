# Namesmith — Live Session Insights

> Extracted from real naming sessions to capture what works, what doesn't, and
> specific techniques that produced the best outcomes. Use these to inform skill
> design, reference file content, and conversation flow improvements.

---

## Sessions Analysed

| Session | Project | Topic | File |
|---------|---------|-------|------|
| `2ae3d9e7` | nikai | Draftloom plugin naming | nikai JSONL |
| `4f21b917` | nikai | IMDb-for-developers naming (Wave 1) | nikai JSONL |
| `a6313415` (subagent) | nikai | Developer directory deep naming exploration | nikai JSONL |

---

## 1 — Techniques That Produced the Best Names

### 1.1 Mechanism-First Metaphor (strongest technique overall)

Rather than describing what the product *is*, find the operational metaphor for what it *does* — then name from that.

**Worked examples:**

| Name chosen | Mechanism found | Metaphor |
|-------------|----------------|---------|
| `Draftloom` | Multi-agent eval loop produces a draft | Weaving (warp+weft = multiple agents, finished cloth = post) |
| `level.dev` (near-miss, false DNS positive) | Tier system IS a levelling system | Gaming — Emerging/Legend maps to Level 1–MAX |
| `primo.dev` | First/best developer directory | Italian "primo" = first/best; casual English already uses it |

**How to apply:** Ask "what does this product do operationally, not what is it categorically?" Extract the verb or process, then find a word that IS that verb.

---

### 1.2 Italian Superlative Suffix Family ("-issimo")

Triggered when a user says something like "I like massimo/maxi/extreme." Explore the full suffix family before checking any one variant.

**Family breakdown:**

| Sub-family | Pattern | Examples generated |
|-----------|---------|-------------------|
| -issimo | base + issimo (superlative) | `devissimo`, `codeissimo`, `hackissimo`, `buildissimo` |
| massi- | massimo root as prefix | `massicoder`, `massimaker`, `massistack`, `massibuild` |
| -imo | short suffix on dev words | `devimo`, `codimo`, `gitimo`, `stackimo` |
| primo | Italian "first/best" | `primo.dev`, `primodev`, `devprimo`, `primocode` |
| short forms | massi root, short domain | `massi.dev`, `massim.dev` |

**Best performer:** `primo.dev` — follows the GitHub/Notion/Stripe naming logic exactly. One word, repurposed, means "the best/first", used casually in English, Italian roots give warmth without obscurity. "I'm on Primo" sounds natural.

**How to trigger:** Mine the user's casual vocabulary during the interview for strong words they've used. Any Italian/Mediterranean word is likely to have a productive suffix family.

---

### 1.3 Suffix Family Plays (portmanteau/suffix construction)

Triggered by user saying things like "like Pokédex" or "like Delicious." Apply the model systematically.

| Family | Model | Examples generated |
|--------|------|--------------------|
| -dex | Pokédex — catalog/index | `makedex.dev`, `hackdex.dev`, `coderdex.dev`, `coderex.dev` |
| -haus | Bauhaus — school of greats | `coderhaus.dev`, `builderhaus.dev` |
| -eum | museum — archive of the greats | `deveum.dev`, `codereum.dev` |
| -lex | lexicon / law | `devlex.dev`, `coderlex` |
| -licious | del.icio.us pattern | `devlicious`, `codelicious`, `hackalicious` |

**Best performers:** `coderex.dev` (coder + index + T-Rex energy), `devlex.dev` (dev + lexicon — the language of devs)

---

### 1.4 The "-dex/-ex/-ix" Index Suffix Family

Particularly productive for directory/ranking products. Compressing "index" into a brand suffix generates names that feel technical but punchy.

| Name | Decomposition |
|------|--------------|
| `kredex` | cred + index |
| `repvex` | rep(utation) + vertex |
| `stardex` | star + index |
| `profaxis` | profile + axis |
| `crestix` | crest + ix |
| `veridex` | veritas (truth) + dex |

---

### 1.5 Single-Word Repurposing (the "Notion Pattern")

The most memorable brands take a common English word and repurpose it entirely. "Notion doesn't explain notes. Level doesn't explain developer profiles. It just becomes it."

**The 6-point memorable-name framework (verbatim from session):**

1. **Short enough to be a hashtag** — max 2 syllables ideally (Twitter, Slack, Figma)
2. **The "click" moment** — a small insight when name meets product. Stripe → a stripe of payment data. That click = the memory anchor
3. **Works in possession** — "my GitHub", "my Notion", "my ____" — must sound natural
4. **Creates a social sharing sentence** — "Just checked my ____ profile, I'm Top-Tier" — the name needs to complete that tweet cleanly
5. **Unique enough to own the search result** — invented or rare words win. "Notion" fought a hard SEO battle. "Figma" owned it from day one
6. **Satisfying to say aloud** — rhythm matters. Twitter has double-T. Figma has hard G. Notion has the -shun ending

**Best performers:** `level.dev`, `prism.dev`, `pessoa.dev` (Fernando Pessoa — Portuguese poet with multiple identities)

---

### 1.6 Domain Hacks (ccTLD as word completion)

| Domain | Word it spells | Note |
|--------|---------------|------|
| `cod.er` | coder | **Strongest of session** — literally IS the word "coder" |
| `build.er` | builder | Clean, natural |
| `build.rs` | builders | Double meaning: Rust build.rs file — nerd culture bonus |
| `hack.er` | hacker | Direct |
| `mak.er` | maker | Maker culture fit |
| `codi.ng` | coding | `.ng` = Nigeria |
| `co.re` | core | `.re` = Réunion |

**Caution:** All ideal short ccTLD hacks are typically taken. Generate 8–10 hacks to compensate for the high take rate.

---

### 1.7 Etymology Mining (Greek/Latin/Italian)

Productive when the product has gravitas or prestige positioning.

**Greek cluster:** `devpantheon.dev`, `devagora.dev`, `lexos.dev`, `telos.dev`, `mylos.dev`
**Latin cluster:** `primo.dev`, `veridex`, `prism.dev`
**Italian cluster:** All the -issimo family above, plus `.icu` = "I see you" TLD

**`.icu` discovery:** The `.icu` TLD reads as the phrase "I see you" — for a developer discovery platform this is perfect: "Massimo, I see you." Cheap (~$3–5/yr).

---

## 2 — Deep-Dive Analysis Format (for the best names)

When a candidate crosses the "this could be the one" threshold, shift from table format to a deep single-name analysis. Model from the `level.dev` treatment:

**Template:**
```
**`[name]` — [availability] [price]**

This is [position in session — strongest, most surprising, etc.].

- **The tweet**: "[exact tweet text a user would send]"
- **The question that spreads it**: "[question people ask that spreads the brand]"
- **The product fit**: [how the name maps to the product's core mechanic]
- **Cultural resonance**: [gaming/dev culture connection]
- **The [Notion/Stripe/Figma] pattern**: [how it fits the repurposed-word brand archetype]
- **SEO ownership**: [why this name wins search]
- **Works in every context**: "[Check their X]", "[my X card]", "[I'm on X]", "[According to X...]"
```

**When to use:** When a candidate is available, passes the 6-point framework, and the session has been long enough to build real context for what the product needs.

---

## 3 — Output Formats That Worked

### 3.1 Top Picks + Per-Archetype Tables

The Wave 1 output structure that produced the best UX:

```markdown
## Wave 1 Results — [product description]

**Top Picks**

✅ `ranqova.com` ~$12/yr — Rank + Nova. Abstract, invented, sounds like a proper noun.
The "rank" semantics land without being on-the-nose. Strong .com.
[Cloudflare →](https://dash.cloudflare.com/domains/registrations/purchase?domain=ranqova.com)

---

**Short & Punchy**
| Domain | Status | Notes |
|--------|--------|-------|
| kredex.io | ✅ | 6 chars, cred + index |
| devlum.io | ✅ | dev + lumen (developer in the light) |
| rankio.com | ❌ | — |

**Abstract/Brandable**
| Domain | Status | Notes |
|--------|--------|-------|
| ranqova.com | ✅ CF confirmed | Rank + Nova |
| repvex.io | ✅ likely | rep + vertex |
| stardex.com | ❌ | — |

[... repeat for each archetype ...]

---
TLD summary: `.com` 2 available | `.io` 8 available | domain hacks all taken
**12 confirmed available** of 35 checked.
```

**Key rules of this format:**
- Taken names (❌) are shown inline — not hidden. User sees what was considered and rejected.
- Top Picks has prose rationale + registration link for each pick
- Footer TLD summary gives quick scorecard
- Registration links use Cloudflare's pre-fill URL pattern

### 3.2 Corrected Availability Table (post-debug)

When the API check returns inconsistent results, issue a corrected summary:

```markdown
**Corrected availability summary:**

| Domain | Signal | Verdict |
|--------|--------|---------|
| `ranqova.com` | CF API ✅ | **Confirmed available** |
| `forkfame.com` | CF API ✅ | **Confirmed available** |
| `devscene.io` | No DNS + no whois | Likely available |
| `kredex.io` | Porkbun ❌ | Taken |
| `rank.dev` | CF API: premium | Not at standard price |
```

### 3.3 Suffix Family Exploration Block

When exploring a suffix family, present as a named section:

```markdown
### "-dex" family (Pokédex energy)

| Name | Concept | Available |
|------|---------|-----------|
| **`makedex.dev`** | maker + index — catalog of makers | ✅ |
| **`hackdex.dev`** | hacker + index — hacker culture vibes | ✅ |
| **`coderdex.dev`** | coder + index — most literal | ✅ |

### Wildcards

| Name | Concept | Available |
|------|---------|-----------|
| **`coderex.dev`** | coder + index + T-Rex energy | ✅ |
| **`devlex.dev`** | dev + lexicon — the language of devs | ✅ |
```

---

## 4 — What the Agent Should Explain (Rationale Quality)

### 4.1 Short rationale (Wave 1 tables)

One short sentence in the Notes column. Focus on decomposition + product fit:
> "Rank + Nova. Abstract, invented, sounds like a proper noun. The rank semantics land without being on-the-nose."

### 4.2 Deep rationale (Top Picks prose)

2–3 sentences. Cover: what the word parts mean, why the combination works for this product, how someone would say it in a sentence:
> "Fork + Fame. Alliterative, playful, IMDb-adjacent ('fame'), instantly signals developer culture. Community energy. The tweet: 'Just hit Top-Tier on level.dev 🎮 Who else is leveling up?'"

### 4.3 "How people say the name" test

After any final candidate, always articulate how it works in everyday speech:
- "I use [Name] to..." (verb test)
- "Check their [Name]" (social sentence)
- "I'm on [Name]" (identity sentence)
- "According to [Name]..." (authority sentence)

If any of these feel awkward, flag it: "Note: [Name] doesn't work well as a verb — 'I [name]d my profile' sounds forced."

---

## 5 — Flow Improvements Identified from Sessions

### 5.1 Mine user's casual vocabulary for technique leads

Pattern: user says "I like massimo/delicious/Pokédex" → escalate immediately to that suffix family. Don't just note the word; generate the full family.

### 5.2 The creativity inflection point

Every naming session has a moment when the user pushes harder for creativity ("brainstorm more", "think about what can be more catchy"). This is when to:
- Ask them for 1–2 words they find interesting (any domain)
- Apply those words as seed concepts for suffix families, etymological mining, or metaphor exploration

### 5.3 DNS false positives on .dev domains

Google Registry (`.dev`, `.app`, `.page`) domains often return no DNS when registered but not deployed. Always cross-check:
1. `whois` → check for `status: ACTIVE` or similar
2. CF API → `registrable: false, reason: domain_premium` means taken (premium)
3. CF API only supports ~390 TLDs — `.io` is not supported; use Porkbun for `.io`

### 5.4 The API Gate should explain itself

When the credential check triggers, tell the user WHY it matters before offering setup:
> "Before I run the availability check, I'll verify your API credentials. Using the Cloudflare and Porkbun APIs gives confirmed availability and pricing in real-time — without them I fall back to DNS lookups which can give false positives on .dev domains."

### 5.5 Persona/mechanism anchoring question

The single most valuable question before deep generation:
> "What does the product do operationally — not what it is, but what it actually does step by step?"

This surfaces the mechanism, which is the best naming raw material.

---

## 6 — What Went Poorly

| Issue | Root cause | Fix |
|-------|-----------|-----|
| DNS false positives on level.dev | Google Registry .dev domains often have no DNS but are registered | Use RDAP or CF API, not `dig` alone |
| check-domains.sh silent CF API crash | `.result[]` path wrong — CF returns `.result.domains[]` | Fix jq path in script |
| .io not supported by CF API | CF registrar doesn't support .io | Route .io directly to Porkbun |
| Session ran 1784 lines without a clear name | No vibe check before deep generation | Add direction round (Option B) before availability check |
| User re-asked the methodology mid-session | No transparency about which API tier was used | Log tier used in status output: "Checking via Cloudflare API..." |
| Wave 2 never triggered | Session ended after corrected availability table | Always offer explicit next options after table: "Want to go deeper on any of these, or start Wave 2?" |

---

## 7 — New Archetype Enhancement: Suffix Family Archetypes

The current 7 archetypes don't have an explicit "Suffix Family" technique. The session data suggests this is one of the highest-yield techniques for naming directories and developer tools.

**Proposed addition to `generation-archetypes.md`:**

```
### Suffix Family Exploration (technique)

When the product has a strong category word (index, rank, code, build, dev), explore:
- The -dex family (Pokédex model): [base]dex, [base]ex, [base]ix
- The -haus family (Bauhaus school): [base]haus
- The -eum family (museum, archive): [base]eum
- The Italian superlative family: [base]issimo, massi[base], [base]imo, primo
- The ccTLD hack family: [base].er, [base].rs, [base].ng

For each family, generate 3–5 variants. Note: -dex and -ex families are especially 
productive for directory/ranking products (the compressed "index" metaphor lands 
naturally).
```

---

## 8 — The `level.dev` Analysis Verbatim

This is the model for deep single-name analysis. Preserve exactly:

> **`level.dev` — free, single word, .dev**
>
> This is the strongest name of the entire session. Here's why it clears every bar:
>
> - **The tweet**: "Just hit Top-Tier on level.dev 🎮 Who else is leveling up?" — that's a real tweet people will send
> - **The question that spreads it**: "What's your level?" — every developer already knows what that means
> - **The product fit is exact**: the tier system IS a levelling system. Emerging → Established → Top-Tier → Legend maps perfectly to Level 1, 2, 3, MAX
> - **Gaming culture**: every developer is also a gamer. "Level up" is already in developer Twitter vocabulary
> - **The Notion pattern**: single common word, totally repurposed. Notion doesn't explain notes. Level doesn't explain developer profiles. It just becomes it
> - **SEO ownership**: invented/rare brand names own search. "level.dev" will own its results
> - **Works in every context**: "Check their Level", "my Level card", "I'm on Level", "According to Level..."

*Note: This domain turned out to be registered (DNS false positive). But the analysis template is the model for any candidate that crosses the "strongest of session" threshold.*

---

## 9 — Popular Brand Name Pattern Examples (from competitor analysis)

Extracted from the developer directory competitor research in the `a6313415` session:

| Site | Pattern | Notes |
|------|---------|-------|
| GitRoll | Git + Roll (talent "roll call") | Domain-specific anchor + metaphor |
| OSSInsight | OSS + Insight | Descriptive compound |
| Peerlist | Peer + List | Transparent utility name |
| Polywork | Poly (many) + Work | Latin prefix + noun |
| WakaTime | Waka (Māori canoe) + Time | Foreign word + English noun; career trajectory metaphor |
| Showwcase | Showcase (misspelled) | Deliberate typo for uniqueness |
| daily.dev | daily + .dev TLD | TLD completes the brand word |
| CommitRank | Git term + Rank | Domain-specific jargon |

**Patterns to apply in generation:**
1. **Git-prefix family** — for developer tools: GitRoll, Gitstar, etc.
2. **Compound descriptive** — OSSInsight, CodersRank — what it is + what it does
3. **Misspelling for uniqueness** — Showwcase (extra 'w')
4. **TLD-as-suffix** — daily.dev (the .dev TLD completes the brand word)
5. **Lateral concept import** — WakaTime (Māori canoe metaphor for career)
6. **Peer/community framing** — Peerlist (social graph, not the individual)
