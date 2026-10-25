# Business-to-Code Handoff Bridge

Bridges Business Documentation Framework (ending at TECH-02) with AI development tools (Memory Bank, task-master).

---

## Table of Contents

- [The Seven Essential Information Categories](#the-seven-essential-information-categories)
- [Handoff Document Template](#handoff-document-template)
- [Memory Bank Population Rules](#memory-bank-population-rules)
- [task-master Integration](#task-master-integration)
- [Verification Checklist](#verification-checklist)

---

## The Seven Essential Information Categories

These categories must survive the handoff from business documentation to implementation. Every handoff artifact must preserve all seven.

| # | Category | Source | What It Prevents |
|---|----------|--------|------------------|
| 1 | **Problem Definition** | IDEA-04 | Building solutions to wrong problems |
| 2 | **Success Metrics** | PROD-18, PROD-09 | Unable to close validation loop |
| 3 | **Constraints/Appetite** | IDEA-09, PROD-09 | Scope creep, missed deadlines |
| 4 | **Non-Goals/No-Gos** | PROD-09, TECH-02 | Scope creep during implementation |
| 5 | **Key Decisions Made** | TECH-02 (sections 8-12) | Re-debating resolved questions |
| 6 | **User Context** | IDEA-01, IDEA-02 | Wrong technical assumptions |
| 7 | **Business Rationale** | IDEA-09 | Wrong prioritization |

---

## Handoff Document Template

Create this document after completing the path's final gateway document (TECH-02).

**File name:** `handoff-[feature-name].md`

```markdown
# Feature Handoff: [Feature Name]

## Metadata
- Source PRD: PROD-09 v[X]
- Source TDD: TECH-02 v[X]
- Created: [Date]
- Hypothesis ID: [Link to PROD-18 hypothesis]
- Recommended Workflow: [Small/Medium/Large]

---

## 1. Problem Definition
[Extract from IDEA-04 Problem Statement]

**Customer Segment:** [Exact wording from IDEA-04]

**Pain Point:** [Specific problem being solved]

**Current Workaround:** [How users solve this today]

**Why Status Quo Fails:** [Specific story showing why current approach breaks down]

---

## 2. Success Criteria
[Extract from PROD-18 Hypothesis Documentation]

**Hypothesis:** We believe [this change] will result in [this outcome]. We will know we're right when [measurable criteria].

**Primary Metric:** [Quantified outcome with target]

**Secondary Metrics:**
- [Supporting measure 1]
- [Supporting measure 2]

**Validation Method:** [How we'll verify success - A/B test, user interviews, etc.]

---

## 3. Solution Boundaries

**Appetite:** [Time constraint - e.g., "6 weeks maximum"]

**In Scope:**
- [Capability 1]
- [Capability 2]
- [Capability 3]

**No-Gos (Explicitly Excluded):**
- [Feature explicitly not included]
- [Scope explicitly avoided]

**Assumptions:**
- [What we're assuming to be true]

---

## 4. Key Technical Decisions
[Extract from TECH-02 sections 8-12]

**Architecture Pattern:** [Choice] because [rationale]

**Data Model:** [Core entities and relationships]

**Integration Points:**
- [External dependency 1]
- [External dependency 2]

**Security Considerations:**
- [Key constraint or requirement]

**Technology Choices:**
- [Framework/library]: [Reason for selection]

---

## 5. Acceptance Criteria
[Derived from JTBD context in IDEA-02]

| Criterion | Verification Method |
|-----------|---------------------|
| [Specific testable requirement] | [How to verify] |
| [Performance requirement] | [Test approach] |
| [Edge case handling] | [Validation approach] |

---

## 6. Business Rationale
[Extract from IDEA-09 Lean Canvas]

**Why Now:** [Urgency or opportunity driving timeline]

**Why This Solution:** [Alternatives considered and why rejected]

**Strategic Fit:** [How this serves larger business goals]

**Revenue/Cost Impact:** [Expected business outcome]

---

## 7. Implementation Guidance

**Starting Point:** [Where to begin implementation]

**Risk Areas (Rabbit Holes):** [Pre-identified risks from TECH-02]
- [Risk 1]: [Mitigation approach]
- [Risk 2]: [Mitigation approach]

**Dependencies:** [What must exist before this can be built]

**Test Strategy:** [From TECH-02 - approach to verification]
```

---

## Memory Bank Population Rules

After creating the handoff document, populate Memory Bank files for AI development sessions.

### File: projectbrief.md

**Sources:** IDEA-04 (Problem Statement), IDEA-09 (Lean Canvas)

```markdown
# Project Brief

## Overview
[One paragraph describing what we're building]

## Problem
[The specific pain point from IDEA-04]

## Solution
[High-level approach from IDEA-09]

## Target Users
[Customer segment from IDEA-04]

## Success Metrics
[Key metrics from IDEA-09]
```

### File: productContext.md

**Sources:** IDEA-08 (Value Proposition Canvas), PROD-09 (PRD)

```markdown
# Product Context

## User Jobs
[What users are trying to accomplish - from Value Prop Canvas]

## User Pains
[Frustrations and obstacles - from Value Prop Canvas]

## User Gains
[Desired outcomes - from Value Prop Canvas]

## Key Features
[Core capabilities from PRD]

## User Stories
[Primary user stories from PRD]
```

### File: techContext.md

**Sources:** TECH-02 (TDD)

```markdown
# Technical Context

## Technology Stack
[Languages, frameworks, infrastructure from TECH-02]

## Architecture Overview
[High-level architecture pattern and rationale]

## Data Model
[Core entities and relationships]

## API Contracts
[Key interfaces and endpoints]

## Dependencies
[External services and libraries]
```

### File: systemPatterns.md

**Sources:** TECH-02 (TDD)

```markdown
# System Patterns

## Architectural Decisions
[Key decisions with rationale - ADR format]

## Code Patterns
[Conventions and patterns to follow]

## Security Patterns
[Authentication, authorization, data handling]

## Error Handling
[Standard approaches to errors]

## Scalability Considerations
[Performance and scaling patterns]
```

### File: activeContext.md (Dynamic)

**Sources:** PROD-09, current task

```markdown
# Active Context

## Current Focus
[What we're working on right now]

## Recent Changes
- [Date]: [Change description]

## Next Steps
1. [Immediate next action]
2. [Following action]

## Active Decisions
[Decisions currently under consideration]

## Blockers
[Current obstacles if any]
```

### File: progress.md (Dynamic)

**Sources:** feature_list.json, git log

```markdown
# Progress

## Completed
- [x] [Task description] - [Completion date]

## In Progress
- [ ] [Current task] - [Status notes]

## Pending
- [ ] [Upcoming task]

## Known Issues
- [Issue description]

## Recent Commits
- [Commit hash]: [Message]
```

---

## task-master Integration

After creating handoff and Memory Bank files:

```bash
# Initialize task-master if not already done
task-master init

# Copy handoff document to docs folder
cp handoff-[feature].md .taskmaster/docs/

# Parse into tasks
task-master parse-prd .taskmaster/docs/handoff-[feature].md

# Analyze complexity
task-master analyze-complexity --research

# Expand complex tasks
task-master expand --id=[complex-task-id]

# Get next priority task
task-master next
```

---

## Verification Checklist

Before proceeding from handoff to implementation:

```
□ Handoff document contains all seven essential categories
□ No sections marked "TBD" or empty
□ AI agent can understand WHY this feature exists without reading all source docs
□ Memory Bank contains enough context for implementation decisions
□ task-master can parse handoff into meaningful tasks
□ Success metrics are specific enough to validate after shipping
□ Recommended workflow (Small/Medium/Large) matches scope
```

### Quality Gate

If any of these are true, go back and fix:

- [ ] Customer segment is vague ("users" without specifics)
- [ ] Success metrics are unmeasurable ("improve experience")
- [ ] Non-goals section is empty
- [ ] No technical decisions documented
- [ ] Business rationale missing "why now" or "why this"
