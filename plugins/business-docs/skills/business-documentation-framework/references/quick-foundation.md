# Quick Foundation Questions

Questions to gather essential information when users skip earlier documents.

---

## Table of Contents

- [When to Use This Guide](#when-to-use-this-guide)
- [Skip Scenario 1: Starting at IDEA-04 (Problem Statement)](#skip-scenario-1-starting-at-idea-04-problem-statement)
- [Skip Scenario 2: Starting at IDEA-09 (Lean Canvas)](#skip-scenario-2-starting-at-idea-09-lean-canvas)
- [Skip Scenario 3: Starting at IDEA-19 (Feasibility Assessment)](#skip-scenario-3-starting-at-idea-19-feasibility-assessment)
- [Skip Scenario 4: Starting at PRD (PROD-09 or PROD-29)](#skip-scenario-4-starting-at-prd-prod-09-or-prod-29)
- [Skip Scenario 5: Starting at TDD (TECH-02)](#skip-scenario-5-starting-at-tdd-tech-02)
- [General Guidance](#general-guidance)
- [Example Output Header for Skipped Foundation](#example-output-header-for-skipped-foundation)
- [Path Changes Mid-Process](#path-changes-mid-process)

---

## When to Use This Guide

Use these questions when:

- User wants to start mid-path (e.g., "I just need a PRD")
- User doesn't have time for full process
- Earlier documents don't exist in project

**Important:** Documents generated from Quick Foundation will have [ASSUMPTION] markers where information was inferred rather than validated.

---

## Skip Scenario 1: Starting at IDEA-04 (Problem Statement)

User skips: IDEA-01 (Interviews), IDEA-02 (JTBD)

### Questions to Ask (6 questions)

1. **Who is your target customer?**

   - Be specific: role, company size, industry
   - "Decision-makers at mid-size companies" is too vague
   - "Operations managers at 50-200 employee logistics companies" is good

2. **What problem are they facing?**

   - Describe the struggle in their words
   - What triggers this problem?
   - How often does it occur?

3. **What is the impact of this problem?**

   - Quantify if possible: hours lost, money wasted, opportunities missed
   - What happens if they don't solve it?

4. **What are they currently doing about it?**

   - Current workarounds or solutions
   - Why are these inadequate?

5. **How do you know this is a real problem?**

   - Personal experience? Customer conversations? Market research?
   - How many people have you talked to about this?

6. **What emotional frustration does this cause?**
   - Beyond practical impact, how does it make them feel?
   - Stressed? Embarrassed? Overwhelmed?

### Output Markers

```
[ASSUMPTION: Customer segment based on founder description, not validated interviews]
[ASSUMPTION: Problem severity estimated, not quantified from customer data]
```

---

## Skip Scenario 2: Starting at IDEA-09 (Lean Canvas)

User skips: IDEA-01 through IDEA-08

### Questions to Ask (7 questions)

1. **Who is your target customer segment?**

   - Specific characteristics, not demographics alone
   - What makes them a good fit for your solution?

2. **What top 3 problems are you solving?**

   - Rank by severity
   - Be specific: "Can't track inventory in real-time" not "inventory issues"

3. **What is your proposed solution?**

   - High-level description
   - What are the core features?

4. **What is your unique value proposition?**

   - Single, clear sentence
   - Why would someone choose you over alternatives?

5. **How will you reach customers?**

   - Acquisition channels
   - Sales approach (self-serve, sales-led, etc.)

6. **How will you make money?**

   - Revenue model: subscription, transaction, license?
   - Pricing approach

7. **What are your key metrics?**
   - How will you know if you're succeeding?
   - What numbers matter most in first 6 months?

### Output Markers

```
[ASSUMPTION: Problem validated through informal assessment, no JTBD analysis]
[ASSUMPTION: Value proposition not tested against customer alternatives]
```

---

## Skip Scenario 3: Starting at IDEA-19 (Feasibility Assessment)

User skips: IDEA-01 through IDEA-09

### Questions to Ask (7 questions)

1. **What are you building?** (1-2 sentence description)

2. **What technology stack do you plan to use?**

   - Frontend, backend, database, hosting
   - Any AI/ML components?

3. **What is your team's technical capability?**

   - Team size and roles
   - Technologies team knows well

4. **What is your budget range?**

   - Development budget
   - Monthly operating budget

5. **What is your timeline?**

   - When do you need MVP?
   - Any hard deadlines (demo, funding, etc.)?

6. **What existing systems must this integrate with?**

   - APIs, databases, third-party services
   - Authentication systems

7. **What similar products or tools exist?**
   - What alternatives have you evaluated?
   - Why build instead of buy?

### Output Markers

```
[ASSUMPTION: Market viability not assessed - feasibility only covers technical/financial]
[ASSUMPTION: Customer validation not performed]
```

---

## Skip Scenario 4: Starting at PRD (PROD-09 or PROD-29)

User skips: All ideation documents

### Questions to Ask (7 questions)

1. **What problem does this product solve?**

   - For whom?
   - How do you know this is a problem?

2. **What are the must-have features?**

   - List 3-5 core capabilities
   - What can you NOT launch without?

3. **What are the nice-to-have features?**

   - List features that could wait for v2
   - Why are these lower priority?

4. **Who are the target users?**

   - Describe 1-2 primary personas
   - What are their goals?

5. **How will you measure success?**

   - Key metrics for launch
   - What numbers indicate product-market fit?

6. **What are the constraints?**

   - Timeline, budget, technology
   - Regulatory or compliance requirements?

7. **What is explicitly out of scope?**
   - What will you NOT build?
   - What features are for future versions?

### Output Markers

```
[ASSUMPTION: Problem validation assumed based on founder knowledge]
[ASSUMPTION: User personas are hypothetical, not research-based]
[ASSUMPTION: Feature priorities based on founder judgment, not customer feedback]
```

---

## Skip Scenario 5: Starting at TDD (TECH-02)

User skips: All ideation + product documents

### Questions to Ask (7 questions)

1. **What system are you designing?**

   - Brief description of purpose
   - What problem does it solve?

2. **What are the functional requirements?**

   - List core capabilities
   - What must the system do?

3. **What are the non-functional requirements?**

   - Performance expectations (response time, throughput)
   - Scalability needs (concurrent users, data volume)
   - Security requirements

4. **What is the proposed architecture?**

   - High-level components
   - How do they interact?

5. **What technology stack?**

   - Languages, frameworks, databases
   - Why these choices?

6. **What alternatives did you consider?**

   - At least 2 alternative approaches
   - Why were they rejected?

7. **What are the biggest technical risks?**
   - What could go wrong?
   - How will you mitigate?

### Output Markers

```
[ASSUMPTION: Requirements based on verbal input, no formal PRD]
[ASSUMPTION: Business context inferred, not documented]
```

---

## General Guidance

### After Quick Foundation Questions

1. **Acknowledge the gaps:**
   "I'll create [Document] based on your answers. Note that this skips [earlier documents], so some assumptions will be marked."

2. **Generate with markers:**
   Include [ASSUMPTION] tags wherever information would normally come from skipped documents.

3. **Offer to backfill:**
   "If you'd like to validate these assumptions later, we can create [earlier document] to strengthen the foundation."

### When to Refuse Skip

If user wants to skip to a document that would be meaningless without foundation:

- **TECH-02 without any product context**: "I need at least a basic understanding of what we're building. Can you answer a few questions first?"
- **Pitch Deck without business model**: "Investors will ask about your business model. Let's at least capture the basics."

### Quality Trade-offs

| Documents Skipped | Quality Impact                      |
| ----------------- | ----------------------------------- |
| 1-2 documents     | Minor - mostly recoverable          |
| 3-4 documents     | Moderate - key assumptions marked   |
| 5+ documents      | Significant - recommend backfilling |

---

## Example Output Header for Skipped Foundation

```markdown
# [Document Name]

**ID:** [DOC-ID]
**Version:** 1.0
**Status:** Draft
**Created:** [Date]
**Foundation:** Quick Foundation (skipped IDEA-01 through IDEA-04)

> ⚠️ **Note:** This document was created using Quick Foundation Questions.
> Sections marked [ASSUMPTION] should be validated when time permits.
```

---

## Path Changes Mid-Process

When user needs to switch paths after documents have been created:

### Internal Tool → External Product (MVP/Investor)

Add these documents:

- IDEA-01 (Customer Interviews) - validate problem externally
- IDEA-02 (JTBD Analysis) - understand customer jobs
- IDEA-08 (Value Proposition Canvas) - articulate value
- Market analysis docs if going Investor path

Update existing documents:

- IDEA-04: Strengthen with external interview evidence
- IDEA-09: Expand all 9 blocks (was lite version)
- PROD-29 → PROD-09: Expand to full PRD

### MVP → Investor

Add these documents:

- IDEA-05 (Mission Statement)
- IDEA-06 (Vision Statement)
- IDEA-10 (Business Model Canvas)
- IDEA-11 (TAM/SAM/SOM Analysis)
- IDEA-12 (Porter's Five Forces)
- IDEA-14 (Competitive Analysis)
- IDEA-15 (Why Now Analysis)
- IDEA-16 (Pitch Deck) ⭐
- IDEA-20 (Build vs Buy Framework)

Existing documents remain valid - investor path builds on MVP foundation.

### Handling Path Changes

1. Acknowledge what's already complete
2. Identify gap documents needed
3. Generate gap documents in dependency order
4. Update any documents that need expansion
5. Continue with new path
