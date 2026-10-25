# Validation Integrity Guide

Ensuring validated facts are distinguished from hypotheses to prevent downstream confusion.

---

## Table of Contents

- [Why Validation Integrity Matters](#why-validation-integrity-matters)
- [Validation State Taxonomy](#validation-state-taxonomy)
- [Tagging Requirements](#tagging-requirements)
- [Premature Specificity Rules](#premature-specificity-rules)
- [Downstream Clarity Checklist](#downstream-clarity-checklist)
- [Validation Chain Dependencies](#validation-chain-dependencies)
- [Handling Unvalidated Content](#handling-unvalidated-content)
- [Document-Specific Guidance](#document-specific-guidance)

---

## Why Validation Integrity Matters

When documents blend validated facts with assumptions, downstream documents inherit false confidence. This causes:

1. **Premature Specificity** — Detailed specifications for unvalidated features
2. **Downstream Confusion** — Technical decisions based on assumptions treated as facts
3. **Wasted Effort** — Building features that solve assumed (not validated) problems
4. **False Confidence** — Stakeholders believing hypotheses are proven

**Principle:** The specificity of claims should be proportional to the evidence supporting them.

---

## Validation State Taxonomy

All significant claims in business documents should be tagged with their validation state:

### [VALIDATED]

Content confirmed through direct evidence:
- Customer interviews (with quotes)
- Quantitative data (with source)
- Observed behavior (documented)
- Experimental results (measured)

**Usage:** Use for claims that have been directly confirmed and can be relied upon for downstream decisions.

```markdown
Sales team spends 3-4 hours/week on manual spot reports. [VALIDATED: Session 6, Dom]
```

### [HYPOTHESIS]

Working assumptions based on analysis but not directly confirmed:
- Inferred from related evidence
- Logical deduction from validated facts
- Team analysis or expert opinion
- Industry precedent

**Usage:** Use for reasonable assumptions that inform planning but require validation before major investment.

```markdown
Ship owners want real-time risk dashboards. [HYPOTHESIS: Inferred from DG product usage]
```

### [ASSUMED]

Dependency assumptions that must be true for other claims to hold:
- Preconditions not yet verified
- External factors outside control
- Market or regulatory assumptions

**Usage:** Use for assumptions that create risk if invalidated.

```markdown
MariTrace API will remain available. [ASSUMED: No SLA documented]
```

### [PENDING-VALIDATION]

Content explicitly flagged for future research:
- Scheduled for upcoming interviews
- Planned experiment or test
- Awaiting external data

**Usage:** Use when validation is planned but not yet complete.

```markdown
Underwriters need real-time vessel data for pricing. [PENDING-VALIDATION: AJG interview scheduled]
```

---

## Tagging Requirements

### When to Tag

Tag validation state for:

| Content Type | Tagging Required |
|--------------|------------------|
| Customer pain points | Always |
| User jobs-to-be-done | Always |
| Success metrics/targets | Always |
| Feature requirements | Always |
| Technical constraints | When from external source |
| Market size claims | Always |
| Competitive assertions | Always |

### Where to Tag

**Inline tagging** for individual claims:
```markdown
Contact discovery takes 15-30 minutes per prospect. [VALIDATED: Session 4]
```

**Section-level tagging** for grouped content:
```markdown
## External Customer Jobs [NOT VALIDATED]

All jobs in this section are hypothesized and require customer interviews.
```

**Table column tagging** for structured data:
```markdown
| Pain Point | Severity | Validation |
|------------|----------|------------|
| Manual reports | High | [VALIDATED] |
| Alert fatigue | Medium | [HYPOTHESIS] |
```

---

## Premature Specificity Rules

### The Confidence-Specificity Principle

**Rule:** Specificity should not exceed confidence.

| Confidence Level | Appropriate Specificity |
|------------------|------------------------|
| [VALIDATED] | Detailed specs, exact numbers, precise requirements |
| [HYPOTHESIS] | Directional guidance, ranges, conditional statements |
| [ASSUMED] | Acknowledgment only, with risk flag |
| [PENDING-VALIDATION] | Placeholder with validation plan |

### Anti-Patterns to Avoid

#### 1. Assumed Specificity

**Bad:** Detailed customer journey maps based on internal assumptions
```markdown
## Customer Journey (HYPOTHETICAL)
| Step | Pain Point | Portal Feature |
| Request VRA | Manual process (assumed) | Self-service VRA request |
```

**Good:** Acknowledge the hypothesis and extract to separate document
```markdown
## Customer Journey
Customer journey details extracted to IDEA-02b pending validation.
See Customer_Interview_Guide.md for validation approach.
```

#### 2. False Precision

**Bad:** Specific numbers without evidence
```markdown
Customers want quotes in under 4 hours. [NO TAG]
```

**Good:** Acknowledge the hypothesis
```markdown
Customers may want faster quotes. [HYPOTHESIS: Based on Spot Ship positioning]
Validation needed: "What quote turnaround is acceptable?"
```

#### 3. Unvalidated Details in Validated Sections

**Bad:** Mixing validation states without distinction
```markdown
## Pain Points
- Manual spot reports: 3-4 hrs/week (validated)
- Alert fatigue from current tools (assumed)
- Limited risk visibility (assumed)
```

**Good:** Separate by validation state
```markdown
## Pain Points [VALIDATED]
- Manual spot reports: 3-4 hrs/week [Session 6]

## Pain Points [HYPOTHESIS] — See IDEA-02b
Pain points for external customers require validation.
```

---

## Downstream Clarity Checklist

Before a document enables downstream work, verify:

### For All Documents

```
- [ ] All claims tagged with validation state
- [ ] [VALIDATED] content has evidence citation
- [ ] [HYPOTHESIS] content has stated basis
- [ ] No untagged significant claims
- [ ] Hypothetical sections clearly separated
```

### For Gateway Documents (IDEA-04, IDEA-09, PROD-09, TECH-02)

```
- [ ] Core problem is [VALIDATED], not [HYPOTHESIS]
- [ ] Success metrics are [VALIDATED] or explicitly [HYPOTHESIS]
- [ ] Non-goals derived from [VALIDATED] scope constraints
- [ ] Technical decisions cite validation state of requirements
- [ ] Unvalidated requirements flagged as "conditional"
```

### For Handoff Documents

```
- [ ] Clear separation of validated vs pending validation
- [ ] Validation plan for [HYPOTHESIS] items
- [ ] Risk assessment for [ASSUMED] dependencies
- [ ] Implementation team knows what's proven vs assumed
```

---

## Validation Chain Dependencies

Certain claims must be validated before downstream decisions:

### Validation Chain Rules

| Claim Type | Must Be Validated Before |
|------------|-------------------------|
| Customer segment definition | Any feature for that segment |
| Pain point existence | Solution design for that pain |
| Success metric targets | Test plan using those metrics |
| Technical constraint | Architecture decision based on it |
| Market size | Fundraising projections |

### Blocking Validation

Some unvalidated content should block downstream progress:

| If Unvalidated... | Then Block... |
|-------------------|---------------|
| External customer jobs | Customer portal feature specs |
| Revenue model | Detailed financial projections |
| Technical feasibility | Sprint planning |
| Security requirements | Production deployment |

### Non-Blocking Validation

Some content can proceed with risk acknowledgment:

| If Unvalidated... | Can Proceed With... |
|-------------------|---------------------|
| Specific feature details | Prototypes (not production) |
| Exact metrics targets | Directional goals |
| Competitive positioning | Internal strategy docs |

---

## Handling Unvalidated Content

### Option 1: Extract to Hypothesis Document

For substantial unvalidated content, create a separate document:

```markdown
## [Section Name]

Content extracted to [DOC-ID]b_[Name]_Hypotheses.md pending validation.

**Action:** Complete [Validation_Guide.md] interviews before building features.
```

**When to use:** When hypothetical content is detailed enough to cause downstream confusion.

### Option 2: Inline Hypothesis Section

For smaller amounts of unvalidated content:

```markdown
## [Section Name] [HYPOTHESIS]

⚠️ Content below is hypothesized and requires validation.

[Content with inline tags]

**Validation Required:**
- [ ] [Specific validation action]
```

**When to use:** When hypothetical content is brief and clearly bounded.

### Option 3: Conditional Statements

For individual claims:

```markdown
If [assumption] is validated, then [specific claim]. [HYPOTHESIS]
```

**When to use:** For isolated claims that don't warrant separation.

---

## Document-Specific Guidance

Each document guide includes a **Validation Integrity** section with document-specific requirements. See individual guides:

| Document | Validation Focus |
|----------|------------------|
| **IDEA-01** | Separate internal (validated) vs external (hypothetical) interviews |
| **IDEA-02** | Tag job statements by evidence source; extract unvalidated jobs |
| **IDEA-04** ⭐ | Core problem must be [VALIDATED]; gateway blocked if hypothetical |
| **PROD-09** ⭐ | Features must trace to validated jobs; conditional features flagged |
| **TECH-02** ⭐ | Architecture decisions must cite requirement validation state |

---

## Quality Scoring Integration

Add validation clarity as a quality dimension:

| Dimension | Score 5 | Score 1 |
|-----------|---------|---------|
| **Validation Clarity** | All claims tagged, clear separation of validated vs hypothetical | No tags, assumptions mixed with facts |

**Threshold:** Gateway documents must score 4+ on Validation Clarity.

**Anti-Pattern to Flag:**
- "Untagged Assumptions" — Claims without validation state markers

---

## Summary

1. **Tag everything** — Use [VALIDATED], [HYPOTHESIS], [ASSUMED], [PENDING-VALIDATION]
2. **Separate clearly** — Don't mix validation states in the same section
3. **Extract when needed** — Move detailed hypotheses to separate documents
4. **Block appropriately** — Don't build on unvalidated foundations
5. **Plan validation** — Include how/when hypotheses will be tested

**Principle:** Better to acknowledge uncertainty than to create false confidence.
