# Draftloom

> AI-powered blog post drafting for Claude Code. Write in your voice, optimised for virality.

Draftloom guides you through writing a blog post end-to-end — voice profile, section wireframe, iterative AI drafting, multi-dimensional evaluation (SEO, hook, voice, readability), and platform-ready distribution copy.

## Commands

| Command | What it does |
|---------|-------------|
| `/draftloom:setup` | Create or edit a named voice profile |
| `/draftloom:draft` | Write a new post (brief → wireframe → draft → eval loop → distribution) |
| `/draftloom:eval` | Score any existing markdown file across 4 dimensions |

## Quick start

```
# 1. Create your writing profile (3 questions)
/draftloom:setup

# 2. Start a post
/draftloom:draft

# 3. Score an existing post
/draftloom:eval
```

## What you get

Each finished post lands in `posts/{slug}/`:

```
posts/my-post/
├── draft.md           — your post, ready to publish
├── distribution.json  — X hook · LinkedIn opener · email subject · newsletter blurb
└── scores.json        — final SEO / hook / voice / readability scores
```

## Multiple profiles

Create one profile per context — personal blog, corporate brand, client accounts:

```
/draftloom:setup                        → create george-personal
/draftloom:setup                        → create vanguard-corporate
/draftloom:draft                        → pick which profile to write as
```

## Requirements

- Claude Code with plugin support
- No external services required (file-based by default)
- Optional: Turso MCP for cross-project analytics — see plugin settings

## Contributing

Found a bug or want to add a feature? Open an issue or PR on [GitHub](https://github.com/neotherapper/claude-plugins).
Contributor docs live in `docs/plugins/draftloom/` in the repo.
