# Document Registry v2.3

Complete registry of all 85 documents with path-aware dependencies.

---

## Table of Contents

- [Path-Specific Dependency Rules](#path-specific-dependency-rules)
- [Ideation Phase (20 documents)](#ideation-phase-20-documents)
- [Product Phase (29 documents)](#product-phase-29-documents)
- [Technical Phase (16 documents)](#technical-phase-16-documents)
- [Operations Phase (7 documents)](#operations-phase-7-documents)
- [Market Phase (3 documents)](#market-phase-3-documents)
- [Funding Phase (3 documents)](#funding-phase-3-documents)
- [ML/AI Phase (4 documents)](#mlai-phase-4-documents)
- [Security Phase (2 documents)](#security-phase-2-documents)
- [Path Definitions](#path-definitions)
- [Gateway Summary](#gateway-summary)
- [Parallel Track Opportunities](#parallel-track-opportunities)
- [Template Coverage](#template-coverage)

---

## Path-Specific Dependency Rules

**CRITICAL:** Dependencies vary by path. Use the correct dependency for the user's selected path.

| Document | Internal Tool Path | MVP Path          | Investor Path     | Full Path        |
| -------- | ------------------ | ----------------- | ----------------- | ---------------- |
| IDEA-04  | None (start here)  | IDEA-02           | IDEA-02           | IDEA-02          |
| IDEA-09  | IDEA-04            | IDEA-08           | IDEA-08           | IDEA-08          |
| PROD-09  | N/A (use PROD-29)  | IDEA-19 + PROD-18 | IDEA-19 + PROD-18 | PROD-02, PROD-03 |
| PROD-29  | IDEA-19            | N/A               | N/A               | N/A              |
| TECH-02  | PROD-29            | PROD-09           | PROD-09           | PROD-09          |

---

## Ideation Phase (21 documents)

| ID      | Name                           | Type      | Standard Deps    | Internal Path Deps | Gateway | Critical Path | Guide |
| ------- | ------------------------------ | --------- | ---------------- | ------------------ | ------- | ------------- | ----- |
| IDEA-01 | Customer Interviews (Mom Test) | Research  | —                | SKIP               | No      | **Yes**       | [Guide](guides/IDEA-01_Customer_Interviews.md) |
| IDEA-02 | JTBD Analysis                  | Research  | IDEA-01          | SKIP               | No      | **Yes**       | [Guide](guides/IDEA-02_JTBD_Analysis.md) |
| IDEA-03 | 5 Whys Analysis                | Research  | IDEA-01          | SKIP               | No      | No            | [Guide](guides/IDEA-03_5_Whys_Analysis.md) |
| IDEA-04 | Problem Statement              | Strategy  | IDEA-02          | None (start)       | **Yes** | **Yes**       | [Guide](guides/IDEA-04_Problem_Statement.md) |
| IDEA-05 | Mission Statement              | Strategy  | IDEA-04          | —                  | No      | No            | [Guide](guides/IDEA-05_Mission_Statement.md) |
| IDEA-06 | Vision Statement               | Strategy  | IDEA-05          | —                  | No      | No            | [Guide](guides/IDEA-06_Vision_Statement.md) |
| IDEA-07 | Company Values                 | Strategy  | IDEA-06          | —                  | No      | No            | [Guide](guides/IDEA-07_Company_Values.md) |
| IDEA-08 | Value Proposition Canvas       | Strategy  | IDEA-04          | SKIP               | No      | **Yes**       | [Guide](guides/IDEA-08_Value_Proposition_Canvas.md) |
| IDEA-09 | Lean Canvas                    | Strategy  | IDEA-08          | IDEA-04            | **Yes** | **Yes**       | [Guide](guides/IDEA-09_Lean_Canvas.md) |
| IDEA-10 | Business Model Canvas          | Strategy  | IDEA-09          | —                  | No      | No            | [Guide](guides/IDEA-10_Business_Model_Canvas.md) |
| IDEA-11 | TAM/SAM/SOM Analysis           | Market    | IDEA-09          | SKIP               | No      | No            | [Guide](guides/IDEA-11_TAM_SAM_SOM_Analysis.md) |
| IDEA-12 | Porter's Five Forces           | Market    | IDEA-11          | SKIP               | No      | No            | [Guide](guides/IDEA-12_Porters_Five_Forces.md) |
| IDEA-13 | PESTEL Analysis                | Market    | IDEA-11          | SKIP               | No      | No            | [Guide](guides/IDEA-13_PESTEL_Analysis.md) |
| IDEA-14 | Competitive Positioning        | Market    | IDEA-12          | SKIP               | No      | No            | [Guide](guides/IDEA-14_Competitive_Positioning.md) |
| IDEA-15 | Why Now? Analysis              | Market    | IDEA-14          | SKIP               | No      | No            | [Guide](guides/IDEA-15_Why_Now_Analysis.md) |
| IDEA-16 | Pitch Deck                     | Synthesis | IDEA-10, IDEA-15 | SKIP               | **Yes** | No            | [Guide](guides/IDEA-16_Pitch_Deck.md) |
| IDEA-17 | OKRs                           | Synthesis | IDEA-09          | —                  | No      | No            | [Guide](guides/IDEA-17_OKRs.md) |
| IDEA-18 | Opportunity Solutions Tree     | Discovery | IDEA-09          | Optional           | No      | **Yes**       | [Guide](guides/IDEA-18_Opportunity_Solutions_Tree.md) |
| IDEA-19 | Feasibility Assessment         | Decision  | IDEA-09          | IDEA-09            | **Yes** | **Yes**       | [Guide](guides/IDEA-19_Feasibility_Assessment.md) |
| IDEA-20 | AI Build vs Buy Decision       | Decision  | IDEA-19          | Optional           | No      | No            | [Guide](guides/IDEA-20_AI_Build_vs_Buy_Decision.md) |
| IDEA-21 | Cross-Domain Strategic Synthesis | Synthesis | IDEA-03 (multiple) | SKIP            | No      | No            | [Guide](guides/IDEA-21_Cross_Domain_Strategic_Synthesis.md) |

**Legend:** "SKIP" = Not used on Internal Tool Path. "—" = Optional, not on critical path.

---

## Product Phase (29 documents)

| ID      | Name                     | Type          | Standard Deps    | Internal Path Deps | Gateway | Critical Path | Guide |
| ------- | ------------------------ | ------------- | ---------------- | ------------------ | ------- | ------------- | ----- |
| PROD-01 | Product Vision           | Strategy      | IDEA-06          | —                  | **Yes** | No            | [Guide](guides/PROD-01_Product_Vision.md) |
| PROD-02 | Product Strategy         | Strategy      | PROD-01          | —                  | No      | No            | [Guide](guides/PROD-02_Product_Strategy.md) |
| PROD-03 | Personas                 | Research      | IDEA-02          | SKIP               | No      | No            | [Guide](guides/PROD-03_Personas.md) |
| PROD-04 | Journey Maps             | Research      | PROD-03          | SKIP               | No      | No            | [Guide](guides/PROD-04_Journey_Maps.md) |
| PROD-05 | Product Roadmap          | Planning      | PROD-02, PROD-09 | —                  | No      | No            | [Guide](guides/PROD-05_Product_Roadmap.md) |
| PROD-06 | RICE Prioritization      | Planning      | PROD-09          | —                  | No      | No            | [Guide](guides/PROD-06_RICE_Prioritization.md) |
| PROD-07 | MoSCoW Prioritization    | Planning      | PROD-09          | —                  | No      | No            | [Guide](guides/PROD-07_MoSCoW_Prioritization.md) |
| PROD-08 | Kano Analysis            | Planning      | PROD-03          | SKIP               | No      | No            | [Guide](guides/PROD-08_Kano_Analysis.md) |
| PROD-09 | PRD                      | Specification | IDEA-19, PROD-18 | N/A (use PROD-29)  | **Yes** | **Yes**       | [Guide](guides/PROD-09_PRD.md) |
| PROD-10 | BRD                      | Specification | IDEA-04          | —                  | No      | No            | [Guide](guides/PROD-10_BRD.md) |
| PROD-11 | MRD                      | Specification | IDEA-11          | SKIP               | No      | No            | [Guide](guides/PROD-11_MRD.md) |
| PROD-12 | Epic Definition          | Specification | PROD-09          | PROD-29            | No      | No            | [Guide](guides/PROD-12_Epic_Definition.md) |
| PROD-13 | User Stories             | Specification | PROD-12          | PROD-12            | No      | No            | [Guide](guides/PROD-13_User_Stories.md) |
| PROD-14 | Acceptance Criteria      | Specification | PROD-13          | PROD-13            | No      | No            | [Guide](guides/PROD-14_Acceptance_Criteria.md) |
| PROD-15 | Feature Specification    | Specification | PROD-09          | PROD-29            | No      | No            | [Guide](guides/PROD-15_Feature_Specification.md) |
| PROD-16 | Feature Flags Docs       | Specification | PROD-15          | PROD-15            | No      | No            | [Guide](guides/PROD-16_Feature_Flags.md) |
| PROD-17 | MVP Canvas               | Validation    | IDEA-09          | SKIP               | No      | **Yes**       | [Guide](guides/PROD-17_MVP_Canvas.md) |
| PROD-18 | Hypothesis Documentation | Validation    | PROD-17          | SKIP               | No      | **Yes**       | [Guide](guides/PROD-18_Hypothesis_Documentation.md) |
| PROD-19 | Experiment Results       | Validation    | PROD-18          | SKIP               | No      | No            | [Guide](guides/PROD-19_Experiment_Results.md) |
| PROD-20 | Competitive Analysis     | Research      | IDEA-14          | SKIP               | No      | No            | [Guide](guides/PROD-20_Competitive_Analysis.md) |
| PROD-21 | Release Plan             | Planning      | PROD-05          | —                  | No      | No            | [Guide](guides/PROD-21_Release_Plan.md) |
| PROD-22 | Release Notes            | Communication | PROD-21          | —                  | No      | No            | [Guide](guides/PROD-22_Release_Notes.md) |
| PROD-23 | User Feedback Analysis   | Research      | —                | —                  | No      | No            | [Guide](guides/PROD-23_User_Feedback_Analysis.md) |
| PROD-24 | Edge Case Documentation  | Specification | PROD-13          | —                  | No      | No            | [Guide](guides/PROD-24_Edge_Case_Documentation.md) |
| PROD-25 | Test Cases / QA Docs     | QA            | PROD-14          | —                  | No      | No            | [Guide](guides/PROD-25_Test_Cases.md) |
| PROD-26 | MVP Scope Definition     | Validation    | PROD-17          | SKIP               | No      | No            | [Guide](guides/PROD-26_MVP_Scope_Definition.md) |
| PROD-27 | Post-Release Review      | Review        | PROD-22          | —                  | No      | No            | [Guide](guides/PROD-27_Post_Release_Review.md) |
| PROD-28 | AI Moat Analysis         | Strategy      | PROD-20          | SKIP               | No      | No            | [Guide](guides/PROD-28_AI_Moat_Analysis.md) |
| PROD-29 | One-Pager PRD (Internal) | Specification | IDEA-19          | IDEA-19            | No      | No            | [Guide](guides/PROD-29_One_Pager_PRD.md) |

---

## Technical Phase (16 documents)

| ID      | Name                    | Type         | Standard Deps | Internal Path Deps | Gateway | Guide |
| ------- | ----------------------- | ------------ | ------------- | ------------------ | ------- | ----- |
| TECH-01 | RFC                     | Decision     | PROD-09       | PROD-29            | No      | [Guide](guides/TECH-01_RFC.md) |
| TECH-02 | TDD                     | Decision     | PROD-09       | PROD-29            | **Yes** | [Guide](guides/TECH-02_TDD.md) |
| TECH-03 | ADR                     | Decision     | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-03_ADR.md) |
| TECH-04 | C4 Context Diagram      | Architecture | PROD-01       | —                  | No      | [Guide](guides/TECH-04_C4_Context_Diagram.md) |
| TECH-05 | C4 Container Diagram    | Architecture | TECH-04       | —                  | **Yes** | [Guide](guides/TECH-05_C4_Container_Diagram.md) |
| TECH-06 | C4 Component Diagram    | Architecture | TECH-05       | —                  | No      | [Guide](guides/TECH-06_C4_Component_Diagram.md) |
| TECH-07 | C4 Code Diagram         | Architecture | TECH-06       | —                  | No      | [Guide](guides/TECH-07_C4_Code_Diagram.md) |
| TECH-08 | arc42 Documentation     | Architecture | TECH-05       | —                  | No      | [Guide](guides/TECH-08_arc42_Documentation.md) |
| TECH-09 | Sequence Diagrams       | Dynamic      | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-09_Sequence_Diagrams.md) |
| TECH-10 | Data Flow Diagrams      | Dynamic      | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-10_Data_Flow_Diagrams.md) |
| TECH-11 | State Diagrams          | Dynamic      | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-11_State_Diagrams.md) |
| TECH-12 | OpenAPI Specification   | API          | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-12_OpenAPI_Specification.md) |
| TECH-13 | AsyncAPI Specification  | API          | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-13_AsyncAPI_Specification.md) |
| TECH-14 | GraphQL Schema          | API          | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-14_GraphQL_Schema.md) |
| TECH-15 | Protocol Buffers        | API          | TECH-02       | TECH-02            | No      | [Guide](guides/TECH-15_Protocol_Buffers.md) |
| TECH-16 | API Versioning Strategy | API          | TECH-12       | TECH-12            | No      | [Guide](guides/TECH-16_API_Versioning_Strategy.md) |

---

## Operations Phase (7 documents)

| ID     | Name                     | Type       | Standard Deps | Gateway | Guide |
| ------ | ------------------------ | ---------- | ------------- | ------- | ----- |
| OPS-01 | README                   | Code Docs  | TECH-02       | No      | [Guide](guides/OPS-01_README.md) |
| OPS-02 | CHANGELOG                | Code Docs  | Implementation | No      | [Guide](guides/OPS-02_CHANGELOG.md) |
| OPS-03 | Contributing Guide       | Code Docs  | OPS-01        | No      | [Guide](guides/OPS-03_Contributing_Guide.md) |
| OPS-04 | Runbooks                 | Operations | TECH-05       | No      | [Guide](guides/OPS-04_Runbook.md) |
| OPS-05 | Incident Postmortems     | Operations | OPS-04        | No      | [Guide](guides/OPS-05_Incident_Postmortem.md) |
| OPS-06 | Tech Debt Register       | Operations | TECH-02       | No      | [Guide](guides/OPS-06_Tech_Debt_Register.md) |
| OPS-07 | Deployment Documentation | Operations | OPS-04        | No      | [Guide](guides/OPS-07_Deployment_Documentation.md) |

---

## Market Phase (3 documents)

| ID | Name | Type | Standard Deps | Gateway | Guide |
| --- | --- | --- | --- | --- | --- |
| MKT-01 | Go-to-Market Strategy | Strategy | PROD-02, IDEA-11 | No | [Guide](guides/MKT-01_Go_to_Market_Strategy.md) |
| MKT-02 | Sales Enablement | Sales | MKT-01 | No | [Guide](guides/MKT-02_Sales_Enablement.md) |
| MKT-03 | Marketing Materials | Marketing | IDEA-08 | No | [Guide](guides/MKT-03_Marketing_Materials.md) |

---

## Funding Phase (3 documents)

| ID | Name | Type | Standard Deps | Gateway | Guide |
| --- | --- | --- | --- | --- | --- |
| FUND-01 | Investor Materials | Communication | IDEA-16 | No | [Guide](guides/FUND-01_Investor_Materials.md) |
| FUND-02 | Financial Projections | Financial | IDEA-09 | No | [Guide](guides/FUND-02_Financial_Projections.md) |
| FUND-03 | Due Diligence Package | Compliance | FUND-01, FUND-02 | No | [Guide](guides/FUND-03_Due_Diligence_Package.md) |

---

## ML/AI Phase (4 documents)

| ID    | Name                   | Type          | Hard Deps | Gateway | Guide |
| ----- | ---------------------- | ------------- | --------- | ------- | ----- |
| ML-01 | Model Card             | Documentation | TECH-02   | **Yes** | [Guide](guides/ML-01_Model_Card.md) |
| ML-02 | Datasheet for Datasets | Documentation | —         | No      | [Guide](guides/ML-02_Datasheet_for_Datasets.md) |
| ML-03 | Experiment Tracking    | Operations    | ML-02     | No      | [Guide](guides/ML-03_Experiment_Tracking.md) |
| ML-04 | Model Versioning       | Operations    | ML-01     | No      | [Guide](guides/ML-04_Model_Versioning.md) |

---

## Security Phase (2 documents)

| ID     | Name                | Type     | Hard Deps | Gateway | Guide |
| ------ | ------------------- | -------- | --------- | ------- | ----- |
| SEC-01 | STRIDE Threat Model | Security | TECH-05   | **Yes** | [Guide](guides/SEC-01_STRIDE_Threat_Model.md) |
| SEC-02 | PASTA Threat Model  | Security | TECH-05   | No      | [Guide](guides/SEC-02_PASTA_Threat_Model.md) |

---

## Path Definitions

### Internal Tool Path (6 documents, 2-3 weeks)

```
IDEA-04⭐ → IDEA-09(lite) → IDEA-19⭐ → PROD-29 → TECH-02⭐ → OPS-01
```

**Documents:** IDEA-04, IDEA-09, IDEA-19, PROD-29, TECH-02, OPS-01

**What to skip:** IDEA-01, IDEA-02, IDEA-08, all market analysis, PROD-17, PROD-18, PROD-09

**Adaptations:**

- IDEA-04: Informal validation acceptable (no 10+ interviews required)
- IDEA-09: Focus on Problem, Solution, Key Metrics, Cost Structure only
- IDEA-19: Market Feasibility → "Internal Demand Assessment"

### MVP Path (11 documents, 8-14 weeks)

```
IDEA-01 → IDEA-02 → IDEA-04⭐ → IDEA-08 → IDEA-09⭐ → IDEA-19⭐ → PROD-17 → PROD-18 → PROD-09⭐ → TECH-02⭐
```

**Documents:** IDEA-01, IDEA-02, IDEA-04, IDEA-08, IDEA-09, IDEA-19, PROD-17, PROD-18, PROD-09, TECH-02

**Optional addition:** IDEA-18 (OST) after IDEA-09 if solution is uncertain

### Investor Path (16+ documents, 10-16 weeks)

MVP Path + IDEA-05, IDEA-06, IDEA-10, IDEA-11, IDEA-14, IDEA-15, IDEA-16, IDEA-20

**Parallel tracks after IDEA-04:**

- Track 1: IDEA-05 → IDEA-06 → IDEA-10 (Mission/Vision/BMC)
- Track 2: IDEA-11 → IDEA-12 → IDEA-14 → IDEA-15 (Market Analysis)

### Full Path (85 documents, 16-26 weeks)

All documents across all phases in dependency order.

---

## Gateway Summary

| Gateway | Phase     | Required Approvers  | Key Approval Criteria                        |
| ------- | --------- | ------------------- | -------------------------------------------- |
| IDEA-04 | Ideation  | Sponsor, PM         | Problem validated with evidence              |
| IDEA-09 | Ideation  | Founding Team       | Business model coherent, all blocks complete |
| IDEA-16 | Ideation  | Investors           | Pitch complete, data supports claims         |
| IDEA-19 | Ideation  | Sponsor, Tech Lead  | All 5 feasibility dimensions GREEN/YELLOW    |
| PROD-01 | Product   | CPO, CEO            | Aligned with company vision                  |
| PROD-09 | Product   | PM, Eng Lead        | Requirements clear, feasible, testable       |
| TECH-02 | Technical | Tech Lead, Security | Design sound, scalable, secure               |
| TECH-05 | Technical | Architect           | Container architecture defined               |
| ML-01   | ML/AI     | ML Lead             | Model performance documented                 |
| SEC-01  | Security  | Security Lead       | Threats identified and mitigated             |

---

## Parallel Track Opportunities

### After IDEA-04 approved (Investor Path):

- **Track 1:** IDEA-05 → IDEA-06 → IDEA-07 (Foundation)
- **Track 2:** IDEA-11 → IDEA-12 → IDEA-13 → IDEA-14 → IDEA-15 (Market)
- **Track 3:** IDEA-08 → IDEA-09 (Critical path continues)

### After IDEA-09 approved:

- **Track A:** IDEA-18 (OST) - if discovery needed
- **Track B:** IDEA-19 (Feasibility) - always required
- **Track C:** IDEA-17 (OKRs) - if setting organizational goals

### After IDEA-19 approved:

- **Track A:** IDEA-20 (Build vs Buy) - if decision needs detail
- **Track B:** PROD-17 → PROD-18 (MVP validation) - MVP path only
- **Track C:** PROD-09 (PRD) or PROD-29 (One-Pager)

### After TECH-02 approved:

- **Track A:** TECH-03, TECH-09, TECH-10, TECH-11 (Design artifacts)
- **Track B:** TECH-12, TECH-13, TECH-14 (API specs)
- **Track C:** OPS-01 → OPS-02, OPS-03 (Code docs)

---

## Template Coverage

| Path          | Template Coverage |
| ------------- | ----------------- |
| Internal Tool | 6/6 (100%) ✅     |
| MVP Path      | 11/11 (100%) ✅   |
| Investor Path | 16/16 (100%) ✅   |
| Full Path     | 85/85 (100%) ✅   |

**Note:** All 85 document types now have generation guides available in the `guides/` directory.

### New in v2.3

- **IDEA-21 Cross-Domain Strategic Synthesis** - Optional document for multi-domain/platform initiatives. Synthesizes meta-root-cause patterns across multiple IDEA-03 analyses to inform strategic direction before IDEA-04.
