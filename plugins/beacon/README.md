# Beacon

> Map any site's API surface — systematically.

A plugin that analyses websites and produces structured, persistent API surface documentation. Powered by a community-maintained knowledge base of framework-specific guides.

**Part of [neotherapper/claude-plugins](https://github.com/neotherapper/claude-plugins)** — works with Claude Code, Gemini CLI, GitHub Copilot, Cursor, and OpenCode.

## What it does

Run `/beacon:analyze https://example.com` and Beacon:

1. Maps the site's tech stack (WordPress, Next.js, Nuxt, Django, Rails, Shopify, and more)
2. Loads a framework-specific guide telling you *exactly* where to look
3. Probes all known public endpoints, source maps, sitemaps, feeds, and GraphQL schemas
4. Runs OSINT (Google dorks, certificate transparency, Wayback Machine, GitHub code search)
5. Generates a browse plan — then executes it via browser automation
6. Produces `docs/research/{site}/` with INDEX, tech-stack, site-map, API surfaces, and an OpenAPI spec

In future sessions, ask questions about the site using `/beacon:load` and Beacon routes directly to the right pre-built research file.

## Installation

### Claude Code
```
/plugin install beacon@neotherapper
```

### Gemini CLI
```bash
gemini skills install https://github.com/neotherapper/claude-plugins.git \
  --path plugins/beacon/skills
```

### GitHub Copilot
```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/* .github/skills/
```

### Cursor
```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/* .cursor/rules/
```

### OpenCode / Codex
Add to your `AGENTS.md`:
```markdown
@claude-plugins/plugins/beacon/skills/site-recon/SKILL.md
@claude-plugins/plugins/beacon/skills/site-intel/SKILL.md
```

See [`docs/platform/`](docs/platform/) for detailed per-platform setup guides.

## Quick start

```
/beacon:analyze https://example.com
```

## Tech packs

Beacon ships with tech packs for WordPress, Next.js, Nuxt, Django, Rails, Shopify, Astro, Laravel, Ghost, Express, React, Sylius, PrestaShop, OpenCart, Shopware, BigCommerce, Wix, Squarespace, Ecwid, Big Cartel, Square Online, Joomla, Webflow, Drupal, Magento, WooCommerce, and TYPO3. Each pack tells Beacon where to look for APIs, config values, auth patterns, and known public endpoints on sites using that framework.

Missing a framework? Beacon will web-search for it and offer to open a PR so the community benefits too.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add tech packs, improve skills, or extend the plugin.

Built by [@neotherapper](https://github.com/neotherapper) · [pilitsoglou.com](https://pilitsoglou.com)
