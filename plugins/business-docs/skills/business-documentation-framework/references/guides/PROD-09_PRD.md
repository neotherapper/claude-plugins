# Generation Guide: PROD-09 Product Requirements Document (GATEWAY)

**Purpose:** Define the complete specification for what needs to be built, serving as the bridge to technical implementation.

---

## Prerequisites
- PROD-02 Product Strategy
- PROD-03 Personas
- PROD-18 Hypothesis Docs

## Extraction from PRD Dependencies
- Problem Statement (IDEA-04)
- Core Personas (PROD-03)
- Validated Hypotheses (PROD-18)

## Questions to Ask the User
- Who are the 2-3 key personas?
- What are the prioritized functional requirements (P0, P1, P2)?
- What are the non-functional requirements (Performance, Security)?
- What is explicitly NOT in scope?

## Document Template

```markdown
# Product Requirements Document (PRD)

**ID:** PROD-09
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-02, PROD-03
**Gateway:** Yes

---

## 1. Executive Summary
**Problem:** [From IDEA-04]
**Solution:** [Summary]
**Success Metric:** [Primary target]

## 2. Personas
- [Persona 1]
- [Persona 2]

## 3. Functional Requirements
| ID | Req | User Story | Priority |
|---|---|---|---|
| FR-1 | | | P0 |

## 4. Non-Functional Requirements
- **Performance:** [Target]
- **Security:** [Target]

## 5. Out of Scope
- ❌ [Item]

## Gateway Approval
**Required Approvers:** PM, Engineering Lead
```

---

## Validation Integrity Requirements (Gateway)

### Feature Traceability to Validation State

Every functional requirement must trace to its validation source:

| Requirement Source | Validation State | PRD Treatment |
|-------------------|-----------------|---------------|
| Validated job from IDEA-02 | [VALIDATED] | Include as firm requirement |
| Hypothetical job from IDEA-02b | [HYPOTHESIS] | Include as [CONDITIONAL] |
| Assumed need | [ASSUMED] | Either exclude OR mark as "pending validation" |

### Functional Requirements Table Expansion

Add validation column:

```markdown
| ID | Requirement | User Story | Priority | Validation |
|---|---|---|---|---|
| FR-1 | Auto spot reports | As sales... | P0 | [VALIDATED: Session 6] |
| FR-2 | Customer dashboard | As customer... | P1 | [CONDITIONAL: Awaiting validation] |
```

### Conditional Features

For features based on [HYPOTHESIS] jobs:

```markdown
## 3b. Conditional Features [PENDING VALIDATION]

These features are based on hypothetical customer jobs. Do not implement until validated.

| ID | Requirement | Blocked On |
|---|---|---|
| FR-C1 | Risk dashboard | Customer interview validation |
```

### Out of Scope Validation

Non-goals should reference validated scope decisions:

```markdown
## 5. Out of Scope [VALIDATED]
- ❌ Customer portal features (blocked until customer interviews complete)
- ❌ Mobile app (not requested in any validated interview)
```

### Gateway Approval Criteria

Add validation-specific criteria:
- [ ] All P0 features traced to [VALIDATED] jobs
- [ ] [CONDITIONAL] features clearly separated
- [ ] No [HYPOTHESIS] content treated as firm requirement
- [ ] Out of scope based on validated scope constraints
