# Generation Guide: IDEA-02 Jobs-to-be-Done (JTBD) Analysis

**Purpose:** Understand the underlying "job" customers are hiring a solution for, including functional, emotional, and social dimensions.

---

## Prerequisites
- IDEA-01 Customer Interviews

## Extraction from IDEA-01
- Key quotes highlighting motivations
- Sequence of actions taken by users
- Frustrations with current workarounds

## Questions to Ask the User
- Share the key findings from your customer interviews.
- What are the main things customers are trying to accomplish?
- What frustrates them emotionally about the current situation?

## Document Template

```markdown
# JTBD Analysis

**ID:** IDEA-02
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** IDEA-01
**Gateway:** No

---

## Business Context
**Business Name:** [Name]
**Source:** Based on IDEA-01 Customer Interviews

## Primary Job Statement
**Format:** "When [situation], I want to [motivation], so I can [expected outcome]."

> When ______________,
> I want to ____________,
> so I can ____________.

## Job Map
| Step | What Customer Does | Pain Points | Current Solution |
|---|---|---|---|
| 1 | | | |

## Related Jobs
### Functional Jobs (What they need to accomplish)
1.
2.

### Emotional Jobs (How they want to feel)
1.
2.

### Social Jobs (How they want to be perceived)
1.

## Current Solutions Being "Hired"
| Solution | Why Hired | Why Fired |
|---|---|---|
| | | |

## Four Forces of Progress
### Demand-Creating Forces
**PUSH of Current Situation:**
1.
2.

**PULL of New Solution:**
1.
2.

### Change-Blocking Forces
**ANXIETY about New Solution:**
1.
2.

**HABIT of Present:**
1.
2.

## Success Criteria (Customer's Perspective)
How customers know they've completed the job successfully:
1.
2.

## Evidence (Interview Quotes)
> "[Quote 1]" — [Role, Context]

## Completion Checklist
- [ ] Jobs derived from interview evidence
- [ ] Job statements follow correct format
- [ ] Functional and emotional dimensions covered
- [ ] Four Forces analysis complete with evidence
- [ ] Success criteria are measurable
- [ ] Validation states tagged on all jobs
```

---

## Validation Integrity Requirements

### Job Statement Tagging

Every job statement must include validation state:

| Job Source | Validation State | Example |
|------------|-----------------|---------|
| Direct interview quote | [VALIDATED] | `"When I need..." [VALIDATED: Session 3, Name]` |
| Inferred from behavior | [HYPOTHESIS] | `"When customers need..." [HYPOTHESIS: Inferred from product usage]` |
| Assumed from domain | [ASSUMED] | `"When underwriters need..." [ASSUMED: Industry standard]` |

### Extracting Unvalidated Jobs

If IDEA-01 contains significant unvalidated content (e.g., inferred customer needs), **extract to IDEA-02b**:

```markdown
## IDEA-02b: Customer Jobs Hypotheses

This document contains hypothetical jobs extracted from IDEA-02 pending validation.

**Status:** NOT VALIDATED — Do not use for feature prioritization.
```

### Four Forces Separation

Only include Four Forces analysis for validated user groups. For hypothetical users:

```markdown
## Four Forces — [User Group] [NOT VALIDATED]

Content extracted to IDEA-02b pending customer interviews.
```

### Preventing Downstream Confusion

- Job maps for uninterviewed users: Extract or omit
- Success criteria for hypothetical jobs: Mark as [HYPOTHESIS]
- Don't create detailed functional jobs for assumed user needs
