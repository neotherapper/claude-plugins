# Generation Guide: ML-04 Model Versioning

**Purpose:** Track the lifecycle of models from training to deployment, including rollback paths and historical performance.

---

## Prerequisites
- ML-03 Experiment Tracking

## Questions to Ask the User
- What is the transition status (Staging, Production)?
- Is there a major architecture change (Major version bump)?
- What is the rollback model ID?

## Document Template

```markdown
# Model Versioning: [Model Name]

**ID:** ML-04
**Current Version:** [X.X.X]

---

## Version Registry
| Version | Exp-ID | Status | Date |
|---|---|---|---|
| 1.0.0 | | Production | |

## Deployment History
- **[Date]:** Promoted [Version] to production
- **Rationale:** [Metric improvement]

## Rollback Plan
- **Primary:** [Version]
- **Secondary:** [Version]
```
