# Model Router — Architecture

## Overview

```
User prompt
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  /model-router:recommend                             │
│  skill (orchestration layer)                         │
│  ┌────────────────────────────────────────────┐      │
│  │ 1. Parse task description                  │      │
│  │ 2. Match to stage template (or custom)     │      │
│  │ 3. Per stage:                              │      │
│  │    a. Apply hard filters (context, modality│      │
│  │    b. Score candidates across dimensions   │      │
│  │    c. Rank + pick top_n                    │      │
│  │    d. Generate rationale string            │      │
│  │ 4. Assemble pipeline                       │      │
│  │ 5. Estimate total cost                     │      │
│  │ 6. Return recommendation with confidence   │      │
│  └────────────────────────────────────────────┘      │
│            │ uses tools                              │
│            ▼                                         │
│  ┌────────────────────────────────────────────┐      │
│  │  MCP Server: model-router                  │      │
│  │                                            │      │
│  │  Tools:                                    │      │
│  │   • list_models(filters)                   │      │
│  │   • get_model(model_id)                    │      │
│  │   • recommend_models(task, constraints)    │      │
│  │   • design_pipeline(task)                  │      │
│  │   • compare_models(model_ids[])            │      │
│  │                                            │      │
│  │  ┌──────────────────────────────────┐      │      │
│  │  │  Adapters (pluggable)            │      │      │
│  │  │  ┌────────────┐ ┌─────────────┐  │      │      │
│  │  │  │ OpenRouter │ │ HuggingFace │  │      │      │
│  │  │  └────────────┘ └─────────────┘  │      │      │
│  │  │  ┌────────────┐ ┌─────────────┐  │      │      │
│  │  │  │ AA (scrape)│ │ Vellum      │  │      │      │
│  │  │  └────────────┘ └─────────────┘  │      │      │
│  │  │  ┌────────────┐ ┌─────────────┐  │      │      │
│  │  │  │ lmarena    │ │ BFCL (v2)   │  │      │      │
│  │  │  └────────────┘ └─────────────┘  │      │      │
│  │  └──────────────────────────────────┘      │      │
│  │            │ normalizes to                   │      │
│  │            ▼                                │      │
│  │  ┌──────────────────────────────────┐      │      │
│  │  │  Unified Model Record            │      │      │
│  │  │  (model.schema.json)             │      │      │
│  │  └──────────────────────────────────┘      │      │
│  │            │ cache                          │      │
│  │            ▼                                │      │
│  │  ┌──────────────────────────────────┐      │      │
│  │  │  SQLite cache (TTL 6h/24h)       │      │      │
│  │  │  models.db                       │      │      │
│  │  └──────────────────────────────────┘      │      │
│  └────────────────────────────────────────────┘      │
│                                                      │
│  ┌────────────────────────────────────────────┐      │
│  │  Scoring Engine                            │      │
│  │                                            │      │
│  │  1. Hard filter: min_context, modality,    │      │
│  │     tools, structured_output               │      │
│  │  2. Normalize each dimension to 0.0–1.0    │      │
│  │  3. Apply stage weights                    │      │
│  │  4. Weighted sum = score                   │      │
│  │  5. Constraint relaxation if 0 candidates  │      │
│  │  6. Confidence = source agreement          │      │
│  │                                            │      │
│  │  Formulas: scoring-formulas.md             │      │
│  └────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────┘
```

## Unified Model Record

```yaml
# Stored in SQLite cache, returned by all tools
model_id: string                      # "nvidia/nemotron-3-ultra-550b-a55b:free"
canonical_id: string                  # "nvidia/nemotron-3-ultra-550b-a55b" (no :free suffix)
display_name: string                  # "NVIDIA Nemotron 3 Ultra 550B"
provider: string                      # "nvidia"
release_date: string | null           # "2026-03-15"
expiration_date: string | null        # "2026-07-21"
deprecated: bool
successor_model_id: string | null

context_length: int                   # 1000000
max_completion_tokens: int            # 128000

modalities:
  input: [text,image,audio,file,video]
  output: [text,image]

pricing_usd_per_mtok:
  input: float
  output: float
  cache_read: float | null
  cache_write: float | null

free_tier:
  available: bool
  variant_id: string | null           # "nvidia/...:free"
  rate_limit_rpm: int | null
  rate_limit_rpd: int | null
  context_length: int | null          # may differ from paid

reasoning:
  supported: bool
  mandatory: bool | null
  default_enabled: bool | null
  effort_levels:
    min: float | null                 # 0.0–1.0 continuous
    max: float | null
    default: float | null
    discrete_levels: [string] | null  # ["low","medium","high","xhigh"]

supported_parameters:
  tools: { supported: bool }
  tool_choice: { supported: bool, modes: [string] }
  structured_outputs: { supported: bool, json_schema: bool }
  reasoning: { supported: bool, effort_control: string, budget_control: bool }
  temperature: { supported: bool, range: [float, float] }

is_moderated: bool | null             # from OpenRouter top_provider

# Derived task types (from modality + architecture)
task_types: [string]                  # ["text_generation","image_to_text","summarization",...]
                                      # derived from architecture.modality + input_modalities

# Provider-specific offerings (same model, different hosting)
offerings:
  - provider: string                  # "openrouter", "nvidia", "azure"
    pricing: { input: float, output: float }
    latency_p50_ms: int | null
    rate_limit_rpm: int | null
    context_length: int | null

# Benchmark-derived scores (all nullable, lazy-fetched)
benchmarks:
  fetched_at: string                  # ISO 8601

  # Artificial Analysis
  aa_intelligence_index: float | null
  aa_agentic_knowledge_work_elo: float | null
  aa_knowledge_reliability: float | null
  aa_long_context_reasoning: float | null
  aa_output_tps: float | null
  aa_ttft_seconds: float | null
  aa_e2e_response_time_500tok: float | null
  aa_cost_per_task_usd: float | null
  aa_active_params_b: float | null
  aa_total_params_b: float | null
  aa_openness_index: float | null
  aa_verbosity_tokens: float | null

  # Vellum
  vellum_hle: float | null
  vellum_swe_bench: float | null
  vellum_terminal_bench: float | null
  vellum_os_world: float | null
  vellum_browse_comp: float | null
  vellum_auto_bench: float | null
  vellum_gpqa_diamond: float | null

  # lmarena (category-level only — sub-categories unavailable)
  lmarena_agent_elo: float | null
  lmarena_text_elo: float | null
  lmarena_code_elo: float | null
  lmarena_vision_elo: float | null
  lmarena_search_elo: float | null
  lmarena_webdev_elo: float | null

  # HuggingFace (open-weight models only)
  hf_downloads: int | null
  hf_likes: int | null
  hf_license: string | null
```

## Stage Template Structure

```yaml
template_id: string
name: string
description: string
stages:
  - name: string
    description: string
    capability_vector: [string]        # scoring dimensions to activate
    hard_constraints:
      min_context: int | null
      requires_tools: bool | null
      requires_structured_output: bool | null
      requires_modality: [string] | null
    weights:                           # must sum to 1.0
      dimension: float
    constraint_relaxation:             # mandatory — never return empty silently
      - step: int
        relax: { constraint: value }
        warning: string
        require_user_confirmation: bool | null
    top_n: int                         # default: 3
    recommended_config:                # output alongside model
      reasoning_effort: string | null
      temperature: float | null
```

## Recommendation Output Schema

```yaml
task_description: string
template_used: string | null           # "research_pipeline" or "custom"
stages:
  - stage_name: string
    description: string
    models:
      - model_id: string
        display_name: string
        provider: string
        score: float                   # 0.0–1.0 weighted composite
        confidence: high | medium | low
        is_free: bool
        reasoning: string              # human-readable rationale
        recommended_config:
          reasoning_effort: string | null
          temperature: float | null
        cost_estimate_per_1k_tokens: float
        speed_tps: float | null
        context_length: int
        modalities: { input: [string], output: [string] }
total_pipeline_cost_estimate: float | null
total_pipeline_speed_estimate: string | null  # "fast" | "medium" | "slow"
warnings: [string]                     # constraint relaxations, stale data, sunset alerts
```

## Agent Flow

```
1. User: "I want to research knowledge systems — find the best model for discovery, then enrichment per item, then report synthesis"

2. Router Agent:
   a. Parses task → identifies 3 stages (Discovery, Enrichment, Report)
   b. Loads template: "research_pipeline" (or constructs custom)
   c. For each stage:
      i.   Fetch models from cache (or refresh if stale)
      ii.  Apply hard filters (min_context, modality)
      iii. Score remaining models across capability_vector dimensions
      iv.  Rank by weighted score
      v.   Pick top_n
      vi.  Generate rationale string
   d. Assemble pipeline
   e. Estimate total cost
   f. Return recommendation

3. Skill formats recommendation for user
```

## Task Type Taxonomy (from Cloudflare Workers AI)

Cloudflare's model catalog demonstrates the right separation: **task type** (what the model does) vs. **capability** (how it does it). A model tagged `Text Generation` can simultaneously have `Reasoning + Function calling + Vision`.

### Task types (what the model produces)

| Task Type | Description | Scoring dimensions that apply |
|-----------|-------------|-------------------------------|
| Text Generation | General-purpose LLM inference | intelligence, agentic_coding, agentic_knowledge_work, reasoning_depth, cost, speed |
| Image-to-Text | Vision understanding / OCR | vision, intelligence, cost |
| Text Embeddings | Vector representations for search/RAG | — (specialized, not scored on general axes) |
| Automatic Speech Recognition | Speech-to-text transcription | — (specialized) |
| Text-to-Speech | Audio synthesis | — (specialized) |
| Text-to-Image | Image generation from prompts | — (specialized) |
| Text Classification | Sentiment, labeling, categorization | instruction_following, cost, speed |
| Summarization | Condense long text | intelligence, context_window, cost |
| Translation | Cross-lingual transfer | — (specialized) |
| Object Detection | Visual object localization | — (specialized) |
| Image Classification | Visual categorization | — (specialized) |
| Voice Activity Detection | Audio turn detection | — (specialized) |

### Capabilities (how the model operates)

| Capability | What it means | Schema field |
|------------|---------------|-------------|
| Reasoning | Chain-of-thought / extended thinking | `reasoning.supported` |
| Function calling | Tool use, API invocation | `supported_parameters.tools` |
| Vision | Image/video input understanding | `modalities.input includes image` |
| Batch | Batch inference support | `supported_parameters.batch` |
| Real-time | Streaming / low-latency | derived from `aa_ttft_seconds` and `aa_output_tps` |
| LoRA | Adapter/fine-tuning support | `hf_lora_compatible` |
| Partner | Third-party hosted | `offerings[].provider` |
| Deprecated | Sunset / end-of-life | `deprecated` |

### How this maps to our schema

Our unified model record already captures most of these via different fields:
- **Task type** → derived from `modalities` + OpenRouter `architecture.modality` (e.g., `"text->text"` = Text Generation, `"image->text"` = Image-to-Text)
- **Capabilities** → `reasoning.supported`, `supported_parameters.tools`, `modalities.input`, `deprecated`
- **Status** → `deprecated`, `free_tier.available`, `expiration_date`

The missing piece: **task type as an explicit field**. Add to schema:

```yaml
task_types: [string]   # ["text_generation", "image_to_text"] — derived from modality
```

This enables a user to say "I need a model for summarization" and get models tagged with that task type, rather than manually inferring it from modality strings.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| OpenRouter as primary source | 343+ models, no API key, covers all free models, includes pricing + modalities + reasoning |
| `is_free` derived, not stored | Avoids sync risk; free variants need separate `free_tier` block anyway |
| Composite scoring with explicit formulas | Prevents magic — every score is reproducible and auditable |
| Constraint relaxation mandatory | Never silently return empty results; progressively relax with warnings |
| `fetched_at` on every source block | 24h cache means data can be stale; must flag in output |
| `offerings` array per model | Same model from different providers has different pricing/speed/limits |
| Effort-level recommendations | Same model at low vs. high effort has wildly different cost/quality |
| lmarena as category-level only | Sub-category breakdowns (text_coding, text_math) don't exist in their API |
| Vellum/AA as scrape-only | No public API; fragile but valuable; cached aggressively with staleness warnings |
