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
