# Generation Guide: IDEA-01 Customer Interviews (Mom Test)

**Purpose:** Validate that a real problem exists by talking to potential customers without biasing their answers.

---

## Prerequisites
- Target customer segment hypothesis
- Problem area to explore

## Questions to Ask the User
- Who specifically are you trying to reach? (role, company size, industry)
- What problem do you believe they have?
- Do you have any existing contacts or channels to reach them?

## Document Template

```markdown
# Customer Interviews (Mom Test)

**ID:** IDEA-01
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** None
**Gateway:** No

---

## Business Context
**Business Name:** [Name]
**Problem Area:** [Brief description]

## Target Interviewees
- [Role] at [Company type]
- Minimum: 10 interviews across 5+ organizations

## Interview Guide

### Opening (5 min)
"Thank you for speaking with me. I'm researching [problem area]. I'm not selling anything—I just want to understand your experience."

### Problem Exploration (15 min)
1. "Tell me about the last time you [dealt with problem area]."
2. "Walk me through what happened from start to finish."
3. "What was the most frustrating part?"
4. "How often does this happen?"

### Current Solutions (10 min)
5. "What do you currently do to handle this?"
6. "What tools or processes do you use?"
7. "What do you like about your current approach?"
8. "What would you change if you could?"

### Quantifying Impact (10 min)
9. "How much time does this take you?"
10. "Have you ever lost money or opportunities because of this?"
11. "If this problem disappeared tomorrow, what would change?"

### Closing (5 min)
12. "Is there anything else about [problem area] that keeps you up at night?"
13. "Who else should I talk to about this?"

## Interview Log
| # | Date | Name/Role | Company | Key Quotes | Pain Points | Current Solution | Pay Signal |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |

## Patterns Identified
### Recurring Pain Points
1.
2.

### Common Workarounds
1.
2.

### Frequency & Severity
- How often:
- Impact level:

### Budget Signals
- Willingness to pay:
- Current spending on alternatives:

## Completion Checklist
- [ ] 10+ interviews completed
- [ ] 5+ different organizations
- [ ] Key patterns documented
- [ ] 3+ strong pain point quotes captured
```

---

## Validation Integrity Requirements

### User Group Separation

When interviewing multiple user groups, maintain clear separation:

| User Group | Validation Status | Action |
|------------|------------------|--------|
| **Primary users interviewed** | [VALIDATED] | Document fully in main sections |
| **Secondary users inferred** | [HYPOTHESIS] | Separate section with clear warnings |
| **Users not interviewed** | [NOT VALIDATED] | Acknowledge gap; create interview guide |

### Tagging Requirements

- All pain points from direct interviews: Tag with `[VALIDATED: Session X, Name]`
- Pain points inferred from observations: Tag with `[HYPOTHESIS: Source]`
- Pain points assumed from industry knowledge: Tag with `[ASSUMED]`

### Preventing Premature Specificity

**Do not** create detailed user journeys, feature requirements, or personas for user groups that haven't been interviewed. Instead:

1. Acknowledge the gap explicitly
2. Extract hypotheses to a separate document (IDEA-01b_Hypotheses.md)
3. Create an interview guide for future validation

### Example Separation

```markdown
# PART 1: INTERNAL USERS [VALIDATED]
[Content from direct interviews]

# PART 2: EXTERNAL CUSTOMERS [NOT VALIDATED]
No customer interviews conducted. Hypotheses extracted to IDEA-01b.
See Customer_Interview_Guide.md for validation approach.
```
