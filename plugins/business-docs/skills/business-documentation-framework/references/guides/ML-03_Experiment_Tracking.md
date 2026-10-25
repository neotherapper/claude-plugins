# Generation Guide: ML-03 Experiment Tracking

**Purpose:** Record hyperparameters, data splits, and metrics for ML training runs to ensure reproducibility.

---

## Prerequisites
- ML-02 Datasheet

## Questions to Ask the User
- What were the primary hyperparameters (Learning Rate, etc.)?
- What was the data split (Train/Val/Test)?
- Which version of the model architecture was used?

## Document Template

```markdown
# ML Experiment: [Exp-ID]

**ID:** ML-03
**Status:** [Success / Failed / Ongoing]

---

## Configuration
- **Model:** [Architecture name]
- **Data:** [Link to ML-02 version]
- **Hyperparameters:**
  - `lr`: [Value]
  - `batch_size`: [Value]

## Results
| Metric | Value |
|---|---|
| Loss | |
| F1 Score | |

## Conclusion
- [Keep / Discard]
- **Learning:** [What changed?]
```
