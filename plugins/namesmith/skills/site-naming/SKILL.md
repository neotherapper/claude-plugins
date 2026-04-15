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
version: 0.2.0
---

# Site Naming

Help users discover, evaluate, and shortlist available domain names through a structured brand interview, multi-archetype generation, and live availability + pricing checks.

**Announce at start:** "I'm using the site-naming skill to find the right domain name."

## Checklist

You MUST create a TodoWrite task for each item and complete them in order:

1. Session orientation — resume or start fresh (Step 0)
2. Project file detection (Step 1)
3. Personal brand detection (Step 2)
4. Brand interview — 6 questions, one per message (Step 3)
5. Wave 1 generation — 25–35 names across 7 archetypes (Step 4)
6. Availability + pricing check (Step 5)
7. Format output with registration links (Step 6)
8. Write names.md to project directory (Step 7)
9. Feedback loop — Wave 2 / Wave 3 / Track B (Step 8)
10. Post-shortlist checklist (Step 9)

<HARD-GATE>
Do NOT generate any name candidates until all 6 interview questions have been answered and the brand profile is locked. This applies regardless of how specific or obvious the project description seems.
</HARD-GATE>

## Red Flags — STOP

| Thought | Correct action |
|---------|----------------|
| "The description is clear, I can skip some questions" | Ask all 6 questions, one per message |
| "Let me suggest a few names while the interview runs" | Complete the interview first — then generate |
| "I already know what they want" | Complete the interview first — answers affect archetype weights |
| "This is a personal brand — skip the interview" | Run the personal brand flow, then offer the interview |
| "The user seems impatient, I'll generate early" | Complete the interview first — the wave will be more accurate |

---

## Step 0: Session Orientation

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

- If they choose (1) **Continue**: load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now — both are needed for Wave 2/3 weighting. Then skip to Step 8.
- If they choose (2) **Start fresh**: proceed from Step 1 as normal.
- If they choose (3) **Track B**: load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now, then follow the Track B section. Skip to Step 8.

**If names.md does not exist**, proceed immediately to Step 1.

## Step 1: Project File Detection

Check for any of these files in the current working directory:
`README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`

If found, offer once: "I noticed you have project files here — want me to read them to better understand what you're building before we start?"

If accepted, read the file(s). Extract: project name, description, key features, target audience. Use this context to pre-fill Q1 of the brand interview.

## Step 2: Personal Brand Detection

Before running the standard interview, scan the user's description for personal brand signals:
- Keywords: "portfolio", "freelance", "my name", "personal site", "personal website", "my website", "consulting"
- Pattern: a human first/last name as the primary subject

If signals are detected, load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and follow the **Personal Branding Flow** section in that file. Generate and check name patterns from that section, present results, then offer to continue to the standard interview for additional options.

- If user accepts → proceed to Step 3 (skip Q1 re-entry; use the detected name as Q1 answer)
- If user declines → proceed to Step 5 to check availability of the personal brand names generated above, then Step 6 (format output), then Step 7 (write names.md)

If no signals, proceed to Step 3.

## Step 3: Brand Interview

Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` now.

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

Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now.

Apply the weighting rules from `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` against the brand profile. Generate 25–35 name candidates across all 7 archetypes weighted accordingly.

Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` now. (Archetypes 5 and 7 require it regardless of Mode; loading it unconditionally at this step avoids mid-generation gaps.)

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
[[ -n "$CF_API_TOKEN" ]] && echo "CF_API_TOKEN: set" || echo "CF_API_TOKEN: not set"
[[ -n "$CF_ACCOUNT_ID" ]] && echo "CF_ACCOUNT_ID: set" || echo "CF_ACCOUNT_ID: not set"
[[ -n "$PORKBUN_API_KEY" ]] && echo "PORKBUN_API_KEY: set" || echo "PORKBUN_API_KEY: not set"
[[ -n "$PORKBUN_SECRET" ]] && echo "PORKBUN_SECRET: set" || echo "PORKBUN_SECRET: not set"
```

- Both `CF_API_TOKEN` and `CF_ACCOUNT_ID` set → Tier 1 (Cloudflare)
- Both `PORKBUN_API_KEY` and `PORKBUN_SECRET` set → Tier 2 (Porkbun)
- Neither set → load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md`, show setup instructions, then proceed with Tier 3 (whois fallback)

Execute availability check (batch into groups of ≤20 if more than 20 candidates):

```bash
\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh domain1.com domain2.io ... domainN.dev
```

Execute pricing lookup (always runs, no auth needed):

```bash
\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh com io dev app co xyz icu
```

Parse check-domains.sh output (one line per domain):
- `available <domain> <price>` → ✅
- `taken <domain> na` → ❌
- `redemption <domain> na` → ⚠️ (recently expired, elevated price at recovery)
- `unknown <domain> na` → ❓

## Step 6: Format Output

Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` now.

Format Wave output using this exact structure:

```
## Wave [N] Results — [one-line project description]

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

Populate Shortlisted with the top 3–5 available names. Populate the Rationale column with the verbatim "Why" string from the conversation output.

## Step 8: Feedback Loop

Present wave output. Wait for the user's response.

**User selects specific names:** Add them to the Shortlisted table in names.md.

**User requests Wave 2:** Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` (needed for weighting rules after context compaction). Generate 20+ new candidates refined toward preferences stated ("more like X", "avoid Y"). Repeat Steps 4–7. No candidate from Wave 2 may repeat a Wave 1 name.

**User requests Wave 3 / "check more TLDs" / "deep scan":** Output a scope warning first:

```
Wave 3 will scan 1,441+ TLDs for your top 5 base words — this may take several minutes. Proceed?
```

Wait for confirmation. Then load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and follow the **Wave 3** section. Apply all 10 techniques exhaustively to every synonym of the core concept.

**All top picks are taken:** Load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and follow the **Track B** section. Run the 4 fallback strategies in order: close variations → synonym exploration → creative reconstruction → domain hacks. Stop as soon as 5+ available options are found. If all 4 strategies complete with fewer than 5 available, show what was found and offer: "Want to broaden constraints, or start fresh with a different direction?"

## Step 9: Post-Shortlist Checklist

After the user confirms their final shortlist, load `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md`. Work through each section in order: pronunciation test, social handle check, trademark check, registration strategy, names.md update. Report findings after each section before proceeding to the next.

---

## Reference Files

| File | Load when |
|------|-----------|
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` | Before Q1 (Step 3), personal brand flow (Step 2), or Wave 2 (Step 8 — context compaction safeguard) |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` | Before Wave 1 generation (Step 4), Wave 3, or Track B |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` | Before Wave 1 generation (Step 4) — always; archetypes 5 and 7 require it regardless of Mode |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` | When formatting Wave output (Step 6) |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md` | When no API env vars detected (Step 5) |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md` | After user confirms final shortlist (Step 9) |

## Scripts

| Script | Purpose |
|--------|---------|
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh` | 3-tier checker: CF → Porkbun → whois |
| `\${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh` | Porkbun no-auth TLD pricing, always runs |

Both scripts must be executable: `chmod +x \${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/*.sh`

## Example

See `examples/example-session.md` for a complete run: developer productivity SaaS → 6-question interview → Wave 1 → Wave 2 refinement → final names.md.
