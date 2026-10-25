# Generation Guide: IDEA-04 Problem Statement (GATEWAY)

**Purpose:** Crystallize the specific problem being solved, supported by evidence, to gate transition into solution design.

---

## Prerequisites
- IDEA-02 JTBD Analysis
- (Optional) IDEA-03 5 Whys

## Extraction from IDEA-02
- Primary job statement → Foundation for description
- Functional/Emotional jobs → Impact details
- Interview quotes → Supporting evidence
- Alternatives hired → Current alternatives section

## Questions to Ask the User
- Based on your research, who exactly experiences this problem?
- What is the quantified impact (time, money, frustration)?
- What evidence proves this problem is worth solving?

## Document Template

```markdown
# Problem Statement

**ID:** IDEA-04
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Dependencies:** IDEA-02
**Gateway:** Yes

---

## The Problem (4-Part Format)
**[Customer segment]** struggles with **[specific problem]**.
This causes **[negative outcomes with numbers]**.
Currently, they try to solve this by **[existing solutions]**.
But these solutions fail because **[specific limitations]**.

## Customer Segment
- **Who:** [Specific role/title]
- **Context:** [Company size, industry, situation]
- **Market size:** [Number of people/companies affected]

## Problem Specifics
- **Primary pain:**
- **Trigger:** What event causes this problem?

## Quantified Impact
| Metric | Value | Source |
|---|---|---|
| Time lost | | Interview data |
| Money lost | | Interview data |

## Current Alternatives
| Alternative | What's Good | What's Bad | Why Still Used |
|---|---|---|---|
| | | | |

## Why Now?
What has changed that makes this problem solvable/urgent now?
1.
2.

## Supporting Evidence
### Key Interview Quotes
> "[Quote]" — [Role, Context]

## Validation Checklist
- [ ] Based on 10+ customer interviews
- [ ] Impact quantified with specific numbers
- [ ] Customer segment specific and reachable
- [ ] Existing alternatives documented with limitations

## Gateway Approval
**Required approvers:** Founder, Product Lead

| Approver | Role | Status | Date |
|---|---|---|---|
| | Founder | ☐ Pending | |
| | PM | ☐ Pending | |
```

---

## Validation Integrity Requirements (Gateway)

### Core Problem Must Be Validated

As a gateway document, IDEA-04 has strict validation requirements:

| Section | Required Validation State | Gateway Blocked If |
|---------|--------------------------|-------------------|
| **Customer segment** | [VALIDATED] | Segment not interviewed |
| **Problem statement** | [VALIDATED] | Based only on assumptions |
| **Quantified impact** | [VALIDATED] or [HYPOTHESIS with plan] | No evidence provided |
| **Current alternatives** | [VALIDATED] | No research on alternatives |

### Do Not Approve If

- Core customer segment hasn't been directly interviewed
- Impact numbers are assumed without evidence
- Problem statement derived from hypothetical jobs (IDEA-02b content)

### Handling Multiple User Groups

If IDEA-02 separates validated vs hypothetical jobs:

```markdown
## The Problem (4-Part Format)

**[Internal Team — VALIDATED]** struggles with **[specific problem]**.

---

## External Customer Problem [NOT VALIDATED]

External customer problems require validation before including in this gateway.
See IDEA-02b for hypotheses awaiting customer interviews.
```

### Validation Checklist Expansion

Add to standard checklist:
```
- [ ] Problem based on [VALIDATED] jobs from IDEA-02
- [ ] Impact numbers have source citations
- [ ] No [HYPOTHESIS] content treated as fact
- [ ] Unvalidated user groups acknowledged as gaps
```
