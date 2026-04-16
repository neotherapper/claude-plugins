---
name: site-naming
description: >
  This skill should be used when the user asks for help naming a site, product,
  project, startup, or personal brand — or needs to find an available domain.
  Trigger phrases: "find me a domain", "name my project", "site name for",
  "what should I call", "available domains for", "I have an idea, find me a name",
  "domain for [concept]", "naming [project]", "domain for my portfolio",
  "find me a site name", "help me name this". Also triggers when the user describes
  a project idea and mentions needing a web presence.
version: 0.3.0
---

# Site Naming

Help users discover, evaluate, and shortlist available domain names through a structured brand interview, direction round, targeted generation, and live availability + pricing checks.

**Announce at start:** "I'm using the site-naming skill to find the right domain name."

## Checklist

You MUST create a TodoWrite task for each item and complete them in order:

1. Session orientation + project/personal brand detection (Phase 1)
2. Brand interview — 7 questions, one per message (Phase 1)
3. Direction Round — 18 samples, archetype selection (Phase 2)
4. Deep Generation — 15–20 names across selected archetypes (Phase 3)
5. Availability + pricing check with API gate (Phase 4)
6. Results with Source column + conditional Spotlight (Phase 5)
7. Write names.md to project directory (Phase 5)
8. Feedback loop — Wave 2 / Wave 3 / Track B (Phase 6)
9. Post-shortlist checklist (Phase 7)

<HARD-GATE>
Do NOT generate any name candidates until all 7 interview questions have been answered and the brand profile is locked. This applies regardless of how specific or obvious the project description seems.
</HARD-GATE>

## Red Flags — STOP

| Thought | Correct action |
|---------|----------------|
| "The description is clear, I can skip some questions" | Ask all 7 questions, one per message |
| "Let me suggest a few names while the interview runs" | Complete the interview first — then generate |
| "I already know what they want" | Complete the interview first — answers affect archetype weights |
| "This is a personal brand — skip the interview" | Run the personal brand flow, then offer the interview |
| "The user seems impatient, I'll generate early" | Complete the interview first — the wave will be more accurate |
| "I can skip the Direction Round for obvious cases" | Always run Direction Round — it calibrates before expensive generation |

---

## Phase 1: Orient + Interview

### Session Orientation

Check whether `names.md` exists in the current working directory.

**If it exists**, read it and output a session brief before doing anything else:

```
Previous session: [project description from names.md header]
Brand profile: Tone=[X] | Direction=[Y] | Mode=[Z] | Length=[W]
Shortlisted: [name1], [name2], [name3]
Options:
  1. Continue — run Wave 2 or refine shortlist
  2. Start fresh — new interview, new wave
  3. Track B — all previous picks were taken; run fallback strategies
```

Wait for the user's choice before continuing.

- If they choose (1) **Continue**: load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now — both are needed for Wave 2/3 weighting. Then skip to Phase 6.
- If they choose (2) **Start fresh**: proceed with Project File Detection below.
- If they choose (3) **Track B**: load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now, then follow the Track B section. Skip to Phase 6.

**If names.md does not exist**, proceed immediately to Project File Detection.

### Project File Detection

Check for any of these files in the current working directory:
`README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`

If found, offer once: "I noticed you have project files here — want me to read them to better understand what you're building before we start?"

If accepted, read the file(s). Extract: project name, description, key features, target audience. Use this context to pre-fill Q1 of the brand interview.

### Personal Brand Detection

Before running the standard interview, scan the user's description for personal brand signals:
- Keywords: "portfolio", "freelance", "my name", "personal site", "personal website", "my website", "consulting"
- Pattern: a human first/last name as the primary subject

If signals are detected, load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and follow the **Personal Branding Flow** section in that file. Generate and check name patterns from that section, present results, then offer to continue to the standard interview for additional options.

- If user accepts → proceed to Brand Interview (skip Q1 re-entry; use the detected name as Q1 answer)
- If user declines → proceed to Phase 4 to check availability of the personal brand names generated above, then Phase 5 (results), then write names.md

If no signals, proceed to Brand Interview.

### Brand Interview

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` now.

Ask the 7 questions from that file **one per message**. Wait for each answer before asking the next. Never ask multiple questions in a single message.

After Q7, output a summary before proceeding:

```
Brand profile locked:
- Building: [Q1 answer]
- Tone: [A/B/C label]
- Direction: [A/B label]
- Mode: [A/B/C label]
- Length: [A/B label]
- Constraints: [Q6 answer or "none"]
- Vocabulary: [Q7 answer or "none"]
```

**Hard gate:** Do NOT proceed to Phase 2 until all 7 questions are answered and brand profile is locked.

---

## Phase 2: Direction Round

**Purpose:** Calibrate direction before weighted generation. Show the user what each archetype looks like for their project. Collect resonance signal. Gate deep generation on explicit selection.

### How it works

1. Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md`. Generate 2 name candidates per archetype, UNWEIGHTED (equal representation). 8 archetypes × 2 = 16 names. Append 2 wildcards (cross-archetype combinations). Total: 18 candidates. Do NOT check availability yet.

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

5. **Archetype cap:** Maximum 3 archetypes may be selected. If user selects more, respond: "Let's keep it focused — pick your top 3."

**Hard gate:** Do NOT proceed to Phase 3 until user has either (a) selected at least one archetype, (b) provided a seed word, or (c) triggered the forced seed-word pivot after 3 rejections.

**Reference files to load:** `generation-archetypes.md` (before generating samples)

---

## Phase 3: Deep Generation

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now (if not already loaded from Phase 2).

Apply the weighting rules from `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` against the brand profile. Generate **15–20 name candidates** across selected archetypes (max 3) + any seed vocabulary from Q7/pivot.

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` now. (Archetypes 5 and 7 require it regardless of Mode; loading it unconditionally at this step avoids mid-generation gaps.)

**Suffix Family:** If selected, generate the full suffix family exploration block (see `generation-archetypes.md` Suffix Family section): one `-dex` cluster, one `-issimo` cluster, one ccTLD hack cluster — 3–4 names each.

Generate the full candidate list before any availability check. **No availability check yet.**

---

## Phase 4: Availability Check

**API Gate explanation runs HERE** — the user has names in front of them, so the explanation lands with context. Output before running scripts:

```
Before checking these [N] names — I'll use whichever API tier is configured:
- Cloudflare API → confirmed availability + pricing in real-time (best accuracy)
- Porkbun API → confirmed availability, good for .io (Cloudflare doesn't support .io)
- whois fallback → less reliable; .dev domains often show no DNS even when registered

Checking credentials now…
```

Check environment variables before running scripts:

```bash
[[ -n "$CF_API_TOKEN" ]] && echo "CF_API_TOKEN: set" || echo "CF_API_TOKEN: not set"
[[ -n "$CF_ACCOUNT_ID" ]] && echo "CF_ACCOUNT_ID: set" || echo "CF_ACCOUNT_ID: not set"
[[ -n "$PORKBUN_API_KEY" ]] && echo "PORKBUN_API_KEY: set" || echo "PORKBUN_API_KEY: not set"
[[ -n "$PORKBUN_SECRET" ]] && echo "PORKBUN_SECRET: set" || echo "PORKBUN_SECRET: not set"
```

- Both `CF_API_TOKEN` and `CF_ACCOUNT_ID` set → Tier 1 (Cloudflare)
- Both `PORKBUN_API_KEY` and `PORKBUN_SECRET` set → Tier 2 (Porkbun)
- Neither set → load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md`, show setup instructions, then proceed with Tier 3 (whois fallback)

Execute availability check (batch into groups of ≤20 if more than 20 candidates):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh domain1.com domain2.io ... domainN.dev
```

Execute pricing lookup (always runs, no auth needed):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh com io dev app co xyz icu
```

Parse check-domains.sh output (one line per domain):
- `available <domain> <price>` → ✅
- `taken <domain> na` → ❌
- `redemption <domain> na` → ⚠️ (recently expired, elevated price at recovery)
- `unknown <domain> na` → ❓

---

## Phase 5: Results

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` now.

Format results using this structure — note the **Source column** (new). Emit the Top Picks block first, then one table per selected archetype (every candidate appears in its archetype's table, with taken shown as ❌):

```
## Wave [N] Results — [one-line project description]

**Top Picks**
✅ [name].[tld]   $[price]/yr  — [one-sentence rationale]
   [[Registrar] →]([registration_url])

### [Archetype Name]
| Name | Domain | Status | Price | Source |
|------|--------|--------|-------|--------|
| [name] | [domain.tld] | ✅/❌/⚠️/❓ | $[price]/yr | CF/Porkbun/whois/DNS |

### [Next Archetype Name]
| Name | Domain | Status | Price | Source |
|------|--------|--------|-------|--------|
| ... |
```

Source values: `CF` / `Porkbun` / `whois` / `DNS`

Show ⚠️ redemption domains with a note: "recently expired — may cost $80+ to recover at auction".

Generate registration links from registrar-routing.md for each ✅ domain.

### Conditional Spotlight

After the results table, compute a 6-point framework score for each ✅ candidate:

1. **Short enough to be a hashtag** — max 2 syllables ideally (Twitter, Slack, Figma) → 1 point
2. **The "click" moment** — a small insight when name meets product → 1 point
3. **Works in possession** — "my [Name]" sounds natural → 1 point
4. **Creates a social sharing sentence** — "Just checked my [Name] profile" works as a tweet → 1 point
5. **Unique enough to own search** — invented or rare word → 1 point
6. **Satisfying to say aloud** — rhythm, hard consonants, satisfying ending → 1 point

If any candidate scores ≥ 4, output a `---` separator and a deep single-name analysis for the highest-scoring candidate (if tied, pick the shortest domain):

- **The tweet:** exact tweet text a user would send
- **The question that spreads it:** the question people ask that spreads the brand
- **Product fit:** how name maps to the product's core mechanic
- **Cultural resonance:** gaming/dev culture or other community connection
- **The Notion pattern:** how it fits the repurposed-word brand archetype
- **SEO ownership:** why this name wins search
- **Works in every context:** "Check their X" / "my X card" / "I'm on X" / "According to X..."

### Write names.md

Write `names.md` to the current working directory:

```markdown
# Name Shortlist — [project description]
_Generated: [YYYY-MM-DD] | Mode: [mode] | Tone: [tone] | Direction: [direction]_

## Shortlisted
| Name | Price/yr | Status | Source | Rationale |
|------|----------|--------|--------|-----------|
| [name] | $[price] | ✅ available | [CF/Porkbun/whois] | [rationale from conversation] |

## Considered / Taken
| Name | Status | Source | Alternative |
|------|--------|--------|-------------|
| [name] | ❌ taken | [source] | [alternative if known] |
| [name] | ⚠️ redemption | [source] | recently expired — elevated price |

## Brand Interview
- Building: [Q1]
- Tone: [Q2 answer]
- Direction: [Q3 answer]
- Mode: [Q4 answer]
- Length: [Q5 answer]
- Constraints: [Q6 answer]
- Vocabulary: [Q7 answer]
```

Populate Shortlisted with the top 3–5 available names. Populate the Rationale column with the verbatim "Why" string from the conversation output.

### Closing Prompt (HARD REQUIREMENT)

This prompt MUST always appear after results — it is the Wave 2 trigger:

```
[N] of [Y] checked available. Want to go deeper on any of these, or start Wave 2?
```

---

## Phase 6: Wave 2+

Present wave output. Wait for the user's response.

**User selects specific names:** Add them to the Shortlisted table in names.md.

**User requests Wave 2:** Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` (needed for weighting rules after context compaction). Generate 20+ new candidates refined toward preferences stated ("more like X", "avoid Y"). Repeat Phases 3–5. No candidate from Wave 2 may repeat a Wave 1 name.

**User requests Wave 3 / "check more TLDs" / "deep scan":** Output a scope warning first:

```
Wave 3 will scan 1,441+ TLDs for your top 5 base words — this may take several minutes. Proceed?
```

Wait for confirmation. Then load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and follow the **Wave 3** section. Apply all 10 techniques exhaustively to every synonym of the core concept.

**All top picks are taken:** Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and follow the **Track B** section. Run the 4 fallback strategies in order: close variations → synonym exploration → creative reconstruction → domain hacks. Stop as soon as 5+ available options are found. If all 4 strategies complete with fewer than 5 available, show what was found and offer: "Want to broaden constraints, or start fresh with a different direction?"

---

## Phase 7: Post-Shortlist

After the user confirms their final shortlist, load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md`. Work through each section in order: pronunciation test, social handle check, trademark check, registration strategy, names.md update. Report findings after each section before proceeding to the next.

---

## Reference Files

| File | Load when |
|------|-----------|
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` | Before Q1 (Phase 1), personal brand flow (Phase 1), or Wave 2 (Phase 6 — context compaction safeguard) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` | Before Direction Round (Phase 2), Deep Generation (Phase 3), Wave 3, or Track B |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` | Before Deep Generation (Phase 3) — always; archetypes 5 and 7 require it regardless of Mode |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` | When formatting results (Phase 5) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md` | When no API env vars detected (Phase 4) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md` | After user confirms final shortlist (Phase 7) |

## Scripts

| Script | Purpose |
|--------|---------|
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh` | 3-tier checker: CF → Porkbun → whois (.io routes to Porkbun automatically) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh` | Porkbun no-auth TLD pricing, always runs |

Both scripts must be executable: `chmod +x ${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/*.sh`

## Example

See `examples/example-session.md` for a complete run: developer productivity SaaS → 7-question interview → Direction Round → Deep Generation → results with Spotlight → final names.md.
