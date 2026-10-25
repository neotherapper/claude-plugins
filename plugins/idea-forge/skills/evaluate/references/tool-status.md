# Research Tool Status

Every research agent reads this before running CLIs. It records which `tools/cli` modules actually work from this machine, so agents spend their budget on evidence instead of rediscovering failures. Last verified 2026-09-08 across six agents. When you hit a new failure, or find that a listed one is fixed, say so in your report so this file can be updated.

## Setup in a fresh worktree

`tools/venv` and `tools/.env` are gitignored, so a new worktree has no research CLIs. Symlink both from the main checkout before dispatching agents:

```bash
ln -sfn <main-checkout>/tools/venv tools/venv && ln -sfn <main-checkout>/tools/.env tools/.env
```

## Broken: use the substitute

| Tool | Failure | Substitute |
|------|---------|------------|
| `cli.duckduckgo` | Rust panic on macOS (`system-configuration` NULL object) | `cli.serper`, or the WebSearch tool |
| `cli.reddit` | Reddit blocks the JSON API from this network (403 / connection closed); `search` only finds subreddits by name anyway | Google SERP results with `site:reddit.com` (real URLs, but no author, date, or score) |
| `cli.google_suggest amazon` / `youtube` | Empty body / `JSONDecodeError` on every query | `cli.google_suggest` (web), or skip and note the gap |
| `cli.crt_sh`, `cli.trustpilot` | JSON parse errors on most domains | Treat "N/A" as a tool failure, not as confirmed absence |

## Works, but differently from what older prompts assume

- **`cli.newsfeed hn`** returns `{source, query, count, articles}`, with no `nbHits`. For story counts, query `https://hn.algolia.com/api/v1/search?query=…` directly. HN Algolia is the most reliable fully attributed quote source in the toolset.
- **`cli.google_trends compare`** normalizes each keyword to its own 0–100 scale. It can't compare magnitudes across keywords; use absolute counts (HN stories, GitHub stars, suggestion breadth) instead.
- **`cli.wayback`** caps at 100 snapshots, so `last_seen` on a busy domain is a pagination artifact, not evidence the site is dead.
- **`cli.remoteok`** has only curated feeds (`europe | muse | remote` with `-q`). Zero hits reflects feed coverage, not zero hiring.

## Missing keys

These keys are empty or absent in `tools/.env`, so their tools fail. Empty strings raise a confusing `ValueError` rather than a clean "missing key" error.
- Empty: `BRAVE_API_KEY`, `HUNTER_API_KEY`.
- Absent: `DATAFORSEO_LOGIN`/`PASSWORD`, `MOZ_*`, `PRODUCTHUNT_TOKEN`, `THEIRSTACK_API_KEY`, `LISTEN_NOTES_API_KEY`, `G2_API_TOKEN`, `BUILTWITH_API_KEY`, `SIMILARWEB_API_KEY`.

DataForSEO is the toolset's only CPC / commercial-intent source. Without it there is no direct willingness-to-pay evidence, so flag that gap explicitly for the scoring agent (it affects C3).
