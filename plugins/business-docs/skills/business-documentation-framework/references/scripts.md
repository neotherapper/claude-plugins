# Business Documentation Scripts

Run every script from the repo root. Most take the project's docs directory as their argument.


### init-project.py — Project Initialization

Create folder structure, config file, and optional placeholder documents for a new project.

```bash
python3 scripts/init-project.py /path/to/project --path MVP
python3 scripts/init-project.py /path/to/project --path "Internal Tool" --with-placeholders
python3 scripts/init-project.py  # Interactive mode
```

**When to use:** Starting a new project; creates `docs/`, `.business-docs.yaml`, and optional placeholder files.

### discover-project.py — Project Document Discovery

Find where business documents are stored for any project.

```bash
python3 scripts/discover-project.py /path/to/project
python3 scripts/discover-project.py --json
```

**When to use:** At the start of any documentation session to locate the docs directory.

### check-progress.py — Path Progress Tracker

Show completion status and next steps for the current path.

```bash
python3 scripts/check-progress.py /path/to/docs
python3 scripts/check-progress.py --path MVP
```

**When to use:** To answer "What's next?" or show progress to stakeholders.

### validate-document.py — Template Compliance Checker

Verify documents match their generation guide templates.

```bash
python3 scripts/validate-document.py docs/IDEA-04_Problem_Statement.md
python3 scripts/validate-document.py docs/  # Validate all
```

**When to use:** After generating documents to ensure quality.

### gateway-status.py — Gateway Approval Tracker

Track approval status of all gateway documents.

```bash
python3 scripts/gateway-status.py /path/to/docs
python3 scripts/gateway-status.py --pending
```

**When to use:** Before proceeding past gateway documents; to identify blocking approvals.

### check-dependencies.py — Dependency Graph Validator

Validate dependency declarations and detect issues.

```bash
python3 scripts/check-dependencies.py /path/to/docs
python3 scripts/check-dependencies.py --graph mermaid
```

**When to use:** To ensure proper document ordering; to generate dependency diagrams.

### check-consistency.py — Cross-Document Consistency Validator

Ensure key information is consistent across all documents.

```bash
python3 scripts/check-consistency.py /path/to/docs
python3 scripts/check-consistency.py --field customer_segment --verbose
```

**When to use:** After generating multiple documents; before finalizing gateway documents.

### extract-seven-categories.py — Handoff Preparation

Extract the Seven Essential Information Categories for business-to-code handoff.

```bash
python3 scripts/extract-seven-categories.py /path/to/docs
python3 scripts/extract-seven-categories.py --output handoff.md
```

**When to use:** After TECH-02 completion to prepare for implementation handoff.

### suggest-path.py — Path Recommendation Tool

Recommend which documentation path to follow based on project characteristics.

```bash
python3 scripts/suggest-path.py              # Interactive
python3 scripts/suggest-path.py --internal --timeline "2-4 weeks"
```

**When to use:** At the start of a new project to select the appropriate path.

## When to run which


1. **New project setup:** Run `init-project.py` to create structure and config
2. **Existing project:** Run `discover-project.py` to find docs location
3. **Path selection:** Run `suggest-path.py` if unsure which path to follow
4. **Tracking progress:** Run `check-progress.py` to show completion status
5. **After document generation:** Run `validate-document.py` to ensure quality
6. **At gateways:** Run `gateway-status.py` to track approvals
7. **Before handoff:** Run `extract-seven-categories.py` to prepare implementation context
