# Generation Guide: OPS-07 Deployment Documentation

**Purpose:** Document the environment configuration and pipeline mechanics for shipping code to production.

---

## Prerequisites
- OPS-02 CHANGELOG
- OPS-04 Runbooks

## Questions to Ask the User
- What is the CI/CD platform used (GitHub Actions, etc.)?
- What are the environment-specific secrets required?
- How is a rollback triggered?

## Document Template

```markdown
# Deployment Documentation

**ID:** OPS-07
**Environment:** [Production / Staging]

---

## Pipeline Overview
- **Platform:** [e.g., GitHub Actions]
- **Trigger:** [e.g., Merge to main]

## Configuration
### Required Secrets
- `DB_PASSWORD`
- `API_KEY`

## Deployment Procedure
1. [Automatic steps]
2. [Manual approvals]

## Rollback Procedure
```bash
# Command to revert
git revert ...
```
```
