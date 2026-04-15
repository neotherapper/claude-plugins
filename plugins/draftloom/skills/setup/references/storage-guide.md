# Storage Guide

Reference for where Draftloom profiles and config are stored.

## Storage modes

### Project mode (default)
Profiles live inside the current project directory:
```
{project-root}/
└── .draftloom/
    ├── config.json
    └── profiles/
        └── {name}.json
```

Use project mode when:
- You have one persona per project
- You want profiles committed to git alongside the project
- You want isolation between different clients or brands

### Global mode
Profiles live in the user's home directory:
```
~/.draftloom/
├── config.json
└── profiles/
    └── {name}.json
```

Use global mode when:
- You write with the same voice across many projects
- You don't want profiles in your project git repo

## config.json schema

```json
{
  "storage_mode": "project",
  "storage_path": ".draftloom",
  "version": "0.1.0",
  "created_at": "2026-04-15T10:00:00Z"
}
```

## First-run behaviour

On first setup run, if `.draftloom/config.json` does not exist, the setup skill asks the user: "Store profiles in this project only, or globally? (project/global)" and creates `config.json` with the chosen `storage_mode`.

If the user asks for more detail about the difference between modes, load this guide and explain the options above.

## Switching modes

To switch from project to global after setup:
1. Copy profiles from `.draftloom/profiles/` to `~/.draftloom/profiles/`
2. Update `.draftloom/config.json` → `storage_mode: "global"`
3. Optionally delete `.draftloom/profiles/` from the project

Claude performs these steps automatically if the user asks to switch storage mode via `/draftloom:setup`.
