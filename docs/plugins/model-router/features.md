# Model Router — Features

## v1.0 — Ships now

### Model registry integration
- [ ] OpenRouter adapter: fetch all 343+ models via `/api/v1/models` (no API key)
- [ ] Task type taxonomy: 12 task types (Text Generation, Image-to-Text, ASR, TTS, Text-to-Image, Embeddings, Classification, Summarization, Translation, Object Detection, Image Classification, VAD) — derived from `architecture.modality` + `input_modalities`
- [ ] Capability tagging: Reasoning, Function calling, Vision, Batch, Real-time, LoRA, Partner, Deprecated — per Cloudflare Workers AI taxonomy
- [ ] Free-tier detection: derive from pricing, not stored boolean
- [ ] Free-variant specifics: `:free` suffix models get variant_id, context_window, rate limits
- [ ] Model expiration tracking: `expiration_date` from OpenRouter, surfaced in recommendations
- [ ] Multi-provider deduplication: same model from different providers → single record with offerings array
- [ ] 6-hour cache TTL for OpenRouter data, 24h for scraped sources

### Scoring system
- [ ] 14 scoring dimensions (see architecture.md): intelligence, agentic_coding, agentic_knowledge_work, computer_use, agentic_search, work_automations, speed, latency, cost, context_window, modality, reasoning_depth, verbosity, openness
- [ ] Composite dimension formulas: `agentic_coding` = f(SWE-Bench, Terminal-Bench, lmarena-code) with explicit weights
- [ ] Hard filters: min_context, requires_tools, requires_structured_output, requires_modality
- [ ] Weight validation: sum(weights) == 1.0 enforced per stage
- [ ] Confidence scoring: high/medium/low based on source agreement

### Stage templates
- [ ] Curated templates: Research Discovery → Enrichment → Report, Plan → Execute → Verify, Code → Test → Review, Extract → Classify → Summarize
- [ ] Per-stage capability vectors with weighted scoring dimensions
- [ ] Constraint relaxation chains: when no model matches, progressively relax with warnings
- [ ] Per-stage `top_n` configuration (default: 3)
- [ ] Custom template support: user defines stages inline via `/model-router:recommend`

### Recommendation output
- [ ] Per-stage ranked model list with rationale strings
- [ ] Recommended configuration per model: reasoning effort, temperature
- [ ] Total pipeline cost estimate
- [ ] Free/paid toggle: `--free` flag filters to free models only
- [ ] Comparison mode: `/model-router:compare model1 model2 model3` side-by-side

### Commands
- [ ] `/model-router:recommend {task description}` — main routing entry point
- [ ] `/model-router:compare {model1} {model2} [{model3}]` — side-by-side comparison
- [ ] `/model-router:cache status|clear|refresh` — cache management

### Hook
- [ ] SessionStart: detect platform (OpenCode/Claude Code/etc.), hint available commands

---

## v2.0 — Next cycle

### Additional data sources
- [ ] Artificial Analysis adapter: scrape Intelligence Index, speed, TTFT, cost per task per model page
- [ ] Vellum adapter: scrape leaderboard for HLE, SWE-Bench, OSWorld, BrowseComp, Terminal-Bench, AutoBench
- [ ] lmarena adapter: scrape Agent Elo, Text/WebDev/Vision/Search Elo rankings
- [ ] HuggingFace adapter: open-weight metadata, license, downloads, model cards
- [ ] BFCL adapter: Berkeley Function Calling Leaderboard — tool-use accuracy scores

### Enhanced scoring
- [ ] Instruction-following accuracy dimension (from BFCL or custom eval)
- [ ] Function-calling quality dimension (BFCL scores)
- [ ] Safety/trustworthiness dimension (OpenRouter `is_moderated` flag)
- [ ] Multilingual support dimension (language coverage metadata)
- [ ] Fine-tuning availability dimension (HuggingFace adapter flags)
- [ ] Structured output quality dimension (JSON compliance rate)

### Pipeline intelligence
- [ ] Stage dependency modeling: downstream stages adjust if upstream fails or returns few results
- [ ] Effort-level optimization: recommend model + effort configuration (low/medium/high/xhigh)
- [ ] Cost-performance Pareto front: show the Pareto-optimal models for each stage
- [ ] Pipeline replay: save and re-run a pipeline template with different inputs

### Provider integration
- [ ] NVIDIA NIM adapter: build.nvidia.com catalog endpoint (if public)
- [ ] Together AI adapter: `/v1/models` endpoint
- [ ] Provider-direct rate limit data: from OpenRouter `per_request_limits`

### UX
- [ ] Interactive pipeline editor: adjust stages, weights, constraints in conversation
- [ ] Model sunset alerts: warn when a recommended model expires within 30 days
- [ ] Historical tracking: log which models were recommended and why (audit trail)

---

## Task type → scoring dimension mapping

When a user says "I need a model for summarization," the plugin:
1. Maps task type → relevant scoring dimensions
2. Hard-filters to models with that task type
3. Scores filtered models on the mapped dimensions

| Task type | Relevant scoring dimensions |
|-----------|---------------------------|
| Text Generation | intelligence, agentic_coding, agentic_knowledge_work, reasoning_depth, cost, speed, instruction_following |
| Image-to-Text | vision, intelligence, cost, speed |
| Summarization | intelligence, context_window, cost, instruction_following |
| Text Classification | instruction_following, cost, speed |
| Translation | intelligence, instruction_following, cost |
| Text Embeddings | (specialized — not scored on general axes) |
| ASR / TTS / Text-to-Image / Object Detection / Image Classification / VAD | (specialized — not scored on general axes) |

## Scoring dimension rubrics (v1)

| Dimension | Primary source | Fallback source | Composite formula |
|-----------|---------------|----------------|-------------------|
| Intelligence | AA Intelligence Index | Vellum HLE | `0.6 * aa.intelligence_index/100 + 0.4 * vellum.hle_score/100` |
| Agentic coding | Vellum SWE-Bench | lmarena code Elo (normalized) | `0.5 * vellum.swe_bench/100 + 0.3 * vellum.terminal_bench/100 + 0.2 * lmarena_norm_code` |
| Agentic knowledge work | AA-Briefcase Elo | lmarena text Elo (normalized) | `0.6 * aa.agentic_knowledge_work_elo/1500 + 0.4 * lmarena_norm_text` |
| Computer use | Vellum OSWorld | — | `vellum.os_world/100` (or 0 if unavailable) |
| Agentic search | Vellum BrowseComp | lmarena search Elo (normalized) | `0.6 * vellum.browse_comp/100 + 0.4 * lmarena_norm_search` |
| Work automations | Vellum AutoBench | AA τ³-Banking (if available) | `vellum.auto_bench/100` |
| Speed | AA output_tps | Vellum speed | `min(aa.output_tps / 400, 1.0)` (normalized to 400 t/s ceiling) |
| Latency | AA TTFT | Vellum latency | `max(0, 1.0 - aa.ttft_seconds / 30)` (inverted: lower is better, 30s floor) |
| Cost | OpenRouter pricing | — | `max(0, 1.0 - blended_price / 50)` (inverted: lower is better, $50/M ceiling) |
| Context window | OpenRouter | — | `log2(context_length / 8000) / log2(1000000 / 8000)` (log-scaled) |
| Modality | OpenRouter | — | Hard gate: 1.0 if required modality present, 0.0 otherwise |
| Reasoning depth | OpenRouter reasoning block | — | `1.0 if reasoning.supported else 0.3` (boosted if effort levels available) |
| Instruction following | lmarena text_instruction_following | — | `lmarena_norm_if` (normalized from lmarena sub-ranking) |
| Verbosity | AA verbosity | — | `max(0, 1.0 - aa.verbosity_tokens / 200M)` (inverted: less verbose is better for cost) |
| Openness | AA Openness Index | — | `aa.openness_index / 100` |
