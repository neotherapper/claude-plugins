# Versioning + Cross-Tool Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a single source of truth for skill versions (`metadata.version`), enable cross-tool distribution via `gh skill`, and update stale plugins.

**Architecture:** Migrate SKILL.md frontmatter from non-standard `version` field to spec-compliant `metadata.version`. Publish skills to GitHub via `gh skill publish` to enable version-pinned installation and cross-tool updates. Keep existing Claude Code marketplace and symlink farm as fallbacks.

**Tech Stack:** `gh` CLI (GitHub CLI), Agent Skills spec (agentskills.io), bash scripts

---

## Background

### The Problem

1. **Version in two places:** SKILL.md has `version: 0.7.1` (non-standard) while the Agent Skills spec says version goes in `metadata.version`. The top-level `version` field is not used by any automation.

2. **No cross-tool updates:** Claude Code has `claude plugin update`, but OpenCode, Codex, Antigravity, and Kiro have no update mechanism. OpenCode's superpowers was stuck at v5.0.7 (cache frozen Apr 23) while Claude Code had v6.1.1.

3. **No version pinning:** Users can't install a specific version of a skill. No supply chain validation.

### The Solution: `gh skill`

`gh skill` is GitHub CLI's official tool for managing agent skills. It's npm for agent skills — but cross-tool.

| Capability | Before | After |
|------------|--------|-------|
| Install from GitHub | ❌ | `gh skill install neotherapper/claude-plugins site-recon` |
| Version pinning | ❌ | `@v0.7.1` or `--pin sha` |
| Cross-tool updates | ❌ (manual per tool) | `gh skill update --all` |
| Update detection | ❌ | `gh skill update --dry-run` |
| Supply chain validation | ❌ | `gh skill publish --dry-run` |

### What Stays the Same

| Mechanism | Keep? | Why |
|-----------|-------|-----|
| `.claude-plugin/marketplace.json` | ✅ | Claude Code's native discovery |
| `scripts/sync-skills.sh` | ✅ | For users who clone the repo |
| `AGENTS.md` | ✅ | Cross-tool instructions layer |
| `plugin.json` version | ✅ | Claude Code plugin system (separate concern) |

---

## File Structure

| Action | File | Purpose |
|--------|------|---------|
| Modify | `plugins/beacon/skills/site-recon/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/beacon/skills/site-intel/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/beacon/skills/site-fleet/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/reframe/skills/site-redesign/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/namesmith/skills/site-naming/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/draftloom/skills/draft/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/draftloom/skills/eval/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/draftloom/skills/setup/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/idea-forge/skills/evaluate/SKILL.md` | Migrate version to metadata |
| Modify | `plugins/idea-forge/skills/generate/SKILL.md` | Migrate version to metadata |
| Create | `scripts/update-skills.sh` | Cross-tool update script |
| Modify | `docs/platform/multi-tool-support.md` | Add gh skill instructions |
| Modify | `README.md` | Add gh skill installation option |

---

## Task 1: Update Superpowers in OpenCode

**Files:**
- Modify: `~/.cache/opencode/packages/` (clear stale cache)

- [ ] **Step 1: Clear OpenCode's stale superpowers cache**

```bash
rm -rf ~/.cache/opencode/packages/superpowers@git+https:*
```

- [ ] **Step 2: Restart OpenCode and verify version**

In OpenCode, ask: "Tell me about your superpowers" — should report v6.1.1 (not v5.0.7).

- [ ] **Step 3: Verify superpowers loads correctly**

```bash
opencode run --print-logs "hello" 2>&1 | grep -i superpowers
```

---

## Task 2: Migrate SKILL.md Version Fields

**Files:**
- Modify: All 10 SKILL.md files listed above

For each SKILL.md file, the change is:

**Before:**
```yaml
---
name: site-recon
description: ...
version: 0.7.1
---
```

**After:**
```yaml
---
name: site-recon
description: ...
metadata:
  version: "0.7.1"
  author: Georgios Pilitsoglou
---
```

- [ ] **Step 1: Migrate beacon/site-recon**

Edit `plugins/beacon/skills/site-recon/SKILL.md`:
- Remove line: `version: 0.7.1`
- Add after description:
```yaml
metadata:
  version: "0.7.1"
  author: Georgios Pilitsoglou
```

- [ ] **Step 2: Migrate beacon/site-intel**

Edit `plugins/beacon/skills/site-intel/SKILL.md`:
- Remove line: `version: 0.8.0`
- Add:
```yaml
metadata:
  version: "0.8.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 3: Migrate beacon/site-fleet**

Edit `plugins/beacon/skills/site-fleet/SKILL.md`:
- Remove line: `version: 0.9.0`
- Add:
```yaml
metadata:
  version: "0.9.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 4: Migrate reframe/site-redesign**

Edit `plugins/reframe/skills/site-redesign/SKILL.md`:
- Remove line: `version: 0.2.0`
- Add:
```yaml
metadata:
  version: "0.2.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 5: Migrate namesmith/site-naming**

Edit `plugins/namesmith/skills/site-naming/SKILL.md`:
- Remove line: `version: 0.3.0`
- Add:
```yaml
metadata:
  version: "0.3.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 6: Migrate draftloom/draft**

Edit `plugins/draftloom/skills/draft/SKILL.md`:
- Remove line: `version: "0.1.0"`
- Add:
```yaml
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 7: Migrate draftloom/eval**

Edit `plugins/draftloom/skills/eval/SKILL.md`:
- Remove line: `version: "0.1.0"`
- Add:
```yaml
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 8: Migrate draftloom/setup**

Edit `plugins/draftloom/skills/setup/SKILL.md`:
- Remove line: `version: "0.1.0"`
- Add:
```yaml
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 9: Migrate idea-forge/evaluate**

Edit `plugins/idea-forge/skills/evaluate/SKILL.md`:
- Remove line: `version: "0.1.0"`
- Add:
```yaml
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 10: Migrate idea-forge/generate**

Edit `plugins/idea-forge/skills/generate/SKILL.md`:
- Remove line: `version: "0.1.0"`
- Add:
```yaml
metadata:
  version: "0.1.0"
  author: Georgios Pilitsoglou
```

- [ ] **Step 11: Commit version migration**

```bash
git add plugins/*/skills/*/SKILL.md
git commit -m "fix: migrate SKILL.md version to metadata.version (Agent Skills spec)"
```

---

## Task 3: Validate with gh skill

**Files:**
- None (validation only)

- [ ] **Step 1: Run dry-run publish**

```bash
gh skill publish --dry-run
```

Expected: Warnings about missing `license` field (fixed in Task 4).

- [ ] **Step 2: Run fix to strip install metadata**

```bash
gh skill publish --fix
```

This strips any `metadata.github-*` fields that `gh skill install` injects.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: strip gh skill install metadata from committed files"
```

---

## Task 4: Add License Field to SKILL.md Frontmatter

**Files:**
- Modify: All 10 SKILL.md files

- [ ] **Step 1: Add license to each SKILL.md**

For each of the 10 SKILL.md files, add `license: MIT` to frontmatter:

```yaml
---
name: site-recon
description: ...
license: MIT
metadata:
  version: "0.7.1"
  author: Georgios Pilitsoglou
---
```

- [ ] **Step 2: Commit license additions**

```bash
git add plugins/*/skills/*/SKILL.md
git commit -m "fix: add license: MIT to SKILL.md frontmatter"
```

---

## Task 5: Publish to GitHub

**Files:**
- None (publishing only)

- [ ] **Step 1: Add agent-skills topic to repo**

```bash
gh repo edit neotherapper/claude-plugins --add-topic agent-skills
```

- [ ] **Step 2: Validate before publishing**

```bash
gh skill publish --dry-run
```

Expected: All skills pass validation.

- [ ] **Step 3: Publish with version tag**

```bash
gh skill publish --tag v1.0.0
```

This creates a GitHub release with all skills.

- [ ] **Step 4: Verify release**

```bash
gh release view v1.0.0
```

---

## Task 6: Create Update Script

**Files:**
- Create: `scripts/update-skills.sh`

- [ ] **Step 1: Create the update script**

```bash
#!/usr/bin/env bash
#
# update-skills.sh — update skills across all installed agents via gh skill
#
#   scripts/update-skills.sh          # interactive update
#   scripts/update-skills.sh --all    # update without prompting
#   scripts/update-skills.sh --dry-run # check for updates only
set -euo pipefail

MODE="${1:-}"
REPO="neotherapper/claude-plugins"

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not installed. Install: https://cli.github.com"
  exit 1
fi

if ! gh skill --help &>/dev/null 2>&1; then
  echo "Error: gh skill not available. Update GitHub CLI: gh upgrade"
  exit 1
fi

case "$MODE" in
  --dry-run)
    echo "Checking for skill updates..."
    gh skill update --dry-run
    ;;
  --all)
    echo "Updating all skills..."
    gh skill update --all
    ;;
  *)
    echo "Interactive skill update..."
    gh skill update
    ;;
esac
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x scripts/update-skills.sh
```

- [ ] **Step 3: Commit update script**

```bash
git add scripts/update-skills.sh
git commit -m "feat: add cross-tool skill update script via gh skill"
```

---

## Task 7: Update Documentation

**Files:**
- Modify: `docs/platform/multi-tool-support.md`
- Modify: `README.md`

- [ ] **Step 1: Add gh skill section to multi-tool-support.md**

Add after the "Per-tool install / setup" section:

```markdown
### Cross-Tool: gh skill (Recommended)

`gh skill` from GitHub CLI installs and updates skills across ALL agents:

```sh
# Install a skill for a specific agent
gh skill install neotherapper/claude-plugins site-recon --agent claude-code
gh skill install neotherapper/claude-plugins site-recon --agent opencode

# Pin to a specific version
gh skill install neotherapper/claude-plugins site-recon@v0.7.1

# Update all skills across all agents
gh skill update --all

# Check for updates
gh skill update --dry-run
```

This replaces the symlink farm for users who prefer versioned, updatable skills.
```

- [ ] **Step 2: Add gh skill to README.md installation section**

Add as an installation option:

```markdown
### Cross-Tool (gh skill)

```sh
gh skill install neotherapper/claude-plugins site-recon --agent claude-code
gh skill install neotherapper/claude-plugins site-recon --agent opencode
```
```

- [ ] **Step 3: Commit documentation**

```bash
git add docs/platform/multi-tool-support.md README.md
git commit -m "docs: add gh skill installation and update instructions"
```

---

## Task 8: Verify End-to-End

**Files:**
- None (verification only)

- [ ] **Step 1: Test gh skill install from GitHub**

```bash
# Install a skill to a temp directory to verify
gh skill install neotherapper/claude-plugins site-recon --agent opencode --dir /tmp/test-skill
cat /tmp/test-skill/site-recon/SKILL.md | head -10
```

Expected: SKILL.md with `metadata.version` in frontmatter.

- [ ] **Step 2: Test gh skill update detection**

```bash
gh skill update --dry-run
```

Expected: Shows installed skills and their status.

- [ ] **Step 3: Verify symlink farm still works**

```bash
scripts/sync-skills.sh --check
```

Expected: All symlinks valid.

- [ ] **Step 4: Verify Claude Code marketplace still works**

```bash
claude plugin validate plugins/beacon/.claude-plugin/plugin.json
```

Expected: Validation passes.

---

## Related Documents

| Document | Location |
|----------|----------|
| Agent Skills spec | https://agentskills.io/specification |
| gh skill docs | https://cli.github.com/manual/gh_skill |
| Multi-tool support | `docs/platform/multi-tool-support.md` |
| Site-utils design | `docs/superpowers/specs/2026-07-13-site-utils-shared-crawl-infrastructure-design.md` |
| Superpowers OpenCode docs | https://github.com/obra/superpowers/blob/main/docs/README.opencode.md |
