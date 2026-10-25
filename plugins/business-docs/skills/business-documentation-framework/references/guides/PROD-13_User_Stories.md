# Generation Guide: PROD-13 User Stories

**Purpose:** Break down epics into discrete, deliverable units of user value using the INVEST criteria and standard user story format.

---

## Prerequisites
- PROD-12 Epic Definition
- PROD-03 Personas (soft dependency — provides user role definitions)

## Questions to Ask the User
- What is the primary user persona for this story? (reference PROD-03 if available)
- What specific action does the user need to accomplish?
- What value or benefit does this action provide to the user?
- Does this story pass all six INVEST criteria?
- Can this story be completed within a single sprint?
- What is the priority level (P0, P1, P2)?

## INVEST Criteria Checklist

Before finalizing each story, validate against INVEST:

| Criterion | Question | Pass/Fail |
|-----------|----------|-----------|
| **I**ndependent | Can this story be developed without dependencies on other stories? | |
| **N**egotiable | Is the scope flexible enough to adjust during implementation? | |
| **V**aluable | Does this deliver clear value to the user or business? | |
| **E**stimable | Can the team reasonably estimate the effort required? | |
| **S**mall | Can this be completed within one sprint (typically ≤8 story points)? | |
| **T**estable | Can we write acceptance criteria that verify completion? | |

## Document Template

```markdown
# User Stories: [Epic Name]

**ID:** PROD-13
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-12 (Epic Definition)
**Gateway:** No

---

## 1. Epic Reference
**Epic ID:** [PROD-12 reference]
**Epic Name:** [Name from PROD-12]
**Epic Objective:** [Brief objective statement]

---

## 2. User Stories

### US-001: [Story Title]
**Priority:** P0 | P1 | P2
**Story Points:** [1-8]
**Sprint Target:** [Sprint number or TBD]

**User Story:**
> As a **[user role/persona]**,
> I want to **[action/capability]**,
> So that **[benefit/value]**.

**INVEST Validation:**
- [ ] Independent
- [ ] Negotiable
- [ ] Valuable
- [ ] Estimable
- [ ] Small
- [ ] Testable

**Acceptance Criteria Preview:**
1. **GIVEN** [precondition], **WHEN** [action], **THEN** [expected result]
2. **GIVEN** [precondition], **WHEN** [action], **THEN** [expected result]

**Dependencies:** [Other stories this depends on, if any]
**Notes:** [Implementation hints, technical considerations]

---

### US-002: [Story Title]
**Priority:** P0 | P1 | P2
**Story Points:** [1-8]
**Sprint Target:** [Sprint number or TBD]

**User Story:**
> As a **[user role/persona]**,
> I want to **[action/capability]**,
> So that **[benefit/value]**.

**INVEST Validation:**
- [ ] Independent
- [ ] Negotiable
- [ ] Valuable
- [ ] Estimable
- [ ] Small
- [ ] Testable

**Acceptance Criteria Preview:**
1. **GIVEN** [precondition], **WHEN** [action], **THEN** [expected result]

**Dependencies:** [Other stories this depends on, if any]
**Notes:** [Implementation hints, technical considerations]

---

## 3. Story Map Overview

| Priority | Story ID | Title | Points | Sprint |
|----------|----------|-------|--------|--------|
| P0 | US-001 | [Title] | [pts] | [sprint] |
| P0 | US-002 | [Title] | [pts] | [sprint] |
| P1 | US-003 | [Title] | [pts] | [sprint] |

---

## 4. Traceability Matrix

| Story ID | PRD Requirement | Epic | Persona |
|----------|-----------------|------|---------|
| US-001 | [REQ-XXX from PROD-09] | [Epic ID] | [Persona name from PROD-03] |
| US-002 | [REQ-XXX from PROD-09] | [Epic ID] | [Persona name from PROD-03] |

---

## 5. Non-Functional Stories (if applicable)

### NFR-001: Performance Baseline
**Type:** Performance
**Story:**
> As a **system administrator**,
> I want the **[feature] to respond within [X]ms**,
> So that **users experience acceptable performance**.

**Acceptance Criteria:**
- [ ] 95th percentile response time < [X]ms under normal load
- [ ] System handles [Y] concurrent users

---

## 6. Definition of Done

All stories in this document are considered "Done" when:

- [ ] Code complete and peer-reviewed
- [ ] Unit tests written and passing
- [ ] Acceptance criteria verified
- [ ] No critical or high-severity bugs
- [ ] Documentation updated (if applicable)
- [ ] Product Owner acceptance received
```

## Completion Checklist

- [ ] All stories reference the parent epic from PROD-12
- [ ] Each story follows the "As a... I want... So that..." format
- [ ] INVEST criteria validated for each story
- [ ] At least one acceptance criterion per story (Given-When-Then)
- [ ] Stories are prioritized (P0, P1, P2)
- [ ] Story points assigned (or marked for refinement)
- [ ] Traceability to PRD requirements established
- [ ] Definition of Done documented

## Translation from JTBD

When converting Jobs-to-be-Done (IDEA-02) to User Stories:

**Job Story (WHY):** "When monitoring vessel traffic in a busy shipping lane, I want to receive automated alerts for anomalous behavior, so I can respond to security threats before they escalate."

**User Stories (WHAT):**
- US-001: As a maritime security officer, I want to set alert thresholds for vessel speed anomalies, so that I can customize sensitivity to my operational needs.
- US-002: As a maritime security officer, I want to receive push notifications when a vessel deviates from its declared route, so that I can investigate immediately.
- US-003: As a maritime security officer, I want to view historical alert data for a specific vessel, so that I can identify patterns of suspicious behavior.

**Rule:** One Job Story may become multiple User Stories. The Job Story captures WHY; User Stories capture WHAT.
