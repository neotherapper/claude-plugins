---
name: business-documentation-framework
description: Write business and product documents in dependency order, from problem statement and canvases through PRD to technical design and the business-to-code handoff. 85 document types, 6 phases, 4 paths (Internal Tool, MVP, Investor, Full). Use when the user wants to create, continue, or check a business document (PRD, Lean/Value Proposition Canvas, JTBD, problem statement, TDD, investor materials), pick a documentation path for a project, or prepare an implementation handoff. To judge whether an idea is worth building at all, use /idea-forge:evaluate.
---

# Business Documentation Framework

> Paths in this skill are relative to the folder that contains this SKILL.md. Resolve them to absolute paths before reading a file or running a script.

Guide users from business idea to deployable product through phased, dependency-aware documentation.

## Core Workflow

### Step 1: Determine Path

Ask these questions before showing any documents, because the answers decide which path, and so which documents, apply:

1. "Is this an **internal tool** for your team, or an **external product** for customers/market?"
2. "What stage are you at? (exploring idea / problem validated / building MVP / seeking investors)"
3. "Do you already know what to build, or do you need to discover the right solution?"

Select path based on answers:

| Scenario                          | Path          | Docs | Time        |
| --------------------------------- | ------------- | ---- | ----------- |
| Internal tool, clear requirements | Internal Tool | 6    | 2-3 weeks   |
| External product, MVP focus       | MVP           | 11   | 8-14 weeks  |
| External product + investors      | Investor      | 16+  | 10-16 weeks |
| Enterprise, regulated, full rigor | Full          | 85   | 16-26 weeks |

For path details, dependencies, and adaptations: [references/path-dependencies.md](references/path-dependencies.md)

### Step 2: Generate Documents

For each document in the path:

**A. Check Prerequisites**

- Search project for dependency documents
- If found: Extract required info per [references/extraction-guide.md](references/extraction-guide.md)
- If skipping: Use [references/quick-foundation.md](references/quick-foundation.md)

**B. Consult Individual Guide**

- Find the specific guide for the document in [references/document-registry.md](references/document-registry.md)
- Read the guide file in `references/guides/` (e.g., `references/guides/IDEA-04_Problem_Statement.md`)

**C. Ask Clarifying Questions** from the specific guide

**D. Generate Document** using the template and instructions in the guide

**E. Verify Consistency**

- Customer segment matches across documents
- Problem statement is consistent
- Metrics align
- Terminology identical (no synonyms)

**F. Create File** as `[ID]_[Name].md`

**G. At Gateways** (⭐ documents): Follow [references/gateway-protocol.md](references/gateway-protocol.md)

**H. Reveal Next Step**

Show only the immediate next document, so the user stays on one step at a time. Format:

```
✅ [DOC-ID] complete!
Progress: [X]/[Total] on [Path]
→ Next: [NEXT-DOC-ID] [Name]
Ready?
```

### Step 3: Bridge to Implementation (After TECH-02)

After completing the path's final gateway document:

1. Generate handoff document using [references/handoff-bridge.md](references/handoff-bridge.md)
2. Extract Seven Essential Categories from completed documents
3. Offer Memory Bank file generation if using AI development tools

### Path Completion

When all path documents are complete:

- Summarize what was created
- Note any [ASSUMPTION] markers needing validation
- Suggest next steps (implementation, team review, etc.)

## Reference Files

- **[document-registry.md](references/document-registry.md)** — Master list of 85 documents with links to individual guides
- **[path-dependencies.md](references/path-dependencies.md)** — Path definitions, dependency tables, adaptations
- **[extraction-guide.md](references/extraction-guide.md)** — What to extract from each dependency
- **[gateway-protocol.md](references/gateway-protocol.md)** — Validation and approval process
- **[quick-foundation.md](references/quick-foundation.md)** — Questions when skipping documents, path changes
- **[handoff-bridge.md](references/handoff-bridge.md)** — Business-to-Code handoff for implementation transition
- **[guides/](references/guides/)** — Directory containing individual generation guides for all 85 document types
- **[adding-new-document-type.md](references/adding-new-document-type.md)** — Maintenance guide for extending the framework with new document types

## Scripts

`scripts/` has helpers for project setup (`init-project.py`, `discover-project.py`, `suggest-path.py`), progress (`check-progress.py`, `gateway-status.py`), quality (`validate-document.py`, `check-consistency.py`, `check-dependencies.py`), and handoff (`extract-seven-categories.py`). Usage and when to run each: [references/scripts.md](references/scripts.md). At session start, run `discover-project.py` on an existing project to find its docs; after writing a document, run `validate-document.py` on it.
