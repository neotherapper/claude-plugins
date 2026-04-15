# namesmith

> Find the right name for your project — brand interview, AI generation across 7 archetypes, live availability + pricing via Cloudflare or Porkbun.

## What it does

namesmith is a Claude Code plugin that runs a structured naming workflow:

1. **Brand interview** — 6 questions to lock your tone, direction, budget mode, and constraints
2. **Multi-archetype generation** — 25–35 candidates per wave across 7 strategies (Short & Punchy, Descriptive, Abstract/Brandable, Playful/Clever, Domain Hacks, Compound/Mashup, Thematic TLD Play)
3. **Live availability + pricing** — checks domains via Cloudflare Registrar API, Porkbun API, or whois fallback
4. **Iteration** — Wave 2 refinement, Wave 3 deep TLD scan (1,441+ IANA TLDs), Track B fallback for fully-taken results
5. **Persistence** — writes `names.md` to your project directory with shortlist, rationale, and brand profile

## Installation

```bash
# From the claude-plugins marketplace
cc install neotherapper/namesmith

# Or add to your project's .claude/plugins list
```

## Usage

Trigger the skill with natural language:

```
find me a domain for my project
name my new SaaS
what should I call this CLI tool?
domain for my portfolio
I need a site name for [description]
```

The skill will guide you through the brand interview and run availability checks automatically.

## API Setup (optional but recommended)

Without API keys, namesmith uses `whois` for availability checks (no price data). Configure one of these for better results:

### Option A: Cloudflare Registrar (recommended)

Best if you already have a Cloudflare account. Provides availability + at-cost pricing. Up to 20 domains per batch call.

```bash
export CF_API_TOKEN="your-token"       # dash.cloudflare.com/profile/api-tokens
export CF_ACCOUNT_ID="your-account-id" # visible in dashboard URL
```

### Option B: Porkbun

Free API key required. Good coverage for a wide range of TLDs.

```bash
export PORKBUN_API_KEY="pk1_..."
export PORKBUN_SECRET="sk1_..."
```

TLD pricing always works without auth (the Porkbun `/pricing/get` endpoint is free and unauthenticated).

See `skills/site-naming/references/api-setup.md` for step-by-step setup instructions.

## Skills

### `site-naming`

The core skill. Handles the full naming workflow:

- Personal brand detection (portfolio, freelance, consulting patterns)
- 6-question brand interview
- Wave 1 / Wave 2 / Wave 3 generation
- 3-tier availability check (Cloudflare → Porkbun → whois)
- Registration link generation per TLD
- `names.md` persistence
- Post-shortlist checklist (pronunciation, social handles, trademark, registration strategy)

## Output

After each wave, namesmith outputs:

```
## Wave 1 Results — [your project]

**Top Picks**
✅ codeforge.io   $35.98/yr  — Authoritative compound, strong tech signal
   [Porkbun →](https://porkbun.com/checkout/search?q=codeforge.io)

...

TLD summary: .com [2 available] | .io [11 available] | .dev [1 available]
13 of 17 checked available. Anything catching your eye, or should I run Wave 2?
```

A `names.md` file is written to your current working directory with your shortlist, brand interview answers, and rationale for each name.

## Prerequisites

- Claude Code with plugin support
- `curl` and `jq` (required for API tiers)
- `whois` (optional, for Tier 3 fallback — `brew install whois` on macOS)
- `dig` (optional, improves redemption detection in Tier 3)

## License

MIT — see [LICENSE](../../LICENSE) or the repository root.
