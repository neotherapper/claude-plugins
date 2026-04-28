# Idea Forge — Features

## v1.0 — Ships now

### Generate skill
- [x] `/idea-forge:generate` — discovers opportunity gaps from domain research
- [x] 5 gap patterns applied to vault domain content to surface candidates
- [x] Light scoring of up to 14 candidates across 3 criteria (market, evidence, differentiation)
- [x] Evidence floor: candidates with Evidence=0 dropped regardless of other scores
- [x] Top 3–5 candidates fleshed out into evaluator-ready idea seeds
- [x] Seeds file written to `ideas/_registry/idea-seeds-{domain}-{YYYY-MM-DD}-run-N.md`
- [x] Graceful degradation when `master-index.yaml` is missing

### Evaluate skill
- [x] `/idea-forge:evaluate` — scores one idea seed through a multi-stage pipeline
- [x] Accepts seeds file input or inline idea description (no seeds file required)
- [x] Adaptive intake interview: 5 targeted questions in up to 3 passes
- [x] 5 parallel research agents: market, competition, data, distribution, customer-voice
- [x] Competitor deep-dive (Stage 1.5): Tranco rank, domain age, funding history
- [x] 13-criteria weighted scoring against inferred business model lens
- [x] 6 business model lenses: directory, ecommerce, saas, marketplace, content, tool-site
- [x] Critic pass: stress-tests scores, flags over-confidence, adjusts before finalising
- [x] Final scored idea card produced with BET / BUILD / PIVOT / KILL verdict
- [x] Verdict mapping: BET ≥7.5 avg, BUILD 6–7.4, PIVOT 4–5.9, KILL <4

### File contract
- [x] All agent outputs written to `ideas/{slug}/research/` — never to conversation history
- [x] Atomic per-agent JSON files — no shared mutable state between agents
- [x] Final `idea-card.md` produced by orchestrator after critic pass

---

## v2.0 — Next cycle

### Vault integration
- [ ] Cross-domain pattern detection: surface ideas that span multiple vault domains
- [ ] `master-index.yaml` trend view — scoring history across runs, drift detection
- [ ] Auto-hint `/idea-forge:generate` when vault domain data is stale (hook)

### Scoring history
- [ ] Idea ranking across multiple evaluate runs for the same domain
- [ ] Score delta view: compare two evaluate runs on the same idea
- [ ] Export scored card history to a structured summary report

### Founder-fit dimension
- [ ] Additional scoring dimension: founder-fit (skills match, network access, time horizon)
- [ ] Configurable weight alongside the existing 13 criteria
- [ ] Founder profile stored in `ideas/_registry/founder-profile.yaml`
