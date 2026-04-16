# Knowledge Vault Integration

`paidagogos:micro` uses the nikai Knowledge Vault (`knowledge/`) for resource links. This is a **file-read-only** integration in V1 — no API, no prompt stuffing.

## Vault location

The Knowledge Vault lives at `/knowledge/` in the nikai repo. It is a separate repository from claude-plugins. When the `paidagogos` plugin is in use, Claude Code has access to both repos in the same session.

## Lookup contract

When building the `resources[]` array for a lesson, follow these steps in order:

### Step 1: Identify the category

Map the lesson topic to a vault category:

| Topic type | Vault category |
|---|---|
| AI frameworks, agent tools, MCP servers | `knowledge/ai-tools/` |
| Development methodologies, processes | `knowledge/methodologies/` |
| Prompt engineering techniques | `knowledge/prompt-techniques/` |
| EdTech platforms | `knowledge/edtech/` |
| Sales tools | `knowledge/sales-tools/` |
| Not in any category | Skip vault lookup, go to Step 4 |

### Step 2: Search the category index

Read `knowledge/{category}/_index.md` and search for the lesson topic (case-insensitive substring match against slug and name fields).

If the file cannot be read (vault not in session, missing file), treat as a vault miss and go to Step 4.

If multiple entries match, prefer the entry whose slug is an exact match for the topic. If no exact match, use the first substring match.

### Step 3: Check entry status

If a match is found, read the entry file:
- `status: detailed` → Use its `url` frontmatter field and the first paragraph of `## One-Paragraph Summary` as resource metadata. Set `source: "vault"`. If the `url` field is absent or empty, treat this entry as a miss and go to Step 4.
- `status: stub` → Skip. Stubs contain only frontmatter — no content worth linking.

### Step 4: Fallback

If no vault match exists (or topic is outside vault categories), generate 2–3 resource links using your knowledge. Mark all as `"source": "ai-suggested"`. Always include at least one official documentation link.

## Source field rules

| source value | When to use | UI display |
|---|---|---|
| `"vault"` | Entry found in vault with `status: detailed` | No badge |
| `"ai-suggested"` | LLM-generated fallback, or stub entry skipped | `(AI-suggested, verify link)` badge |

## Resource type mapping

When building the `type` field for a resource:

| Resource kind | type value |
|---|---|
| Official documentation, API reference, spec | `"docs"` |
| Step-by-step tutorial or guide | `"tutorial"` |
| YouTube video, course video | `"video"` |
| Playground, browser-based tool, game | `"interactive"` |
| GitHub repo, library page | `"docs"` (treat as reference) |

## What NOT to do

- Do NOT read the full vault entry into the lesson prompt — only extract `url` and the one-paragraph summary
- Do NOT use stub entries — they contain only frontmatter, no content worth linking
- Do NOT mark vault resources as `"ai-suggested"` — they come from curated research
- Do NOT fail lesson generation if the vault lookup fails — fall back to Step 4 silently

## Example lookup

Lesson topic: "LangChain"

1. Maps to `knowledge/ai-tools/`
2. Read `knowledge/ai-tools/_index.md` → find slug `langchain`
3. Read `knowledge/ai-tools/langchain.md` → `status: detailed`
4. Extract: url + one-paragraph summary
5. Add to resources: `{ "title": "LangChain", "url": "...", "type": "docs", "source": "vault" }`
