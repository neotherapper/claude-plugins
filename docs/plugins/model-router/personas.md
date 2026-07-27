# Model Router — User Personas

## Persona 1: The Multi-Provider Orchestrator (primary)

**Name:** Georgios · Full-stack developer; Claude Code (Max) daily, OpenCode with free
provider subscriptions on the side
**Platform:** OpenCode with 9 authenticated providers (NVIDIA NIM, Cerebras, OpenRouter,
Mistral, Groq, …)
**Typical ask:** "I'm about to do X in OpenCode — which of my models should I use?"

**Pain points:**
- 9 providers × dozens of models each — no idea which is better for a given task
- Free models rotate; `:free` variants have different context windows and rate limits
- No single place showing speed + quality + cost for the models *he actually has*

**How Model Router helps:** auto-discovers his providers from OpenCode's config, recommends
1–3 models with rationale ("GLM: 347 t/s, AA coding index 58, free on your NVIDIA key"),
flags when a recommendation rests on no benchmark data (`confidence: low`).

---

## Persona 2: The Speed-Critical Builder

**Name:** Priya · DevRel engineer building live demos
**Typical ask:** "Fastest model I have that can still follow instructions — TTFT under 2s."

**How Model Router helps:** AA TPS/TTFT are first-class fields in the merged record; the
rationale states the numbers and their source, so "fastest" is a fact, not a vibe.

---

## Persona 3: The Quality Maximizer

**Name:** Daniel · ML researcher comparing capabilities
**Typical ask:** "Compare kimi-k2.6 vs glm-5.2 vs minimax-m3."

**How Model Router helps:** comparison is the same data path with side-by-side output;
every number is source-attributed, and disagreements between facts and benchmarks are
surfaced rather than averaged away.

---

## Persona 4: The Budget-Conscious Starter

**Name:** Alex · Indie developer, $0 API budget
**Typical ask:** "Best completely free model I can use right now?"

**How Model Router helps:** `is_free` is derived from live pricing at query time (never a
stale stored flag), free-variant limits are shown explicitly, and brand-new free models
appear as soon as the registries know them.

---

*The former Persona 5 (pipeline designer) was retired with the pipeline scope cut
(ADR-006). Multi-step tasks get model-per-step suggestions in prose — v2 UX item.*
