# Business Docs

> Write business and product documents in the right order, from problem statement to technical design.

One skill, `business-documentation-framework`, covering 85 document types across 6 phases. It asks a few questions to choose a path, then shows only the next documents whose dependencies are met. Each document has its own generation guide.

| Path | Docs | Use case |
|------|------|----------|
| Internal Tool | 6 | Tools for your own team |
| MVP | 11 | External product, market validation |
| Investor | 16+ | External product seeking funding |
| Full | 85 | Enterprise or regulated environments |

Documents go in the project's `docs/` folder. Helper scripts in `skills/business-documentation-framework/scripts/` scaffold a project, report progress, validate documents and gateways, and extract the seven handoff categories for implementation. See `references/scripts.md` inside the skill.

To decide whether an idea is worth building before documenting it, use `/idea-forge:evaluate`.
