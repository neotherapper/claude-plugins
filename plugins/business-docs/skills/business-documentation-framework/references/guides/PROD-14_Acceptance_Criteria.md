# Generation Guide: PROD-14 Acceptance Criteria

**Purpose:** Define the specific conditions that a user story must satisfy to be considered complete and correct.

---

## Prerequisites
- PROD-13 User Stories

## Questions to Ask the User
- What are the positive paths (happy paths) for this story?
- What are the negative paths (error handling)?
- What specific data or state is required before the action?

## Document Template

```markdown
# Acceptance Criteria: [User Story Title]

**ID:** PROD-14
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-13
**Gateway:** No

---

## Scenario 1: [Positive Path Name]
- **GIVEN** [Precondition]
- **WHEN** [Action/Trigger]
- **THEN** [Expected Outcome]

## Scenario 2: [Negative/Error Path]
- **GIVEN** [Precondition]
- **WHEN** [Action/Trigger]
- **THEN** [Error Message/Recovery]

## Scenario 3: [Edge Case]
...

## Non-Functional Criteria
- **Performance:** [Response time < X ms]
- **Security:** [Auth required]
```
