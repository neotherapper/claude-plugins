# Generation Guide: PROD-25 Test Cases / QA Documentation

**Purpose:** Provide a structured plan for manual and automated verification of features.

---

## Prerequisites
- PROD-14 Acceptance Criteria

## Questions to Ask the User
- What is the required test coverage (%)?
- Which browsers/devices must be verified?
- What is the data setup required for testing?

## Document Template

```markdown
# Test Cases: [Feature Name]

**ID:** PROD-25
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** PROD-14
**Gateway:** No

---

## Test Environment
- **Platform:** [Web/iOS/Android]
- **Version:** [Development/Staging]

## Manual Test Cases
| ID | Action | Expected Result | Status |
|---|---|---|---|
| TC-1 | | | |

## Automated Tests
- **Unit:** [List critical functions]
- **E2E:** [List critical flows]
```
