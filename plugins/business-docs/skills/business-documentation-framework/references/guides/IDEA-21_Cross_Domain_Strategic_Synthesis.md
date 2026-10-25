# Generation Guide: IDEA-21 Cross-Domain Strategic Synthesis

**Purpose:** Synthesize patterns across multiple domain-specific root cause analyses to identify shared systemic issues and strategic implications for platform initiatives.

**Type:** Synthesis
**Gateway:** No
**Optional:** Yes - only for multi-domain/platform initiatives

---

## When to Use This Document

Use IDEA-21 when:
- Initiative spans **2+ distinct domains** (e.g., Sales + Operations + Salvage)
- Multiple IDEA-03 analyses have been completed across domains
- Pattern recognition across analyses would inform platform architecture
- Strategic implications need documentation before problem articulation (IDEA-04)

**Skip this document if:**
- Single domain/vertical initiative
- Only one IDEA-03 analysis exists
- Patterns are obvious and don't require formal synthesis

---

## Prerequisites

- IDEA-03 5 Whys Analysis (at least 2 domain analyses)
- IDEA-01 Customer Interviews (for evidence references)
- IDEA-02 JTBD Analysis (for job context)

---

## Extraction from Prerequisites

| Source | Extract |
|--------|---------|
| IDEA-03 (multiple) | Root causes per domain, intervention points |
| IDEA-01 | Evidence quotes supporting patterns |
| IDEA-02 | Job statements showing cross-domain needs |

---

## Questions to Ask the User

1. How many distinct domains does this initiative span?
2. What shared infrastructure or data do these domains need?
3. Are there vendor dependencies that affect multiple domains?
4. What organizational patterns led to the current fragmentation?

---

## Document Template

```markdown
# Cross-Domain Strategic Synthesis

**ID:** IDEA-21
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** IDEA-03 (multiple domain analyses)
**Gateway:** No
**Scope:** Platform-level synthesis

---

## Initiative Context

**Platform/Initiative Name:** [Name]
**Domains Analyzed:** [List domains with IDEA-03 references]
**Total Root Causes Identified:** [Count]

---

## Root Cause Summary by Domain

| Domain | # Analyses | Key Root Causes |
|--------|------------|-----------------|
| [Domain 1] | X | [Brief list] |
| [Domain 2] | X | [Brief list] |
| [Domain 3] | X | [Brief list] |

---

## Meta-Root-Cause Patterns

Patterns that appear across multiple domain analyses.

### Pattern 1: [Name]

**Appears in:** [List domains]

**Description:** [2-3 sentences describing the systemic pattern]

**Evidence:**
- [Domain A]: [Specific root cause reference]
- [Domain B]: [Specific root cause reference]

**Pattern Recognition:**
```
[Trigger] → [Consequence] → [Workaround] → [Repeat]
```

### Pattern 2: [Name]

[Same structure]

### Pattern 3: [Name]

[Same structure]

---

## Strategic Implications

What these patterns mean for platform/solution design.

### Implication 1: [Title]

**Pattern(s):** [Which meta-root-cause(s) this addresses]

**Recommendation:** [Specific architectural or strategic recommendation]

**Priority:** [High/Medium/Low based on frequency and impact]

### Implication 2: [Title]

[Same structure]

---

## Shared Infrastructure Requirements

Based on pattern analysis, these capabilities are needed across domains:

| Capability | Domains Requiring | Priority | Rationale |
|------------|-------------------|----------|-----------|
| [Capability 1] | [Domains] | [H/M/L] | [Why needed] |
| [Capability 2] | [Domains] | [H/M/L] | [Why needed] |

---

## Vendor/Dependency Risks

Systemic dependencies affecting multiple domains.

| Dependency | Domains Affected | Risk Level | Mitigation Options |
|------------|------------------|------------|-------------------|
| [Vendor/System] | [Domains] | [H/M/L] | [Build/Buy/Mitigate] |

---

## Validation Checkpoints

| Pattern | Validation Question | Who To Ask |
|---------|---------------------|------------|
| [Pattern 1] | [Question to confirm pattern] | [Role] |
| [Pattern 2] | [Question to confirm pattern] | [Role] |

---

## Next Document

This synthesis informs:
→ **IDEA-04: Problem Statement** — Uses patterns to articulate unified platform problem

---

## Completion Checklist

- [ ] All domain IDEA-03 analyses referenced
- [ ] At least 2 meta-root-cause patterns identified
- [ ] Strategic implications documented with priorities
- [ ] Shared infrastructure requirements listed
- [ ] Vendor dependencies assessed
- [ ] Validation checkpoints provided
```

---

## Integration with Existing Framework

### Dependency Rules

| Path | IDEA-21 Usage |
|------|---------------|
| Internal Tool | SKIP (single domain) |
| MVP | Optional (if multi-domain) |
| Investor | Optional (if multi-domain) |
| Full | Include if 2+ domains |

### Path Insertion

When used, IDEA-21 sits between IDEA-03 and IDEA-04:

```
IDEA-03 (Domain A)  ─┐
IDEA-03 (Domain B)  ─┼→ IDEA-21 → IDEA-04⭐
IDEA-03 (Domain C)  ─┘
```

### Related Documents

| Document | Relationship |
|----------|--------------|
| IDEA-03 | Source of domain root causes |
| IDEA-04 | Receives synthesized problem context |
| IDEA-19 | Receives vendor risk assessment |
| IDEA-18 | May receive strategic implications for OST |
