# Namesmith — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Namesmith conducts a structured brand personality interview then generates domain names across 7 archetypes using 10 proven naming techniques, checks availability via Cloudflare and Porkbun APIs, and persists a shortlist to `names.md`.

**Commands:** `/namesmith` (single entry point, brand interview → generation → availability → names.md)

---

## File map

```
plugins/namesmith/
├── README.md                       ← user-facing overview (ships)
│
├── .claude-plugin/plugin.json      ← manifest
│
├── skills/
│   └── site-naming/SKILL.md        ← full brand interview + generation workflow
│       └── references/
│           ├── brand-interview.md  ← 6 interview questions with intent notes
│           ├── generation-archetypes.md ← 7 archetypes × 10 techniques
│           ├── tld-catalog.md      ← TLD options and use cases
│           └── api-setup.md        ← Cloudflare + Porkbun credential setup
│
└── scripts/
    ├── check-domains.sh            ← CF → Porkbun → whois availability check
    └── get-prices.sh               ← Porkbun no-auth pricing
```

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-04-15-namesmith-design.md` |
| Implementation plan | `docs/superpowers/plans/2026-04-15-namesmith.md` |
| Feature specs (.feature) | `docs/plugins/namesmith/specs/` ← to be written |
| User-facing README | `plugins/namesmith/README.md` |
