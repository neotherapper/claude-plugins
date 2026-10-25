# Gateway Protocol

Validation and approval process for gateway documents.

---

## Table of Contents

- [What Are Gateways?](#what-are-gateways)
- [Gateway Documents](#gateway-documents)
- [Pre-Approval Quality Check](#pre-approval-quality-check)
- [Quality Scoring Rubric](#quality-scoring-rubric)
- [Anti-Pattern Detection](#anti-pattern-detection)
- [Issue Presentation Format](#issue-presentation-format)
- [Approval Request Format](#approval-request-format)
- [Approval Criteria by Gateway](#approval-criteria-by-gateway)
- [Post-Approval Actions](#post-approval-actions)
- [Handling Rejections](#handling-rejections)
- [Gateway Bypass (Not Recommended)](#gateway-bypass-not-recommended)

---

## What Are Gateways?

Gateway documents (marked with ⭐) are critical checkpoints that require explicit approval before proceeding. They validate that the foundation is solid before building on it.

---

## Gateway Documents

| ID      | Name                   | Path                | What It Validates               |
| ------- | ---------------------- | ------------------- | ------------------------------- |
| IDEA-04 | Problem Statement      | All                 | Problem is worth solving        |
| IDEA-09 | Lean Canvas            | MVP, Investor, Full | Business model is viable        |
| IDEA-16 | Pitch Deck             | Investor            | Investor readiness              |
| IDEA-19 | Feasibility Assessment | All                 | Technical/financial feasibility |
| PROD-09 | PRD                    | MVP, Investor       | Product scope is complete       |
| TECH-02 | Technical Design Doc   | All                 | Architecture is sound           |
| SEC-01  | Security Review        | Full                | Security posture is adequate    |

---

## Pre-Approval Quality Check

Before requesting gateway approval, verify:

### 1. Completeness Check

```
- [ ] All required sections are filled (no empty placeholders)
- [ ] All questions answered with substantive content
- [ ] Word count meets minimum (varies by document)
- [ ] All dependencies properly referenced
```

### 2. Quality Check

```
- [ ] Statements are specific, not vague
- [ ] Claims have supporting evidence or rationale
- [ ] Numbers are realistic and sourced where possible
- [ ] Risks and assumptions are explicitly stated
```

### 3. Consistency Check

```
- [ ] Customer segment matches earlier documents
- [ ] Problem statement is consistent
- [ ] Metrics align with prior commitments
- [ ] Terminology is identical throughout
```

---

## Quality Scoring Rubric

Score each gateway document on 6 dimensions (1-5 scale, max 30 points):

| Dimension | Description | Score 5 | Score 1 |
|-----------|-------------|---------|---------|
| **Clarity** | Understandable to target audience | Crystal clear, no ambiguity | Unclear, reader cannot understand intent |
| **Specificity** | Claims are measurable, not vague | All claims have specific metrics/dates | No specifics, entirely abstract |
| **Evidence** | Assumptions backed by data/quotes | Every claim has cited evidence | No evidence, all assumptions |
| **Actionability** | Clear next steps defined | Anyone can execute immediately | Not actionable, no clear path |
| **Consistency** | Aligns with prior documents | Perfect alignment, terms match | Contradicts other documents |
| **Validation Clarity** | Validated vs hypothetical clearly distinguished | All claims tagged, clear separation | Assumptions mixed with facts, no tags |

### Thresholds

| Document Type | Minimum Total | Minimum Per Dimension |
|---------------|---------------|----------------------|
| Gateway documents | **24/30** | **4/5** |
| Critical path documents | 21/30 | 3/5 |
| Other documents | 18/30 | 3/5 |

**Blocking dimensions:** Consistency and Validation Clarity must score 4+ on ALL documents.

See **validation-integrity-guide.md** for detailed validation state taxonomy and tagging requirements.

---

## Anti-Pattern Detection

Common issues to flag before approval:

### IDEA-04 Issues (Problem Statement)

| Anti-Pattern | Indicators | Fix |
|--------------|------------|-----|
| **Vague Problem** | Uses "users" without segment, "improve" without metrics | Add specific customer segment, quantify impact |
| **Solution-First** | Problem description includes solution features | Remove solution language, focus on underlying needs |
| **No Evidence** | No customer quotes or data points | Add interview quotes, research citations |

### IDEA-09 Issues (Lean Canvas)

| Anti-Pattern | Indicators | Fix |
|--------------|------------|-----|
| **Empty Blocks** | TBD, TODO, single words, copied template text | Complete all blocks with specific content |
| **Wishful Metrics** | "Increase revenue" without numbers | Add quantified targets with timeframes |

### PROD-09 Issues (PRD)

| Anti-Pattern | Indicators | Fix |
|--------------|------------|-----|
| **Feature Soup** | >20 features without P0/P1/P2 prioritization | Prioritize ruthlessly, add metrics per feature |
| **Missing Non-Goals** | No out-of-scope section | Add explicit "what we're NOT building" |
| **Untraceable Stories** | User stories don't link to problems | Add traceability to IDEA-04 problems |

### TECH-02 Issues (TDD)

| Anti-Pattern | Indicators | Fix |
|--------------|------------|-----|
| **Buzzword Architecture** | Technology choices without justification | Justify each choice, add specific numbers |
| **No Alternatives** | Only one approach considered | Consider and document 2+ alternatives |
| **Missing Security** | No security considerations section | Add threat model, auth approach |

### All Documents — Validation Integrity Issues

| Anti-Pattern | Indicators | Fix |
|--------------|------------|-----|
| **Untagged Assumptions** | Claims without [VALIDATED]/[HYPOTHESIS] markers | Add validation state tags to all significant claims |
| **Premature Specificity** | Detailed specs for unvalidated requirements | Extract to hypothesis document OR reduce specificity |
| **Mixed Validation States** | Validated and hypothetical content in same section | Separate clearly or add section-level tags |
| **Missing Evidence Links** | [VALIDATED] tags without source citation | Add interview session, data source, or quote |

See **validation-integrity-guide.md** for complete validation state taxonomy.

---

## Issue Presentation Format

If issues are found during quality check, present them clearly:

```
## Gateway Review: [DOC-ID] [Name]

### Issues Found:

1. **[Category]**: [Specific issue]
   - Location: [Section]
   - Impact: [Why this matters]
   - Suggested fix: [How to resolve]

2. **[Category]**: [Specific issue]
   ...

### Recommended Action:
[ ] Address issues before approval
[ ] Proceed with noted caveats
```

Issue Categories:

- **Completeness**: Missing required content
- **Consistency**: Conflicts with earlier documents
- **Quality**: Vague or unsupported claims
- **Dependency**: Missing prerequisite information

---

## Approval Request Format

When document passes quality check:

```
---
## Gateway Approval Request

**Document:** [DOC-ID] [Name]
**Path:** [Current Path]
**Status:** Ready for Review

### Summary
[2-3 sentences describing what this document establishes]

### Key Decisions Made
1. [Decision 1]
2. [Decision 2]
3. [Decision 3]

### Dependencies Verified
- ✅ [DEP-ID]: [One line summary of what was extracted]
- ✅ [DEP-ID]: [One line summary]

### Quality Checklist
- ✅ All sections complete
- ✅ Consistency verified
- ✅ Evidence/rationale provided

### What This Unlocks
Approval enables proceeding to: [NEXT-DOC-ID] [Name]

---
**Do you approve this document to proceed?** (yes/no/revise)
```

---

## Approval Criteria by Gateway

### IDEA-04 (Problem Statement)

**Must demonstrate:**

- Clear customer segment definition
- Specific, quantified problem
- Evidence from interviews or research
- Impact if problem remains unsolved

**Approval unlocks:** IDEA-08, IDEA-09

---

### IDEA-09 (Lean Canvas)

**Must demonstrate:**

- All relevant blocks completed
- Problem-solution fit is logical
- Revenue model is realistic
- Key metrics are measurable
- Unfair advantage is defensible

**Approval unlocks:** IDEA-19, PROD-17

---

### IDEA-16 (Pitch Deck)

**Must demonstrate:**

- Compelling narrative flow
- Market size justified with sources
- Team credibility established
- Ask amount and use of funds clear
- All previous analysis incorporated

**Approval unlocks:** Investor outreach

---

### IDEA-19 (Feasibility Assessment)

**Must demonstrate:**

- Technical feasibility assessed realistically
- Financial projections are grounded
- AI acceleration opportunities identified
- Build vs buy recommendation clear
- Timeline is achievable

**Approval unlocks:** PROD-09 or PROD-29

---

### PROD-09 (PRD)

**Must demonstrate:**

- Complete functional requirements
- Non-functional requirements specified
- User stories with acceptance criteria
- Success metrics are measurable
- Scope is bounded (explicit out-of-scope)

**Approval unlocks:** TECH-02

---

### TECH-02 (Technical Design Document)

**Must demonstrate:**

- Architecture addresses all requirements
- Technology choices are justified
- Alternatives were considered
- Risks are identified with mitigations
- C4 diagrams at minimum Level 1-2

**Approval unlocks:** Implementation, OPS-01+

---

### SEC-01 (Security Review)

**Must demonstrate:**

- Threat model complete
- Security controls identified
- Compliance requirements addressed
- Incident response plan outlined
- Third-party dependencies assessed

**Approval unlocks:** Production deployment

---

## Post-Approval Actions

After approval:

1. **Mark document as approved:**

   ```
   **Status:** Approved
   **Approved:** [Date]
   ```

2. **Announce next step:**

   ```
   ✅ [DOC-ID] approved!
   → Next: [NEXT-DOC-ID] [Name]
   Ready to proceed?
   ```

3. **Do NOT revisit approved content** unless user explicitly requests revision

---

## Handling Rejections

If user says "no" or "revise":

1. Ask: "What specific concerns do you have?"
2. Identify which sections need revision
3. Make targeted edits (don't regenerate entire document)
4. Re-present approval request

---

## Gateway Bypass (Not Recommended)

If user insists on skipping a gateway:

1. Warn: "Skipping [Gateway] may cause issues with [downstream docs]"
2. If user confirms, proceed with warning marker:
   ```
   **Warning:** This document was generated without approved [DEPENDENCY].
   Consider revisiting if foundational assumptions change.
   ```
3. Continue to next document but note the skip
