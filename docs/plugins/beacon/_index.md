# Beacon — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Beacon maps any website's API surface through a 12-phase systematic analysis — tech fingerprinting, OSINT, script probing, browser recon, and OpenAPI spec generation. Output lands in `docs/research/{site}/` as a structured, queryable research folder.

**Commands:** `/beacon:analyze {url}` · `/beacon:load`

---

## File map

```
plugins/beacon/
├── README.md                    ← user-facing overview (ships)
├── CONTRIBUTING.md              ← contributor guide
│
├── .claude-plugin/plugin.json   ← manifest
│
├── skills/
│   ├── site-recon/SKILL.md      ← /beacon:analyze — 12-phase analysis
│   └── site-intel/SKILL.md      ← /beacon:load — query research docs
│
├── agents/
│   └── site-analyst.md          ← JS analysis, OSINT, tech pack application
│
├── technologies/                ← tech-pack guides per framework/version
│   ├── nextjs/15.x.md
│   ├── wordpress/6.x.md
│   └── ...
│
├── hooks/hooks.json             ← SessionStart hook
└── scripts/                     ← probe scripts and utilities
```

---

## Related docs

| Doc | Location |
|-----|----------|
| Feature specs (.feature) | `docs/plugins/beacon/specs/` |
| Design docs | `docs/plugins/beacon/designs/` |
| Implementation plans | `docs/plugins/beacon/plans/` |
| User-facing README | `plugins/beacon/README.md` |
