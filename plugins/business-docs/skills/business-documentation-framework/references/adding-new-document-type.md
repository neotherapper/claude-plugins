# Adding a New Document Type

Guide for extending the Business Documentation Framework with new document types.

---

## Quick Reference Checklist

When adding a new document type (e.g., IDEA-21), update these files in order:

| Step | File | What to Update |
|------|------|----------------|
| 1 | `references/guides/{ID}_{Name}.md` | Create the generation guide |
| 2 | `references/document-registry.md` | Add row to registry table, update counts |
| 3 | `references/path-dependencies.md` | Update phase range, Full Path count |
| 4 | `references/extraction-guide.md` | Add extraction rules (ToC + section) |
| 5 | `SKILL.md` | Update doc counts (find/replace old → new) |
| 6 | `scripts/check-progress.py` | DOCUMENT_NAMES dict + counts |
| 7 | `scripts/check-dependencies.py` | STANDARD_DEPENDENCIES dict |
| 8 | `scripts/check-consistency.py` | DOCUMENT_PRIORITY list |
| 9 | `scripts/discover-project.py` | Full path doc_count |
| 10 | `scripts/suggest-path.py` | Full path counts (4 locations) |
| 11 | `scripts/init-project.py` | DOC_DESCRIPTIONS dict |
| 12 | Verify | `grep -r "OLD_COUNT" .` to find missed references |

---

## Detailed Steps

### Step 1: Create the Generation Guide

Location: `references/guides/{ID}_{Name}.md`

Required sections:
```markdown
# Generation Guide: [ID] [Full Name]

**Purpose:** [One sentence describing what this document achieves]

**Type:** [Discovery | Synthesis | Planning | Specification | Technical | Operations]
**Gateway:** [Yes/No]
**Optional:** [Yes - condition / No]

---

## When to Use This Document

Use [ID] when:
- [Condition 1]
- [Condition 2]

**Skip this document if:**
- [Condition 1]
- [Condition 2]

---

## Prerequisites

- [IDEA-XX] [Name] (required/optional)
- [Other dependencies]

---

## Extraction from Prerequisites

| Source | Extract |
|--------|---------|
| [ID] | [What to extract] |

---

## Questions to Ask the User

1. [Question 1]
2. [Question 2]

---

## Document Template

```markdown
# [Document Title]

**ID:** [ID]
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** [List]
**Gateway:** [Yes/No]

---

## [Section 1]

[Content structure]

---

## [Section 2]

[Content structure]

---

## Completion Checklist

- [ ] [Verification item 1]
- [ ] [Verification item 2]
```

---

## Integration with Existing Framework

### Dependency Rules

| Path | [ID] Usage |
|------|------------|
| Internal Tool | [SKIP/Include/Optional] |
| MVP | [SKIP/Include/Optional] |
| Investor | [SKIP/Include/Optional] |
| Full | [Include if condition] |

### Path Insertion

[Show where this document fits in the dependency flow]

### Related Documents

| Document | Relationship |
|----------|--------------|
| [ID] | [How it relates] |
```

### Step 2: Update Document Registry

File: `references/document-registry.md`

1. Update header version and count:
```markdown
# Document Registry v2.X
Complete registry of all [NEW_COUNT] documents...
```

2. Add row to appropriate phase table:
```markdown
| [ID] | [Name] | [Type] | [Dependencies] | [Path columns] | [Gateway] | [Guide link] |
```

3. Update "Full Path" section count:
```markdown
### Full Path ([NEW_COUNT] documents, 16-26 weeks)
```

4. Update Guide Coverage table if present.

### Step 3: Update Path Dependencies

File: `references/path-dependencies.md`

1. Update Table of Contents if it lists document ranges
2. Update Full Path section:
```markdown
## Full Path ([NEW_COUNT] Documents)
```
3. Update phase overview table if document extends a phase range

### Step 4: Update Extraction Guide

File: `references/extraction-guide.md`

1. Add to Table of Contents:
```markdown
- [[ID] ([Name]) - Optional](#[id]-[name]---optional)
```

2. Add extraction section:
```markdown
## [ID] ([Name]) - Optional

[When to use note if optional]

### When generating, extract from [DEPENDENCY]:

| Field | Where It Goes |
|-------|---------------|
| [Field 1] | [Section in new doc] |

### What downstream documents extract from [ID]:

[List what other documents pull from this one]
```

3. Update any existing sections that should extract from this new document.

### Step 5: Update SKILL.md

File: `SKILL.md`

Search and replace all occurrences of old count with new count:
- Description line
- Path table
- Reference file descriptions

### Step 6: Update check-progress.py

File: `scripts/check-progress.py`

1. Add to DOCUMENT_NAMES dict:
```python
'[ID]': '[Full Name]',
```

2. Update Full path description:
```python
'description': 'Enterprise/regulated environments ([NEW_COUNT] docs, 16-26 weeks)'
```

3. Update total count calculations:
```python
completion_pct = len(real_doc_ids) / [NEW_COUNT] * 100
'total': len(path_sequence) if path_sequence else [NEW_COUNT],
```

### Step 7: Update check-dependencies.py

File: `scripts/check-dependencies.py`

Add to STANDARD_DEPENDENCIES dict:
```python
'[ID]': ['[DEPENDENCY_ID]'],  # Comment explaining dependency
```

### Step 8: Update check-consistency.py

File: `scripts/check-consistency.py`

Add to DOCUMENT_PRIORITY list in correct position (earlier = more authoritative):
```python
DOCUMENT_PRIORITY = [
    'IDEA-01', 'IDEA-02', ..., '[NEW_ID]', ...
]
```

### Step 9: Update discover-project.py

File: `scripts/discover-project.py`

Update Full path definition:
```python
'Full': {
    'required': [],  # All [NEW_COUNT] documents
    'doc_count': [NEW_COUNT]
}
```

### Step 10: Update suggest-path.py

File: `scripts/suggest-path.py`

Update Full path in PATHS dict (4 locations):
```python
'Full': {
    'documents': [],  # All [NEW_COUNT]
    'doc_count': [NEW_COUNT],
    ...
    'includes': ['All [NEW_COUNT] document types across all phases'],
}
```

And in print output:
```python
print("  All [NEW_COUNT] documents in dependency order")
```

### Step 11: Update init-project.py

File: `scripts/init-project.py`

Add to DOC_DESCRIPTIONS dict:
```python
'[ID]': '[Brief description for placeholder files]',
```

If the document should appear in a specific path's sequence, also add to that path's documents list.

### Step 12: Verification

Run these commands to verify no references were missed:

```bash
# Check for old count references
grep -r "[OLD_COUNT]" <skill-folder>/

# Verify new document is referenced
grep -r "[NEW_ID]" <skill-folder>/

# Count guide files (should match registry)
ls -1 references/guides/*.md | wc -l
```

---

## Gateway vs Non-Gateway Documents

If adding a **Gateway document** (requires approval before proceeding):

Additional updates needed:
- `scripts/validate-document.py`: Add to GATEWAYS list
- `scripts/gateway-status.py`: Add to GATEWAYS dict with approvers
- `scripts/init-project.py`: Add to GATEWAYS list
- `references/gateway-protocol.md`: Document approval criteria

---

## Path-Specific Documents

If the document is **path-specific** (not just Full path):

Additional updates needed:
- `scripts/check-progress.py`: Add to path's sequence list
- `scripts/check-dependencies.py`: Add to PATH_DEPENDENCIES for that path
- `scripts/suggest-path.py`: Add to path's documents list
- `scripts/discover-project.py`: Add to path's required list
- `scripts/init-project.py`: Add to path's documents list

---

## Example: Adding IDEA-21

Here's the actual checklist used when IDEA-21 was added:

| File | Change |
|------|--------|
| `guides/IDEA-21_Cross_Domain_Strategic_Synthesis.md` | Created full guide |
| `document-registry.md` | Added row, updated to v2.3, 85 docs |
| `path-dependencies.md` | Updated IDEA range to IDEA-21, Full Path to 85 |
| `extraction-guide.md` | Added ToC entry + full section + IDEA-04 extraction |
| `SKILL.md` | 84 → 85 (4 locations) |
| `check-progress.py` | DOCUMENT_NAMES + 3 count updates |
| `check-dependencies.py` | STANDARD_DEPENDENCIES entry |
| `check-consistency.py` | DOCUMENT_PRIORITY list |
| `discover-project.py` | Full path count |
| `suggest-path.py` | Full path counts (4 locations) |
| `init-project.py` | DOC_DESCRIPTIONS entry |

Total files modified: **11**

---

## Maintenance Notes

- Always increment the document-registry.md version number
- Test the validation script after adding: `python scripts/validate-document.py docs/`
- If adding optional documents, clearly mark conditions in the guide
- Keep extraction rules bidirectional (what this doc extracts AND what extracts from it)
