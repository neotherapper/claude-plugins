# Generation Archetypes

## 8 Archetypes

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

**How to generate:** Load `$CLAUDE_PLUGIN_ROOT/skills/site-naming/references/tld-catalog.md`. Take core concept words. Identify if any fragment of the word matches a ccTLD ending. The best hacks are short (under 8 chars total) and the TLD meaning reinforces the concept.

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
A generic or descriptive base name paired with a TLD that adds meaning (load `$CLAUDE_PLUGIN_ROOT/skills/site-naming/references/tld-catalog.md` for full category matrix).

**Examples:** build.studio, launch.ai, code.run, ship.it, deploy.dev, design.systems, make.tools

**How to generate:** Take the core verb or noun from the concept. Find a TLD from tld-catalog.md's thematic categories that reinforces it. The name + TLD should read as a complete phrase.

---

### 8. Suffix Family Exploration

**When to use:** When the product has a strong category word (index, rank, code, build, dev) OR when the user's Q7 vocabulary hints at a suffix family (Italian, Pokédex → -dex, Bauhaus → -haus).

**Sub-families to explore:**

| Sub-family | Pattern | Examples |
|-----------|---------|---------|
| -dex | Pokédex model — catalog/index | `coderdex`, `devdex`, `makedex` |
| -haus | Bauhaus — school of greats | `coderhaus`, `devhaus` |
| -eum | museum — archive of the greats | `deveum`, `codereum` |
| -issimo | Italian superlative | `devissimo`, `codeissimo`, `hackissimo` |
| massi- | massimo root as prefix | `massidev`, `massicoder` |
| primo | Italian "first/best" | `primo.dev`, `primodev` |
| ccTLD hack | [base].er, [base].rs, [base].ng | `cod.er`, `build.rs`, `hack.er` |

Generate 3–4 variants per relevant sub-family. Note: -dex and -ex families are especially productive for directory/ranking products (the compressed "index" metaphor). ccTLD hacks have high take rates — generate 8–10 to compensate.

**Direction Round sample (2 names max):** one from -dex family, one from -issimo family.
**Deep Generation full block:** generate all relevant sub-families for the selected seed concept.

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
Generate 15–20 candidates across the archetypes selected in Phase 2 Direction Round (max 3) plus any seed vocabulary from Q7 or the forced pivot. Apply weighting from brand-interview.md. If Suffix Family is selected, generate the full suffix family exploration block (see Archetype 8). Do not check availability during generation — generate the full list first, then batch-check.

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
Load `$CLAUDE_PLUGIN_ROOT/skills/site-naming/references/tld-catalog.md`. Take the 3–5 best base words from the session. Scan the domain hack catalog for any word fragment + ccTLD completion. Present all matches.
