# Extraction Guide

What to extract from dependency documents when generating new documents.

---

## Table of Contents

- [How to Use This Guide](#how-to-use-this-guide)
- [IDEA-02 (JTBD Analysis)](#idea-02-jtbd-analysis)
- [IDEA-04 (Problem Statement)](#idea-04-problem-statement)
- [IDEA-08 (Value Proposition Canvas)](#idea-08-value-proposition-canvas)
- [IDEA-09 (Lean Canvas)](#idea-09-lean-canvas)
- [IDEA-18 (Opportunity Solution Tree) - Optional](#idea-18-opportunity-solution-tree---optional)
- [IDEA-19 (Feasibility Assessment)](#idea-19-feasibility-assessment)
- [IDEA-21 (Cross-Domain Strategic Synthesis) - Optional](#idea-21-cross-domain-strategic-synthesis---optional)
- [IDEA-20 (Build vs Buy Framework)](#idea-20-build-vs-buy-framework)
- [PROD-17 (MVP Canvas)](#prod-17-mvp-canvas)
- [PROD-18 (Hypothesis Documentation)](#prod-18-hypothesis-documentation)
- [PROD-09 (PRD) - MVP/Investor Path](#prod-09-prd---mvpinvestor-path)
- [PROD-29 (One-Pager PRD) - Internal Tool Path](#prod-29-one-pager-prd---internal-tool-path)
- [TECH-02 (Technical Design Document)](#tech-02-technical-design-document)
- [OPS-01 (README)](#ops-01-readme)
- [Consistency Verification](#consistency-verification)

---

## How to Use This Guide

Before generating any document:

1. Identify required dependencies from path-dependencies.md
2. Search project for each dependency document
3. Extract the specific fields listed below
4. Include extracted information with citations: "From IDEA-04: [exact quote]"

---

## IDEA-02 (JTBD Analysis)

### When generating, extract from IDEA-01 (Customer Interviews):

- Interview participant count and roles
- Key quotes about struggles (2-3)
- Observed behaviors vs stated preferences
- Emotional language used

---

## IDEA-04 (Problem Statement)

### When generating, extract from IDEA-02 (JTBD):

| Field                                 | Where It Goes             |
| ------------------------------------- | ------------------------- |
| Primary job statement (exact wording) | Job definition section    |
| Top 3 functional jobs                 | Problem context           |
| Top 2 emotional jobs                  | Emotional impact section  |
| Key interview quotes (2-3)            | Evidence section          |
| Four Forces analysis                  | Why customers will switch |

### For multi-domain initiatives, also extract from IDEA-21 (if exists):

| Field                            | Where It Goes                    |
| -------------------------------- | -------------------------------- |
| Meta-root-cause patterns         | Platform-level problem context   |
| Strategic implications           | Solution direction hints         |
| Shared infrastructure needs      | Technical constraints            |
| Vendor/dependency risks          | Risk acknowledgment              |

### For Internal Tool Path (no IDEA-02):

Use Quick Foundation Questions instead.

---

## IDEA-08 (Value Proposition Canvas)

### When generating, extract from IDEA-04:

| Field                                | Where It Goes      |
| ------------------------------------ | ------------------ |
| Customer segment (exact wording)     | Customer Profile   |
| Problem statement (4-part format)    | Customer Pains     |
| Quantified impact numbers            | Pain severity      |
| Current alternatives and limitations | Existing solutions |

---

## IDEA-09 (Lean Canvas)

### When generating, extract from IDEA-04:

| Field                   | Where It Goes            |
| ----------------------- | ------------------------ |
| Customer segment        | CUSTOMER SEGMENTS block  |
| Problem (4-part format) | PROBLEM block            |
| Current alternatives    | EXISTING ALTERNATIVES    |
| Quantified impact       | Problem severity context |

### When generating, extract from IDEA-08:

| Field                    | Where It Goes          |
| ------------------------ | ---------------------- |
| Unique Value Proposition | UVP block              |
| Pain relievers           | SOLUTION block         |
| Gains                    | KEY METRICS foundation |

### Internal Tool Adaptation:

Focus on 4 blocks: Problem, Solution, Key Metrics, Cost Structure
Skip: Channels, Revenue Streams, Customer Relationships

---

## IDEA-18 (Opportunity Solution Tree) - Optional

### When generating, extract from IDEA-09:

| Field               | Where It Goes         |
| ------------------- | --------------------- |
| Problem statement   | Outcome definition    |
| Customer segment    | Who we're solving for |
| Key metrics         | Success criteria      |
| Solution hypothesis | Solution branches     |

---

## IDEA-19 (Feasibility Assessment)

### When generating, extract from IDEA-09:

| Field             | Where It Goes                     |
| ----------------- | --------------------------------- |
| Solution features | Technical Feasibility scope       |
| Revenue model     | Financial Feasibility assumptions |
| Key metrics       | Success criteria                  |
| Cost structure    | Budget requirements               |
| Unfair advantage  | Competitive moat analysis         |

### For AI-Era Assessment, also consider:

- AI acceleration potential for each component
- Build vs buy candidates (off-the-shelf vs custom)
- 6-month viability window

---

## IDEA-21 (Cross-Domain Strategic Synthesis) - Optional

Use this document only for multi-domain/platform initiatives with 2+ IDEA-03 analyses.

### When generating, extract from IDEA-03 (multiple):

| Field                          | Where It Goes                 |
| ------------------------------ | ----------------------------- |
| Root causes per domain         | Root Cause Summary by Domain  |
| Intervention points            | Strategic Implications        |
| Evidence quotes                | Pattern Evidence              |

### When generating, extract from IDEA-01:

| Field                          | Where It Goes                 |
| ------------------------------ | ----------------------------- |
| Interview quotes about patterns | Pattern Evidence section     |
| Cross-domain observations      | Pattern Recognition           |

### When generating, extract from IDEA-02:

| Field                          | Where It Goes                 |
| ------------------------------ | ----------------------------- |
| Job statements spanning domains | Shared Infrastructure needs  |
| Common pain points             | Meta-Root-Cause Patterns      |

### What downstream documents extract from IDEA-21:

IDEA-04 extracts:
- Meta-root-cause patterns → Platform-level problem articulation
- Strategic implications → Solution direction
- Shared infrastructure requirements → Technical constraints

IDEA-19 extracts:
- Vendor/Dependency risks → Risk assessment section

---

## IDEA-20 (Build vs Buy Framework)

### When generating, extract from IDEA-19:

| Field                       | Where It Goes               |
| --------------------------- | --------------------------- |
| Technical feasibility notes | Build complexity assessment |
| Financial feasibility       | Cost comparison             |
| AI acceleration notes       | AI tool evaluation          |
| Timeline requirements       | Time-to-market analysis     |

---

## PROD-17 (MVP Canvas)

### When generating, extract from IDEA-09:

| Field            | Where It Goes      |
| ---------------- | ------------------ |
| Problem          | Core hypothesis    |
| Solution         | Feature candidates |
| Key metrics      | Success metrics    |
| Unfair advantage | Differentiation    |

---

## PROD-18 (Hypothesis Documentation)

### When generating, extract from PROD-17:

| Field              | Where It Goes         |
| ------------------ | --------------------- |
| Core assumptions   | Hypothesis statements |
| Feature candidates | Experiment subjects   |
| Success metrics    | Validation criteria   |
| Risk factors       | Assumption risks      |

---

## PROD-09 (PRD) - MVP/Investor Path

### When generating, extract from IDEA-04:

| Field             | Where It Goes       |
| ----------------- | ------------------- |
| Problem statement | Section 2: Problem  |
| Customer segment  | Personas foundation |
| Quantified impact | Business case       |

### When generating, extract from IDEA-09:

| Field          | Where It Goes        |
| -------------- | -------------------- |
| Solution       | Feature requirements |
| Key metrics    | Success metrics      |
| Cost structure | Resource constraints |

### When generating, extract from IDEA-19:

| Field                         | Where It Goes               |
| ----------------------------- | --------------------------- |
| Build vs Buy recommendation   | Architecture constraints    |
| Technical feasibility notes   | Non-functional requirements |
| AI acceleration opportunities | Implementation approach     |

### When generating, extract from PROD-18:

| Field                | Where It Goes             |
| -------------------- | ------------------------- |
| Validated hypotheses | Prioritized features      |
| Experiment results   | Evidence for requirements |
| Failed hypotheses    | Out of scope              |

---

## PROD-29 (One-Pager PRD) - Internal Tool Path

### When generating, extract from IDEA-19:

| Field                       | Where It Goes           |
| --------------------------- | ----------------------- |
| Feasibility assessment      | Constraints section     |
| Build vs buy recommendation | Implementation approach |
| Success criteria            | Definition of done      |

### When generating, extract from IDEA-09:

| Field       | Where It Goes      |
| ----------- | ------------------ |
| Problem     | Problem statement  |
| Solution    | Must-have features |
| Key metrics | Success metrics    |

---

## TECH-02 (Technical Design Document)

### For MVP/Investor Path, extract from PROD-09:

| Field                       | Where It Goes                  |
| --------------------------- | ------------------------------ |
| All functional requirements | Design scope (Sections 4-5)    |
| Non-functional requirements | Performance, security sections |
| User stories (prioritized)  | Feature breakdown              |
| Success metrics             | Monitoring requirements        |
| Out of scope                | Non-goals section              |

### For Internal Tool Path, extract from PROD-29:

| Field                 | Where It Goes            |
| --------------------- | ------------------------ |
| Problem statement     | Background section       |
| Must-have features    | Design scope             |
| Success metrics       | Monitoring requirements  |
| Scope boundaries      | Non-goals section        |
| Technical constraints | Architecture constraints |

### From IDEA-19 or IDEA-20:

| Field                       | Where It Goes         |
| --------------------------- | --------------------- |
| Build vs Buy decision       | Architecture approach |
| Technical feasibility notes | Technology choices    |
| AI acceleration potential   | Development approach  |
| Integration requirements    | System interfaces     |

---

## OPS-01 (README)

### When generating, extract from TECH-02:

| Field               | Where It Goes         |
| ------------------- | --------------------- |
| System architecture | Architecture overview |
| Technology stack    | Prerequisites         |
| Component list      | Project structure     |
| Build commands      | Installation section  |
| API endpoints       | Usage section         |

---

## Consistency Verification

After generating any document, verify:

```
Consistency Check:
- [ ] Customer segment matches IDEA-04: "[exact phrase]"
- [ ] Problem statement matches IDEA-04: "[first sentence]"
- [ ] Success metrics use same numbers as IDEA-09/PROD-09
- [ ] Terminology is identical (no synonyms for same concept)
```

If inconsistency found:

1. Flag to user
2. Ask which version is correct
3. Recommend updating earlier document if needed

---

## Validation State Verification

When extracting content, verify and preserve validation state:

### Extraction Rules by Validation State

| Source Validation State | Extraction Action |
|------------------------|-------------------|
| **[VALIDATED]** | Extract with citation; can be used for downstream decisions |
| **[HYPOTHESIS]** | Extract with tag preserved; flag as conditional in new doc |
| **[ASSUMED]** | Extract with risk flag; document invalidation impact |
| **[PENDING-VALIDATION]** | Either exclude OR extract with "blocked until validated" flag |

### Validation State Check

```
Validation Check:
- [ ] All extracted [VALIDATED] content has source citation
- [ ] [HYPOTHESIS] content is not treated as fact in new document
- [ ] [ASSUMED] dependencies are flagged as risks
- [ ] New document doesn't increase confidence beyond source
```

### Preventing Confidence Inflation

**Rule:** A downstream document cannot treat hypothetical content as validated.

| Source Document | Source State | New Document | Maximum New State |
|-----------------|--------------|--------------|-------------------|
| IDEA-01 | [VALIDATED] | IDEA-02 | [VALIDATED] |
| IDEA-01 | [HYPOTHESIS] | IDEA-02 | [HYPOTHESIS] |
| IDEA-02 | [HYPOTHESIS] | IDEA-04 | [HYPOTHESIS] — cannot become [VALIDATED] |
| IDEA-04 | [HYPOTHESIS] | PROD-09 | [CONDITIONAL] — must flag as pending |

**Anti-Pattern:** "Assumption laundering" — where hypotheses become treated as facts through document chain.

See **validation-integrity-guide.md** for complete taxonomy and tagging requirements.
