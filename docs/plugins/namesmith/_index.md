# Namesmith — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Namesmith runs a brand-interview-first domain naming workflow — 6 structured questions lock tone, direction, budget, and constraints, then it generates names across 7 archetypes using 10 techniques, checks availability via a 3-tier API chain (Cloudflare → Porkbun → whois), and persists a shortlist to `names.md` in the user's project directory.

**Skill:** `site-naming` — triggered by natural language ("find me a domain", "name my project", "what should I call this")

---

## File map

```
plugins/namesmith/
├── README.md                              ← user-facing overview (ships)
│
├── .claude-plugin/plugin.json             ← manifest
│
└── skills/
    └── site-naming/
        ├── SKILL.md                       ← 10-step orchestration (v0.2.0, ~1,700 words)
        │
        ├── references/                    ← loaded on demand via $CLAUDE_PLUGIN_ROOT
        │   ├── brand-interview.md         ← 6 questions, weighting rules, personal brand flow
        │   ├── generation-archetypes.md   ← 7 archetypes, 10 techniques, Wave 1/2/3, Track B
        │   ├── tld-catalog.md             ← budget/trendy/thematic TLDs, 22 domain hacks
        │   ├── registrar-routing.md       ← per-TLD registrar table, URL patterns
        │   ├── api-setup.md               ← CF + Porkbun env var setup, whois fallback
        │   └── post-shortlist.md          ← pronunciation, social handles, trademark, registration
        │
        ├── examples/
        │   └── example-session.md         ← complete worked session (dev SaaS → names.md)
        │
        └── scripts/
            ├── check-domains.sh           ← 3-tier availability checker: CF → Porkbun → whois
            └── get-prices.sh              ← Porkbun no-auth TLD pricing (single API call)
```

---

## Workflow overview

```
User describes project
        ↓
Step 0: Session orientation — resume or start fresh (reads existing names.md)
Step 1: Detect project files (README, package.json, etc.)
Step 2: Detect personal brand signals (portfolio, freelance, name)
Step 3: Brand interview — 6 questions, one per message
Step 4: Wave 1 generation — 25–35 names across 7 archetypes
Step 5: Availability + pricing check (check-domains.sh + get-prices.sh)
Step 6: Format output with registration links per TLD
Step 7: Write names.md to project directory
Step 8: Feedback loop — Wave 2, Wave 3, or Track B if all taken
Step 9: Post-shortlist checklist (pronunciation, handles, trademark)
```

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-04-15-namesmith-design.md` |
| Implementation plan | `docs/superpowers/plans/2026-04-15-namesmith.md` |
| Architectural decisions | `docs/plugins/namesmith/DECISIONS.md` |
| Testing guide | `docs/plugins/namesmith/TESTING.md` |
| User-facing README | `plugins/namesmith/README.md` |
| Feature specs (.feature) | `docs/plugins/namesmith/specs/` — 8 feature files covering session-orientation, brand-interview, personal-brand-flow, wave-generation, availability-check, output-and-names-md, track-b-fallback, post-shortlist |
| Contributor knowledge base | `docs/plugins/namesmith/CONTRIBUTOR-KNOWLEDGE.md` — research-backed context: archetype origins, registrar data, AI prompting patterns, known gaps |
