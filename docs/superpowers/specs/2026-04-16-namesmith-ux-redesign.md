# Namesmith UX Redesign — Implementation Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace namesmith's direct interview→generation→check flow with a 7-phase flow that includes a Direction Round — showing archetype samples before deep generation so the user steers before 20+ names are generated blind.

**Architecture:** The Direction Round sits between interview and generation. It shows 2 unweighted samples per archetype (16 names + 2 wildcards), collects resonance signal, then gates Deep Generation on an explicit archetype/seed selection. Everything else (availability check, results, Wave 2) stays structurally similar but gains inline API gate, conditional Spotlight, and consistent soft Wave 2 prompt.

**Affected files:**
- `plugins/namesmith/skills/site-naming/SKILL.md` — rewrite flow (Steps 0–9 → 7 phases)
- `plugins/namesmith/skills/site-naming/references/brand-interview.md` — add Q7 vocabulary mining
- `plugins/namesmith/skills/site-naming/references/generation-archetypes.md` — add Suffix Family as 8th archetype
- `plugins/namesmith/skills/site-naming/scripts/check-domains.sh` — fix `.result[]` → `.result.domains[]`, add explicit `.io` routing to Porkbun

---

## Phase-by-Phase Spec

### Phase 1 — Orient + Interview

**Merges:** current Step 0 (session orientation) + Step 1 (project file detection) + Step 2 (personal brand detection) + Step 3 (brand interview)

**Changes from current:**
- No structural change to Steps 0–2 logic
- Brand interview grows from 6 to 7 questions
- Q7 (new): "Any words from any domain — a brand, a place, a concept — that you love the sound or feel of?" — this is vocabulary mining; answers seed the Direction Round suffix/etymology family exploration
- Brand profile summary after Q7 includes `Vocabulary: [Q7 answer or "none"]`

**Hard gate:** Do NOT proceed to Phase 2 until all 7 questions are answered and brand profile is locked.

**Reference files to load:** `brand-interview.md` (before Q1)

---

### Phase 2 — Direction Round

**NEW phase — does not exist in current SKILL.md**

**Purpose:** Calibrate direction before weighted generation. Show the user what each archetype looks like for their project. Collect resonance signal. Gate deep generation on explicit selection.

**How it works:**

1. Load `generation-archetypes.md`. Generate 2 name candidates per archetype, UNWEIGHTED (equal representation). 8 archetypes × 2 = 16 names. Append 2 wildcards (cross-archetype combinations). Total: 18 candidates. Do NOT check availability yet.

2. Present as a compact table, one archetype per section:

```
## Direction Round — which of these feels closest?

**Short & Punchy**         `kredex` · `devlum`
**Descriptive**            `coderank.dev` · `devprofile.io`
**Abstract/Brandable**     `ranqova` · `veltrix`
**Playful/Clever**         `forkfame` · `codewitch`
**Domain Hacks**           `cod.er` · `build.rs`
**Compound/Mashup**        `gitpulse` · `stackmark`
**Thematic TLD Play**      `dev.so` · `code.run`
**Suffix Family**          `coderdex` · `devissimo`
─────────────────────────────────────────
**Wildcards**              `primo.dev` · `lexos.dev`

Which direction resonates — or is there a word from any domain you want to explore?
```

3. Present exactly 3 response options (numbered, no prose):
   ```
   1. Pick archetypes (e.g. "1, 3, 5")
   2. Give me a seed word to explore
   3. None of these — show me different samples
   ```

4. **Rejection loop:** Track `rejectionCount`. On option 3, increment counter and regenerate Phase 2 with fresh samples from the same archetypes. After 3 consecutive rejections, force a pivot: "Let's try a different approach — give me 2 words you find interesting from any domain (a place, a brand, a concept)." Use those words as seed vocabulary for Deep Generation; proceed to Phase 3.

5. **Hard gate:** Do NOT proceed to Phase 3 until user has either (a) selected at least one archetype, (b) provided a seed word, or (c) triggered the forced seed-word pivot after 3 rejections.

**Archetype cap:** Maximum 3 archetypes may be selected. If user selects more, respond: "Let's keep it focused — pick your top 3."

**Reference files to load:** `generation-archetypes.md` (before generating samples)

---

### Phase 3 — Deep Generation

**Changes from current Step 4:**
- Volume reduced: 15–20 names (was 25–35). Direction Round already surfaced archetypes — deep generation needs quality over quantity.
- Weights from brand interview apply HERE (not in Direction Round)
- Only generate across selected archetypes (max 3) + any seed vocabulary from Q7/pivot
- Suffix Family archetype: if selected, generate the full suffix family exploration block (see `generation-archetypes.md` Suffix Family section): one `-dex` cluster, one `-issimo` cluster, one ccTLD hack cluster — 3–4 names each
- Load `tld-catalog.md` as before (archetypes 5 and 7 require it)

**No availability check yet.** Generate full candidate list first.

---

### Phase 4 — Availability Check

**Changes from current Step 5:**
- **API Gate explanation runs HERE**, not before Phase 2. Rationale: user has 20 names in front of them — the API explanation lands with context. Text to output before running scripts:

```
Before checking these [N] names — I'll use whichever API tier is configured:
- Cloudflare API → confirmed availability + pricing in real-time (best accuracy)
- Porkbun API → confirmed availability, good for .io (Cloudflare doesn't support .io)
- whois fallback → less reliable; .dev domains often show no DNS even when registered

Checking credentials now…
```

- Credential check logic unchanged (4 env vars)
- **Script fix required** (see Task 4 below): `.io` domains must route to Porkbun explicitly — do not pass `.io` to Cloudflare API
- **Script fix required** (see Task 4 below): CF API path is `.result.domains[]` not `.result[]`
- Batch into groups of ≤20 as before

---

### Phase 5 — Results

**Changes from current Steps 6–7:**
- Table format gains Source column: `Name · Domain · Status · Price · Source`
  - Source values: `CF` / `Porkbun` / `whois` / `DNS`
- Taken names shown inline (❌), not hidden
- **Conditional Spotlight:** After the table, compute a 6-point framework score for each ✅ candidate. If any candidate scores ≥ 4:
  - Output a `---` separator
  - Output deep single-name analysis using the `level.dev` template:
    - **The tweet:** exact tweet text a user would send
    - **The question that spreads it:** the question people ask that spreads the brand
    - **Product fit:** how name maps to the product's core mechanic
    - **Cultural resonance:** gaming/dev culture or other community connection
    - **The Notion pattern:** how it fits the repurposed-word brand archetype
    - **SEO ownership:** why this name wins search
    - **Works in every context:** "Check their X" / "my X card" / "I'm on X" / "According to X..."
  - Spotlight only runs for the single highest-scoring candidate. If tied, pick the shortest domain.
- Write `names.md` as before (Step 7 logic unchanged)
- **Closing prompt always appears** (hard requirement — this is the Wave 2 trigger fix):

```
[N] of [Y] checked available. Want to go deeper on any of these, or start Wave 2?
```

---

### Phase 6 — Wave 2

**Changes from current Step 8:**
- Wave 2 is triggered by the soft prompt at the end of Phase 5 — not by a numeric sufficiency gate
- Logic unchanged: generate 20+ new candidates refined toward stated preferences, no repeats from Wave 1
- Wave 3 / Track B logic unchanged

---

### Phase 7 — Post-shortlist

**No changes from current Step 9.**

---

## Script Fixes (required for Phase 4 to work correctly)

### Fix 1: check-domains.sh — CF API jq path

**File:** `plugins/namesmith/skills/site-naming/scripts/check-domains.sh`

**Current (broken):**
```bash
available=$(echo "$response" | jq -r '.result[] | ...')
```

**Fixed:**
```bash
available=$(echo "$response" | jq -r '.result.domains[] | ...')
```

This is a silent crash — jq returns nothing, script falls through to whois fallback without warning. The fix makes CF Tier 1 actually work.

### Fix 2: check-domains.sh — .io routing

**Current behavior:** `.io` domains are passed to Cloudflare API, which doesn't support `.io`. CF returns an error or empty result; script silently falls to whois.

**Fix:** Before calling the CF API, split the domain list: `.io` domains go directly to Porkbun API. All other TLDs try CF first, then Porkbun if CF returns no result, then whois.

---

## Reference File Changes

### brand-interview.md — add Q7

Add after Q6:

```markdown
### Q7 — Vocabulary Mining

"Any words from any domain — a brand, a place, a concept — that you love the sound or feel of? (e.g. 'massimo', 'Pokédex', 'notion', anything)"

This answer is optional but high-value. If provided:
- Extract the word class (Italian superlative, English single-word, portmanteau, etc.)
- Mark it in the brand profile as `Vocabulary: [word] ([class])`
- In Phase 2 Direction Round, include one sample from the suffix family of that word class
- In Phase 3 Deep Generation, if that archetype is selected, generate the full suffix family exploration block
```

### generation-archetypes.md — add Suffix Family (8th archetype)

Add as new section:

```markdown
## 8. Suffix Family Exploration

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
```

---

## 6-Point Framework (for Spotlight scoring)

Defined here for SKILL.md reference — implement inline in Phase 5:

1. **Short enough to be a hashtag** — max 2 syllables ideally (Twitter, Slack, Figma) → 1 point
2. **The "click" moment** — a small insight when name meets product → 1 point
3. **Works in possession** — "my [Name]" sounds natural → 1 point
4. **Creates a social sharing sentence** — "Just checked my [Name] profile" works as a tweet → 1 point
5. **Unique enough to own search** — invented or rare word → 1 point
6. **Satisfying to say aloud** — rhythm, hard consonants, satisfying ending → 1 point

Score each ✅ candidate. Spotlight triggers if any score ≥ 4.

---

## What Does NOT Change

- Step 0 resumption detection logic (exact same 3-option menu)
- Step 1 project file detection
- Step 2 personal brand detection and personal brand flow
- Step 5 script output parsing (`available` / `taken` / `redemption` / `unknown`)
- Step 6 registration link generation and registrar-routing.md usage
- Step 7 names.md write format
- Step 8 Wave 3 / Track B logic
- Step 9 post-shortlist checklist

---

## File Map

| File | Action | Reason |
|------|--------|--------|
| `SKILL.md` | Rewrite | New 7-phase flow replaces 9-step flow |
| `references/brand-interview.md` | Add Q7 | Vocabulary mining |
| `references/generation-archetypes.md` | Add section 8 | Suffix Family archetype |
| `scripts/check-domains.sh` | Fix × 2 | `.result.domains[]` path + `.io` routing |

---

## Testing

After implementation, verify with a simulated session:

1. Start namesmith with no `names.md` present → should run Phase 1 full interview
2. Answer all 7 questions → brand profile summary should include `Vocabulary` line
3. Phase 2 Direction Round should show 8 archetype rows + 2 wildcards
4. Select 2 archetypes → Phase 3 generates 15–20 names from those 2 only
5. Phase 4 should print API Gate explanation before running scripts
6. For a `.io` domain in the candidate list: verify it routes to Porkbun, not CF
7. Phase 5 Results table should have 5 columns including Source
8. If any name scores ≥4 on 6-point framework → Spotlight should appear
9. Closing prompt "Want to go deeper..." should always appear after results
10. Reject 3 times in Direction Round → should trigger seed-word pivot prompt
