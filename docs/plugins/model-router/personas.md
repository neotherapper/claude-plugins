# Model Router — User Personas

## Persona 1: The Multi-Model Orchestrator

**Name:** Georgios · Full-stack developer using OpenCode with multiple providers
**Uses models for:** Research pipelines, code generation, data enrichment, report synthesis
**Platform:** OpenCode (NVIDIA NIM free tier: minimax-m3, GLM 5.2, Kimi K2.6, Step 3.7 Flash)
**Typical workflow:** Describe a complex task → get a staged pipeline with best model per stage

**Goals:**
- Pick the best free or cheap model for each step of a multi-stage workflow
- Understand *why* a model was recommended (not just the name)
- Avoid paying for GPT-5.5 when a free model does the job

**Pain points:**
- 343+ models across providers — impossible to compare manually
- Free models have different context windows, rate limits, and quality than paid variants
- No single place to see speed + intelligence + cost for the same model

**How Model Router helps:**
- `/model-router:recommend` breaks "research X, enrich each item, write report" into 3 scored stages
- Returns ranked list per stage with reasoning ("GLM 5.2: 347 t/s, free, strong intelligence — best for speed-critical discovery")
- Filters to free-only when budget is $0, or shows cost tradeoffs when budget exists

**Profile example:** OpenCode power user · budget: free-first, paid if justified · priorities: speed > cost > intelligence

---

## Persona 2: The Speed-Critical Builder

**Name:** Priya · DevRel engineer building real-time demo apps
**Uses models for:** Live demos, quick prototyping, interactive coding assistants
**Platform:** Claude Code, Cursor
**Typical workflow:** "I need the fastest model that can do X — TTFT under 2s, 200+ t/s output"

**Goals:**
- Minimize latency for interactive demos (TTFT matters more than intelligence)
- Find models with fast first-token response for streaming UX
- Balance speed against quality — "fast enough" beats "perfect but slow"

**Pain points:**
- Intelligence benchmarks don't measure speed — you have to cross-reference multiple sources
- The "fastest" model changes weekly as providers add capacity
- Some fast models have terrible instruction following

**How Model Router helps:**
- `/model-router:compare minimax-m3 kimi-k2.6 glm-5.2` shows side-by-side speed, cost, intelligence
- Stage templates weight speed at 0.4+ for "discovery" stages where throughput matters
- Outputs TTFT + TPS + cost per 500 tokens for each recommendation

**Profile example:** DevRel engineer · budget: free or low-cost · priorities: speed (TTFT, TPS) > instruction following > cost

---

## Persona 3: The Quality-Maximizer

**Name:** Daniel · ML researcher evaluating model capabilities
**Uses models for:** Benchmarking, capability assessment, model comparison reports
**Platform:** Claude Code, custom scripts
**Typical workflow:** "Which model scores highest on SWE-Bench + HLE + GPQA Diamond? Show me the tradeoffs."

**Goals:**
- See intelligence benchmarks across multiple axes (reasoning, coding, knowledge, agentic)
- Compare models head-to-head with confidence intervals where available
- Understand where a model is strong vs. weak (not just an average score)

**Pain points:**
- No single source has all benchmarks — AA has Intelligence Index, Vellum has SWE-Bench, lmarena has Elo
- Benchmark scores disagree — a model might rank #1 on AA but #10 on lmarena
- Need to explain *why* scores differ (different eval sets, different methodologies)

**How Model Router helps:**
- `/model-router:compare` returns composite scores per dimension with source attribution
- Shows "Agentic coding: 85.2% (Vellum SWE-Bench) + 80.4% (Vellum Terminal-Bench)"
- Highlights where sources disagree and why (methodology differences)

**Profile example:** ML researcher · budget: any · priorities: intelligence > agentic coding > openness

---

## Persona 4: The Budget-Conscious Starter

**Name:** Alex · Indie developer, early-stage startup, no API budget
**Uses models for:** Code completion, documentation writing, research
**Platform:** OpenCode (free models only), GitHub Copilot free tier
**Typical workflow:** "What's the best completely free model I can use right now?"

**Goals:**
- Find the best free model for each task type
- Know when free models are "good enough" vs. when to pay
- Track which free models are being sunset (expiration dates)

**Pain points:**
- Free models come and go — NVIDIA NIM free tier changes monthly
- `:free` variants on OpenRouter have lower context windows and rate limits
- Hard to know if a free model is actually good or just listed as free

**How Model Router helps:**
- `/model-router:recommend --free` filters to free models only
- Shows free-tier specifics: context window (may differ from paid), rate limits, expiration date
- "This model expires in 13 days — consider `nvidia/nemotron-3-super-120b-a12b:free` as alternative"

**Profile example:** Indie developer · budget: $0 · priorities: cost (free) > intelligence > speed

---

## Persona 5: The Pipeline Designer

**Name:** Mei · Platform engineer building automated research pipelines
**Uses models for:** Multi-step automated workflows with tool use, structured output
**Platform:** Claude Code, custom agent frameworks
**Typical workflow:** "Design a 4-stage pipeline: extract → classify → enrich → summarize. Each stage needs tool_use + structured output."

**Goals:**
- Design multi-model pipelines where each stage is optimized for its specific task
- Ensure all selected models support required features (tools, JSON output, large context)
- Minimize total pipeline cost while meeting quality thresholds

**Pain points:**
- A model that supports `tools` doesn't mean it does tool-use well (quality varies 60%–99%)
- Structured output compliance varies wildly across models
- Pipeline cost is the sum of all stages — a cheap discovery stage + expensive synthesis can be optimal

**How Model Router helps:**
- `/model-router:recommend` with a pipeline description returns per-stage model + config
- Hard filters: `min_context`, `requires_tools`, `requires_structured_output`
- Total pipeline cost estimate shown alongside per-stage recommendations
- "Stage 3 (Synthesis) uses GLM 5.2 at effort=high: $0.95/M input, 347 t/s — best quality/cost ratio for your pipeline"

**Profile example:** Platform engineer · budget: cost-optimized · priorities: tool_use_reliability > intelligence > cost
