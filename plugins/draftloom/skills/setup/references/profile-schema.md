# Profile Schema

Full JSON schema for a voice profile. Load this file when constructing or validating a profile.

## Full schema

```json
{
  "id": "george-personal",
  "blog_name": "George's Build Log",
  "blog_url": "https://george.dev",
  "audience": "indie hackers and frontend developers",
  "audience_expertise": "intermediate",
  "tone": ["direct", "opinionated", "technical", "slightly irreverent"],
  "pillars": ["AI tooling", "frontend architecture", "building in public"],
  "channels": ["own blog", "X", "LinkedIn"],
  "typical_length": "medium",
  "inspiration": ["Paul Graham", "Dan Luu"],
  "cta_goal": "newsletter subscribe",
  "language": "en",
  "seo_default_keywords": [],
  "brand_voice_examples": [
    {
      "source": "local_file",
      "value": "posts/my-best-post/draft.md",
      "context": "My most-shared post — this is the tone to match"
    },
    {
      "source": "url",
      "value": "https://george.dev/writing/example",
      "context": "Opinionated take format I use often"
    },
    {
      "source": "inline",
      "value": "Here's the thing nobody talks about: ...",
      "context": "My opening sentence pattern"
    }
  ],
  "storage": "project",
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:00:00Z"
}
```

## Field reference

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | slug format, unique per storage location |
| `blog_name` | string | no | display name for UI |
| `blog_url` | string | no | used in distribution copy |
| `audience` | string | yes | free text, collected in Q2 |
| `audience_expertise` | string | no | beginner / intermediate / advanced |
| `tone` | string[] | yes | 3–5 adjectives, collected in Q3 |
| `pillars` | string[] | no | 2–4 topic areas |
| `channels` | string[] | no | distribution channels |
| `typical_length` | string | no | short / medium / long |
| `inspiration` | string[] | no | author or publication names |
| `cta_goal` | string | no | desired reader action |
| `language` | string | no | BCP-47 language code, default "en" |
| `seo_default_keywords` | string[] | no | pre-loaded into each brief |
| `brand_voice_examples` | object[] | no | local_file / url / inline |
| `storage` | string | yes | "project" or "global" |
| `created_at` | string | yes | ISO-8601 |
| `updated_at` | string | yes | ISO-8601 |

## Null fields

All deferred fields not collected during setup must be written as `null` (not omitted). This ensures the schema is always complete and agents can check field presence reliably.

## brand_voice_examples loading

When voice-eval loads brand_voice_examples:
- `local_file`: read the file at `value` path (relative to project root)
- `url`: fetch the URL content (text/plain or HTML, strip tags)
- `inline`: use `value` directly as text

If a source fails to load, log a warning and skip that example. Do not abort evaluation.
