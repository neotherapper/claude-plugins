# Generation Guide: ML-01 Model Card (GATEWAY)

**Purpose:** Provide transparency and standardization for machine learning models, covering performance, intended use, and ethical considerations.

---

## Prerequisites
- TECH-02 TDD
- ML-03 Experiment Tracking

## Questions to Ask the User
- What is the primary intended use of the model?
- What are the out-of-scope use cases?
- What are the known limitations or potential biases?

## Document Template

```markdown
# Model Card: [Model Name]

**ID:** ML-01
**Version:** 1.0
**Developer:** [Name]
**Date:** [Date]

---

## 1. Model Details
- **Type:** [e.g., Transformer, XGBoost]
- **Version:** [X.X]
- **License:** [License]

## 2. Intended Use
- **Primary Use:** [Description]
- **Target Users:** [Who uses the output]
- **Out-of-Scope:** ❌ [What NOT to use it for]

## 3. Factors & Data
- **Training Data:** [Link to ML-02]
- **Size:** [N samples]

## 4. Metrics & Performance
| Metric | Dataset | Value |
|---|---|---|
| Accuracy | Test | |

## 5. Ethical Considerations
- **Bias:** [Known risks]
- **Privacy:** [PII handling]

## Gateway Approval
**Required Approver:** ML Lead
```
