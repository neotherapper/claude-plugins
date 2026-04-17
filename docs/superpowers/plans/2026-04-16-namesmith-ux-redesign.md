# Namesmith UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Direction Round between brand interview and deep generation, fix two check-domains.sh bugs, add Q7 vocabulary mining to the interview, and add Suffix Family as the 8th generation archetype.

**Architecture:** Four files change. The script fixes are independent of the content file changes and can be done in any order. SKILL.md rewrite is last — it references the updated brand-interview.md and generation-archetypes.md content and must be consistent with both.

**Tech Stack:** Bash (check-domains.sh), Markdown (SKILL.md, brand-interview.md, generation-archetypes.md), jq, curl

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `plugins/namesmith/skills/site-naming/scripts/check-domains.sh` | Modify | Fix `.result[]` → `.result.domains[]` on line 57; add `.io` split routing in main block |
| `plugins/namesmith/skills/site-naming/references/brand-interview.md` | Modify | Add Q7 after Q6; add Q7 row to weighting rules table |
| `plugins/namesmith/skills/site-naming/references/generation-archetypes.md` | Modify | Add section 8 (Suffix Family); update Wave 1 default distribution note |
| `plugins/namesmith/skills/site-naming/SKILL.md` | Rewrite | 9-step flow → 7-phase flow with Direction Round, inline API Gate, conditional Spotlight, hard gates |

---

## Task 1: Fix check-domains.sh — CF API jq path

**Files:**
- Modify: `plugins/namesmith/skills/site-naming/scripts/check-domains.sh:57`
- Create: `plugins/namesmith/skills/site-naming/scripts/test-cf-path.sh` (temp test, deleted after passing)

**The bug:** Line 57 uses `.result[]` but the Cloudflare Registrar API returns `.result.domains[]`. This causes jq to emit nothing, the `check_cloudflare` function outputs zero lines, and the script silently falls through — appearing to check domains but producing no results.

- [ ] **Step 1: Write a failing test**

Create `plugins/namesmith/skills/site-naming/scripts/test-cf-path.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Mock CF API response — this is what the real API actually returns
mock_response='{"success":true,"result":{"domains":[{"name":"example.com","available":true,"price":8.03},{"name":"taken.com","available":false,"price":null}]}}'

# Test the CURRENT (broken) jq path
broken_output=$(echo "$mock_response" | jq -r '.result[] | "\(.available | if . then "available" else "taken" end) \(.name) \(.price // "na")"' 2>/dev/null || true)

if [[ -z "$broken_output" ]]; then
  echo "CONFIRMED BROKEN: .result[] produces no output on real CF response"
else
  echo "UNEXPECTED: .result[] produced output — test premise wrong"
  exit 1
fi

# Test the FIXED jq path
fixed_output=$(echo "$mock_response" | jq -r '.result.domains[] | "\(.available | if . then "available" else "taken" end) \(.name) \(.price // "na")"')

expected_line1="available example.com 8.03"
expected_line2="taken taken.com na"

if [[ "$(echo "$fixed_output" | head -1)" == "$expected_line1" ]] && \
   [[ "$(echo "$fixed_output" | tail -1)" == "$expected_line2" ]]; then
  echo "PASS: .result.domains[] produces correct output"
else
  echo "FAIL: unexpected output:"
  echo "$fixed_output"
  exit 1
fi
```

```bash
chmod +x plugins/namesmith/skills/site-naming/scripts/test-cf-path.sh
```

- [ ] **Step 2: Run test to confirm the bug exists**

```bash
bash plugins/namesmith/skills/site-naming/scripts/test-cf-path.sh
```

Expected output:
```
CONFIRMED BROKEN: .result[] produces no output on real CF response
PASS: .result.domains[] produces correct output
```

- [ ] **Step 3: Apply the fix**

In `plugins/namesmith/skills/site-naming/scripts/check-domains.sh`, change line 57:

Old:
```bash
      echo "$response" | jq -r '.result[] | "\(.available | if . then "available" else "taken" end) \(.name) \(.price // "na")"'
```

New:
```bash
      echo "$response" | jq -r '.result.domains[] | "\(.available | if . then "available" else "taken" end) \(.name) \(.price // "na")"'
```

- [ ] **Step 4: Verify fix applies cleanly**

```bash
grep -n 'result\.' plugins/namesmith/skills/site-naming/scripts/check-domains.sh | grep -v "^#"
```

Expected: line 57 now reads `.result.domains[]`

- [ ] **Step 5: Delete temp test file and commit**

```bash
rm plugins/namesmith/skills/site-naming/scripts/test-cf-path.sh
git add plugins/namesmith/skills/site-naming/scripts/check-domains.sh
git commit -m "fix(namesmith): fix CF API jq path .result[] → .result.domains[]"
```

---

## Task 2: Fix check-domains.sh — .io routing

**Files:**
- Modify: `plugins/namesmith/skills/site-naming/scripts/check-domains.sh:152-182` (main routing block)
- Create: `plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh` (temp test, deleted after passing)

**The bug:** The main routing logic passes ALL domains (including `.io`) to the Cloudflare API when CF credentials are set. CF silently fails `.io` lookups (it doesn't support that TLD), the function outputs `unknown`, and the script exits with code 1. The user sees `❓` for all `.io` candidates even with valid credentials.

**The fix:** Split the domain list before routing. `.io` domains always go to Porkbun (if creds present) or whois. All other domains use the existing CF → Porkbun → whois logic.

- [ ] **Step 1: Write a failing test**

Create `plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/check-domains.sh"

echo "=== Test: .io domains bypass CF when both CF+Porkbun creds set ==="

# Unset all credentials — test that .io goes to whois path (not CF)
unset CF_API_TOKEN CF_ACCOUNT_ID PORKBUN_API_KEY PORKBUN_SECRET 2>/dev/null || true

# With no creds, both .io and .com should use whois — result is "unknown" or "available"
# We just verify the script doesn't crash and returns one line per domain
output=$("$CHECK_SCRIPT" kredit.io example.com 2>/dev/null || true)
line_count=$(echo "$output" | wc -l | tr -d ' ')

if [[ "$line_count" -eq 2 ]]; then
  echo "PASS: 2 domains → 2 output lines (no crash)"
else
  echo "FAIL: expected 2 lines, got ${line_count}"
  echo "Output: $output"
  exit 1
fi

echo "=== Test: .io separated from non-.io in output (order preserved) ==="
# Verify first line contains kredit.io and second contains example.com
first_domain=$(echo "$output" | head -1 | awk '{print $2}')
second_domain=$(echo "$output" | tail -1 | awk '{print $2}')

# After the fix, .io is processed first in the new split loop
# Both domains must appear exactly once in output
if echo "$output" | grep -q "kredit.io" && echo "$output" | grep -q "example.com"; then
  echo "PASS: both domains appear in output"
else
  echo "FAIL: missing domain in output"
  echo "Output: $output"
  exit 1
fi

echo "ALL ROUTING TESTS PASSED"
```

```bash
chmod +x plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh
```

- [ ] **Step 2: Run test to establish baseline**

```bash
bash plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh
```

Expected: `PASS: 2 domains → 2 output lines` and `PASS: both domains appear in output` (whois fallback handles both correctly today, but the CF tier silently drops .io — this test validates the routing split works after the fix)

- [ ] **Step 3: Apply the .io routing fix**

Replace the entire main routing block (lines 152–182) in `plugins/namesmith/skills/site-naming/scripts/check-domains.sh`:

Old block:
```bash
all_unknown=true

if [[ -n "${CF_API_TOKEN:-}" && -n "${CF_ACCOUNT_ID:-}" ]]; then
  # Tier 1: Cloudflare (batch)
  results=$(check_cloudflare "${DOMAINS[@]}")
  echo "$results"
  if [[ -n "$results" ]] && echo "$results" | grep -qv "^unknown"; then
    all_unknown=false
  fi

elif [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
  # Tier 2: Porkbun (per-domain)
  for domain in "${DOMAINS[@]}"; do
    result=$(check_porkbun "$domain")
    echo "$result"
    if [[ "$result" != unknown* ]]; then
      all_unknown=false
    fi
  done

else
  # Tier 3: whois fallback (per-domain)
  for domain in "${DOMAINS[@]}"; do
    result=$(check_whois "$domain")
    echo "$result"
    if [[ "$result" != unknown* ]]; then
      all_unknown=false
    fi
  done
fi
```

New block:
```bash
# Split domains: .io always bypasses Cloudflare (CF doesn't support .io TLD)
io_domains=()
other_domains=()
for domain in "${DOMAINS[@]}"; do
  if [[ "$domain" == *.io ]]; then
    io_domains+=("$domain")
  else
    other_domains+=("$domain")
  fi
done

all_unknown=true

# Route .io domains — Porkbun if available, else whois
for domain in "${io_domains[@]}"; do
  if [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
    result=$(check_porkbun "$domain")
  else
    result=$(check_whois "$domain")
  fi
  echo "$result"
  if [[ "$result" != unknown* ]]; then
    all_unknown=false
  fi
done

# Route all other domains through CF → Porkbun → whois
if [[ ${#other_domains[@]} -gt 0 ]]; then
  if [[ -n "${CF_API_TOKEN:-}" && -n "${CF_ACCOUNT_ID:-}" ]]; then
    # Tier 1: Cloudflare (batch)
    results=$(check_cloudflare "${other_domains[@]}")
    echo "$results"
    if [[ -n "$results" ]] && echo "$results" | grep -qv "^unknown"; then
      all_unknown=false
    fi
  elif [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
    # Tier 2: Porkbun (per-domain)
    for domain in "${other_domains[@]}"; do
      result=$(check_porkbun "$domain")
      echo "$result"
      if [[ "$result" != unknown* ]]; then
        all_unknown=false
      fi
    done
  else
    # Tier 3: whois fallback (per-domain)
    for domain in "${other_domains[@]}"; do
      result=$(check_whois "$domain")
      echo "$result"
      if [[ "$result" != unknown* ]]; then
        all_unknown=false
      fi
    done
  fi
fi
```

- [ ] **Step 4: Run test again to verify fix**

```bash
bash plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh
```

Expected: `ALL ROUTING TESTS PASSED`

- [ ] **Step 5: Delete temp test file and commit**

```bash
rm plugins/namesmith/skills/site-naming/scripts/test-io-routing.sh
git add plugins/namesmith/skills/site-naming/scripts/check-domains.sh
git commit -m "fix(namesmith): route .io domains to Porkbun, bypass Cloudflare API"
```

---

## Task 3: Add Q7 vocabulary mining to brand-interview.md

**Files:**
- Modify: `plugins/namesmith/skills/site-naming/references/brand-interview.md`

- [ ] **Step 1: Add Q7 after Q6 in the Standard Interview section**

In `plugins/namesmith/skills/site-naming/references/brand-interview.md`, after the Q6 block (after the closing ` ``` ` of the Q6 question), add:

```markdown
### Q7 — Vocabulary Mining
```
Any words from any domain — a brand, a place, a concept — that you love the sound or feel of? (e.g. "massimo", "Pokédex", "notion", anything)
```
*Optional but high-value. If provided:*
- *Extract the word class (Italian superlative, English single-word, portmanteau, ccTLD fragment, etc.)*
- *Record in brand profile as `Vocabulary: [word] ([class])`*
- *In Phase 2 Direction Round: include one sample from the suffix/etymology family of that word class in the Suffix Family archetype row*
- *In Phase 3 Deep Generation: if Suffix Family archetype is selected, use this word as the primary seed for the full suffix family exploration block*
```

- [ ] **Step 2: Add Q7 row to Weighting Rules table**

In the Weighting Rules section, after the last table row (`| Q5=A | Short & Punchy ×2...`), add:

```markdown
| Q7 provided | In Direction Round: bias Suffix Family samples toward that word's family; in Deep Generation: anchor ≥40% of Suffix Family output to that seed |
```

Also update the final line of the weighting rules:
Old:
```
Default (no strong signal): distribute evenly across all 7 archetypes.
```
New:
```
Default (no strong signal): distribute evenly across all 8 archetypes.
```

- [ ] **Step 3: Verify changes**

```bash
grep -c "Q7" plugins/namesmith/skills/site-naming/references/brand-interview.md
```

Expected: `3` (Q7 heading, Q7 in weighting table, Q7 reference in default note area)

- [ ] **Step 4: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/brand-interview.md
git commit -m "feat(namesmith): add Q7 vocabulary mining to brand interview"
```

---

## Task 4: Add Suffix Family as 8th archetype to generation-archetypes.md

**Files:**
- Modify: `plugins/namesmith/skills/site-naming/references/generation-archetypes.md`

- [ ] **Step 1: Add Section 8 after the existing Section 7**

In `plugins/namesmith/skills/site-naming/references/generation-archetypes.md`, after the closing `---` of Section 7 (Thematic TLD Play), add:

```markdown
### 8. Suffix Family Exploration

Names built by applying a recognisable suffix family to a concept word. Produces clusters of related names that share a sound identity without being identical.

**When to use:** When the product has a strong category word (index, rank, code, build, dev) OR when Q7 vocabulary hints at a suffix family (Italian → -issimo, Pokédex → -dex, Bauhaus → -haus).

**Sub-families to explore:**

| Sub-family | Pattern | Examples |
|-----------|---------|---------|
| -dex | Pokédex model — catalog/index | `coderdex`, `devdex`, `makedex`, `hackdex` |
| -haus | Bauhaus — school of greats | `coderhaus`, `devhaus`, `builderhaus` |
| -eum | museum — archive of the greats | `deveum`, `codereum`, `codeeum` |
| -issimo | Italian superlative | `devissimo`, `codeissimo`, `hackissimo`, `buildissimo` |
| massi- | massimo root as prefix | `massidev`, `massicoder`, `massistack` |
| primo | Italian "first/best" | `primo.dev`, `primodev`, `devprimo` |
| ccTLD hack | [base].er, [base].rs, [base].ng | `cod.er`, `build.rs`, `hack.er`, `mak.er` |

**How to generate:** Identify the strongest 1–2 concept words. Apply each relevant sub-family. Generate 3–4 variants per sub-family. Note: `-dex` and `-ex` families are especially productive for directory/ranking products (the compressed "index" metaphor). ccTLD hacks have high take rates — generate 8–10 to compensate.

**Direction Round sample (2 names max):** pick one from the `-dex` sub-family and one from the `-issimo` sub-family.

**Deep Generation full block (when archetype is selected):** generate all sub-families relevant to the concept word. If a ccTLD hack sub-family is included, generate 8–10 variants.

---
```

- [ ] **Step 2: Update Wave 1 default distribution note**

In the Wave System section, change the Wave 1 description line:

Old:
```
Default (no strong signal): distribute evenly across all 7 archetypes.
```

New:
```
Default (no strong signal): distribute evenly across all 8 archetypes.
```

Also update the Wave 1 opening sentence in the Wave System section:

Old:
```
Generate 25–35 candidates across all 7 archetypes.
```

New:
```
Generate 25–35 candidates across all 8 archetypes.
```

- [ ] **Step 3: Verify section 8 exists**

```bash
grep -c "Suffix Family" plugins/namesmith/skills/site-naming/references/generation-archetypes.md
```

Expected: at least `4` occurrences (section heading, When to use, Direction Round note, Deep Generation note)

- [ ] **Step 4: Commit**

```bash
git add plugins/namesmith/skills/site-naming/references/generation-archetypes.md
git commit -m "feat(namesmith): add Suffix Family as 8th generation archetype"
```

---

## Task 5: Rewrite SKILL.md — 7-phase flow

**Files:**
- Modify: `plugins/namesmith/skills/site-naming/SKILL.md` (full rewrite)

This is the largest task. The new SKILL.md replaces the existing 9-step flow with a 7-phase flow. The complete new content is specified below — write it exactly.

- [ ] **Step 1: Write the new SKILL.md**

Replace the entire contents of `plugins/namesmith/skills/site-naming/SKILL.md` with:

````markdown
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

Help users discover, evaluate, and shortlist available domain names through a structured brand interview, a direction round that calibrates archetype selection before deep generation, and live availability + pricing checks.

**Announce at start:** "I'm using the site-naming skill to find the right domain name."

## Checklist

You MUST create a TodoWrite task for each item and complete them in order:

1. Phase 1: Orient + Interview — resume or start fresh, project detection, personal brand detection, 7-question brand interview
2. Phase 2: Direction Round — 2 unweighted samples × 8 archetypes + 2 wildcards, archetype/seed selection, up to 3 rejection loops
3. Phase 3: Deep Generation — weighted 15–20 names across selected archetypes (max 3)
4. Phase 4: Availability Check — API gate explanation, credential check, CF/Porkbun/whois
5. Phase 5: Results — 5-column table, conditional Spotlight, names.md write, closing prompt
6. Phase 6: Wave 2 — if user requests, generate refined wave
7. Phase 7: Post-shortlist — pronunciation, trademark, registration

<HARD-GATE>
Do NOT start Phase 2 (Direction Round) until all 7 brand interview questions have been answered and the brand profile is locked.
Do NOT start Phase 3 (Deep Generation) until the user has explicitly selected archetypes, provided a seed word, or triggered the forced pivot after 3 Direction Round rejections.
</HARD-GATE>

## Red Flags — STOP

| Thought | Correct action |
|---------|----------------|
| "The description is clear, I can skip some questions" | Ask all 7 questions, one per message |
| "Let me suggest a few names while the interview runs" | Complete the interview first — then run Phase 2 |
| "I already know what they want" | Complete the interview first — answers affect archetype weights |
| "This is a personal brand — skip the interview" | Run the personal brand flow, then offer the interview |
| "The user seems impatient, I'll generate early" | Complete the interview first — Direction Round calibrates before deep generation |
| "I'll skip the Direction Round, I know the archetype" | The Direction Round is not optional — it surfaces resonance before weighted generation |

---

## Phase 1: Orient + Interview

### Step 0: Session Orientation

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
- If they choose (2) **Start fresh**: proceed from Step 1 as normal.
- If they choose (3) **Track B**: load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now, then follow the Track B section. Skip to Phase 6.

**If names.md does not exist**, proceed immediately to Step 1.

### Step 1: Project File Detection

Check for any of these files in the current working directory:
`README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`

If found, offer once: "I noticed you have project files here — want me to read them to better understand what you're building before we start?"

If accepted, read the file(s). Extract: project name, description, key features, target audience. Use this context to pre-fill Q1 of the brand interview.

### Step 2: Personal Brand Detection

Before running the standard interview, scan the user's description for personal brand signals:
- Keywords: "portfolio", "freelance", "personal site", "my name", "my website", "consulting"
- Pattern: a human first/last name as the primary subject

If signals are detected, load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and follow the **Personal Branding Flow** section. Generate and check name patterns, present results, then offer to continue to the standard interview for additional options.

- If user accepts → proceed to Step 3 (skip Q1 re-entry; use the detected name as Q1 answer)
- If user declines → proceed to Phase 4 to check availability of the personal brand names, then Phase 5, then Phase 7

If no signals, proceed to Step 3.

### Step 3: Brand Interview

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` now.

Ask the 7 questions from that file **one per message**. Wait for each answer before asking the next.

After Q7, output a locked profile before proceeding:

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

---

## Phase 2: Direction Round

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now.

Generate 2 candidates per archetype, **UNWEIGHTED** (equal representation regardless of brand profile). 8 archetypes × 2 = 16 names. Add 2 Wildcards (cross-archetype combinations; use Q7 vocabulary if provided). Total: 18 candidates.

Do NOT check availability during the Direction Round.

Present as a compact table:

```
## Direction Round — which of these feels closest?

**Short & Punchy**         `[name1]` · `[name2]`
**Descriptive**            `[name1]` · `[name2]`
**Abstract/Brandable**     `[name1]` · `[name2]`
**Playful/Clever**         `[name1]` · `[name2]`
**Domain Hacks**           `[name1]` · `[name2]`
**Compound/Mashup**        `[name1]` · `[name2]`
**Thematic TLD Play**      `[name1]` · `[name2]`
**Suffix Family**          `[name1]` · `[name2]`
─────────────────────────────────────────
**Wildcards**              `[name1]` · `[name2]`

Which direction resonates — or is there a word from any domain you want to explore?
```

Present exactly 3 numbered options (no prose):
```
1. Pick archetypes (e.g. "1, 3, 5" or archetype names)
2. Give me a seed word to explore
3. None of these — show me different samples
```

**Branch A — Archetype selection:** User picks 1–3 archetypes. If user selects more than 3: "Let's keep it focused — pick your top 3." Record selection. Proceed to Phase 3.

**Branch B — Seed word:** User provides a word. Record as seed vocabulary alongside Q7 answer. Proceed to Phase 3 with seed word as primary generation anchor.

**Branch C — Rejection loop:**
- Increment `rejectionCount` (starts at 0, increments on each option-3 response)
- If `rejectionCount` < 3: regenerate 18 fresh samples across all 8 archetypes. Present the same 3 options again.
- If `rejectionCount` == 3: output "Let's try a different approach — give me 2 words you find interesting from any domain (a place, a brand, a concept)." Take the response as seed words. Proceed to Phase 3.

<HARD-GATE>
Do NOT proceed to Phase 3 until Branch A, B, or the forced pivot after rejectionCount==3 has resolved.
</HARD-GATE>

---

## Phase 3: Deep Generation

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` and `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` now (context compaction safeguard).

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` now (required for archetypes 5, 7, and Suffix Family ccTLD cluster).

Apply the weighting rules from `brand-interview.md` to the selected archetypes only (max 3). Generate 15–20 name candidates total.

**If Suffix Family archetype is selected**, generate the full suffix family exploration block:
- One `-dex` cluster: 3–4 names (e.g. `coderdex`, `devdex`, `makedex`)
- One `-issimo` cluster: 3–4 names (e.g. `devissimo`, `codeissimo`, `buildissimo`)
- One ccTLD hack cluster: 8–10 names (e.g. `cod.er`, `build.rs`, `hack.er`, `mak.er`) — generate more to compensate for high take rates

If a seed word was provided (Q7 or Direction Round), anchor at least 40% of generated names to that word's suffix family or etymology cluster.

Generate the full candidate list before proceeding. Do NOT check availability yet.

---

## Phase 4: Availability Check

Before running any scripts, output this explanation:

```
Before checking these [N] names — here's which API tier I'll use:
- Cloudflare API → confirmed availability + pricing (best accuracy; doesn't support .io)
- Porkbun API → confirmed availability; handles .io domains; fallback for non-.io
- whois fallback → less reliable; .dev domains often show no DNS even when registered

Checking credentials now…
```

Check environment variables:

```bash
[[ -n "$CF_API_TOKEN" ]] && echo "CF_API_TOKEN: set" || echo "CF_API_TOKEN: not set"
[[ -n "$CF_ACCOUNT_ID" ]] && echo "CF_ACCOUNT_ID: set" || echo "CF_ACCOUNT_ID: not set"
[[ -n "$PORKBUN_API_KEY" ]] && echo "PORKBUN_API_KEY: set" || echo "PORKBUN_API_KEY: not set"
[[ -n "$PORKBUN_SECRET" ]] && echo "PORKBUN_SECRET: set" || echo "PORKBUN_SECRET: not set"
```

If neither CF nor Porkbun credentials are set: load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md`, show setup instructions, then continue with whois fallback.

Execute availability check (batch into groups of ≤20 if more than 20 candidates):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh domain1.com domain2.io ... domainN.dev
```

Note: The script automatically routes `.io` domains to Porkbun, bypassing Cloudflare (which does not support `.io`).

Execute pricing lookup (always runs, no auth needed):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh com io dev app co xyz icu
```

Parse check-domains.sh output:
- `available <domain> <price>` → ✅
- `taken <domain> na` → ❌
- `redemption <domain> na` → ⚠️ (recently expired, elevated price at recovery)
- `unknown <domain> na` → ❓

---

## Phase 5: Results

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` now.

Format Wave output:

```
## Wave [N] Results — [one-line project description]

**Top Picks**
✅ [name].[tld]   $[price]/yr  — [one-sentence rationale]
   [[Registrar] →]([registration_url])

[Per-archetype sections with available names; taken names shown inline as ❌]

---
| Name | Domain | Status | Price | Source |
|------|--------|--------|-------|--------|
| [name] | [domain] | ✅ available | $[price]/yr | CF |
| [name] | [domain] | ❌ taken | — | CF |
| [name] | [domain] | ✅ available | $[price]/yr | Porkbun |

TLD summary: .com [X available] | .io [X available] | .dev [X available] | hacks [X available]
```

Source column values: `CF` / `Porkbun` / `whois` / `DNS`

Show ⚠️ redemption domains with note: "recently expired — may cost $80+ to recover at auction".

**Conditional Spotlight:** After the table, score each ✅ candidate against the 6-point framework:

1. Short enough to be a hashtag (max 2 syllables ideally) → 1 pt
2. Has a "click" moment — small insight when name meets product → 1 pt
3. Works in possession — "my [Name]" sounds natural → 1 pt
4. Creates a social sharing sentence — "Just checked my [Name] profile" reads as a real tweet → 1 pt
5. Unique enough to own search — invented or rare word → 1 pt
6. Satisfying to say aloud — rhythm, hard consonants, satisfying ending → 1 pt

If any ✅ candidate scores ≥ 4: output `---` separator, then the deep analysis for the single highest-scoring candidate (ties broken by shortest domain):

```
---

**`[name]` — [availability] [price]**

This is [position — strongest, most surprising, etc.].

- **The tweet**: "[exact tweet text a user would send]"
- **The question that spreads it**: "[question people ask that spreads the brand]"
- **The product fit**: [how name maps to the product's core mechanic]
- **Cultural resonance**: [gaming/dev culture or community connection]
- **The Notion pattern**: [how it fits the repurposed-word brand archetype]
- **SEO ownership**: [why this name wins search]
- **Works in every context**: "Check their [Name]", "my [Name] card", "I'm on [Name]", "According to [Name]..."
```

Write `names.md` to the current working directory:

```markdown
# Name Shortlist — [project description]
_Generated: [YYYY-MM-DD] | Mode: [mode] | Tone: [tone] | Direction: [direction]_

## Shortlisted
| Name | Price/yr | Status | Rationale |
|------|----------|--------|-----------|
| [name] | $[price] | ✅ available | [rationale] |

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
- Vocabulary: [Q7 answer]
```

**Closing prompt (always appears):**
```
[N] of [Y] checked available. Want to go deeper on any of these, or start Wave 2?
```

---

## Phase 6: Wave 2

Triggered when user responds to the Phase 5 closing prompt requesting Wave 2 or deeper exploration.

Load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` and `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` (context compaction safeguard).

Generate 20+ new candidates refined toward stated preferences ("more like X", "avoid Y"). No candidate from Wave 2 may repeat a Wave 1 name. Repeat Phases 4–5 for the new batch.

**Wave 3 / deep scan:** Output scope warning first:
```
Wave 3 will scan 1,441+ TLDs for your top 5 base words — this may take several minutes. Proceed?
```
Wait for confirmation. Then load `generation-archetypes.md` and follow the Wave 3 section.

**All top picks taken:** Follow the Track B section in `generation-archetypes.md`. Run 4 fallback strategies in order; stop when 5+ available options are found.

---

## Phase 7: Post-Shortlist

After the user confirms their final shortlist, load `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md`. Work through each section in order: pronunciation test, social handle check, trademark check, registration strategy, names.md update. Report findings after each section before proceeding to the next.

---

## Reference Files

| File | Load when |
|------|-----------|
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/brand-interview.md` | Before Q1 (Step 3), personal brand flow (Step 2), Deep Generation (Phase 3 — compaction safeguard), or Wave 2 (Phase 6) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/generation-archetypes.md` | Before Direction Round (Phase 2), Deep Generation (Phase 3), Wave 2/3, or Track B |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/tld-catalog.md` | Before Deep Generation (Phase 3) — always; archetypes 5, 7, and Suffix Family require it |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/registrar-routing.md` | When formatting Wave output (Phase 5) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/api-setup.md` | When no API env vars detected (Phase 4) |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/references/post-shortlist.md` | After user confirms final shortlist (Phase 7) |

## Scripts

| Script | Purpose |
|--------|---------|
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/check-domains.sh` | 3-tier checker: CF → Porkbun → whois; `.io` domains route to Porkbun directly, bypassing CF |
| `${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/get-prices.sh` | Porkbun no-auth TLD pricing, always runs |

Both scripts must be executable: `chmod +x ${CLAUDE_PLUGIN_ROOT}/skills/site-naming/scripts/*.sh`

## Example

See `examples/example-session.md` for a complete run: developer productivity SaaS → 7-question interview → Direction Round → Deep Generation → Wave 1 results with Spotlight → Wave 2 refinement → final names.md.
````

- [ ] **Step 2: Verify the new SKILL.md passes structure checks**

```bash
# Version bumped to 0.3.0
grep "version:" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: version: 0.3.0

# 7 checklist items
grep -c "^[0-9]\." plugins/namesmith/skills/site-naming/SKILL.md
# Expected: 7

# Two HARD-GATE blocks
grep -c "HARD-GATE" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: 4 (opening + closing tag × 2)

# Direction Round phase exists
grep -c "Direction Round" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: at least 3

# Closing prompt requirement present
grep -c "always appears" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: 1

# Q7 Vocabulary in brand profile summary
grep -c "Vocabulary:" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: at least 2

# Source column in results table
grep -c "Source" plugins/namesmith/skills/site-naming/SKILL.md
# Expected: at least 2
```

- [ ] **Step 3: Commit**

```bash
git add plugins/namesmith/skills/site-naming/SKILL.md
git commit -m "feat(namesmith): redesign skill flow — 7-phase with Direction Round, Spotlight, Suffix Family"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task that covers it |
|-----------------|---------------------|
| Phase 1: resume detection + personal brand branch | Task 5 (SKILL.md Phase 1, Step 0/2) |
| Phase 2: 7 questions + Q7 vocabulary mining | Task 3 (brand-interview.md) + Task 5 (Step 3) |
| Phase 3: API Gate moved to Availability Check | Task 5 (Phase 4 opening block) |
| Phase 4: Direction Round unweighted, 8 archetypes + wildcards | Task 5 (Phase 2) |
| Phase 4: rejection loop cap at 3 | Task 5 (Phase 2 Branch C) |
| Phase 5: Direction Selection hard gate, cap 3 archetypes | Task 5 (Phase 2 hard gate + Branch A) |
| Phase 6: Deep Generation weighted, 15–20 names | Task 5 (Phase 3) |
| Phase 6: Suffix Family full block if selected | Task 5 (Phase 3) + Task 4 (generation-archetypes.md) |
| Phase 7: Availability Check with API Gate explanation | Task 5 (Phase 4) |
| Phase 8a: Results table 5 columns | Task 5 (Phase 5) |
| Phase 8b: Conditional Spotlight with 6-point framework | Task 5 (Phase 5 Conditional Spotlight) |
| Phase 9: Soft Wave 2 prompt (always appears) | Task 5 (Phase 5 closing prompt) |
| Phase 10: Wave 2 conditional | Task 5 (Phase 6) |
| Phase 11: Post-shortlist | Task 5 (Phase 7) |
| Fix .result[] → .result.domains[] | Task 1 |
| Fix .io routing to Porkbun | Task 2 |
| Add Suffix Family 8th archetype | Task 4 |

All spec requirements covered. No placeholders. No TBDs.
