# neotherapper/claude-plugins

> AI agent plugins by [@neotherapper](https://github.com/neotherapper) · [pilitsoglou.com](https://pilitsoglou.com)

Works with **Claude Code**, **Gemini CLI**, **GitHub Copilot**, **Cursor**, **Windsurf**, and **OpenCode**.

---

## Plugins

### [beacon](plugins/beacon/) — Map any site's API surface

> *Map any site's API surface — systematically.*

Run one command and Beacon:
1. Detects the tech stack and loads a framework-specific guide
2. Probes all known public endpoints, sitemaps, feeds, and GraphQL schemas
3. Analyses JS bundles and source maps for hidden API paths
4. Runs OSINT (certificate transparency, Wayback Machine, GitHub code search, Google dorks)
5. Compiles a browser visit plan — then executes it
6. Writes `docs/research/{site}/` with INDEX, tech-stack, site-map, API surfaces, and an OpenAPI spec

In future sessions, ask questions about the site and Beacon routes directly to the pre-built research files.

---

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
cp -r claude-plugins/plugins/beacon/agents/* .github/agents/
```

Then reference in `.github/copilot-instructions.md`:
```markdown
Skills are available in `.github/skills/`. Follow them when they match the task.
```

### Cursor

```bash
git clone https://github.com/neotherapper/claude-plugins.git
cp -r claude-plugins/plugins/beacon/skills/* .cursor/rules/
```

Or add to `.cursorrules` for always-on context.

### Windsurf

```bash
git clone https://github.com/neotherapper/claude-plugins.git
cat claude-plugins/plugins/beacon/skills/site-recon/SKILL.md >> .windsurfrules
```

### OpenCode / Codex

Copy the `AGENTS.md` from this repo to your project root, or add these references to your existing `AGENTS.md`:

```markdown
@plugins/beacon/skills/site-recon/SKILL.md
@plugins/beacon/skills/site-intel/SKILL.md
```

---

## Platform setup guides

Detailed setup instructions for each platform live inside each plugin:

- [Beacon — Gemini CLI setup](plugins/beacon/docs/platform/gemini-cli.md)
- [Beacon — Copilot setup](plugins/beacon/docs/platform/copilot.md)
- [Beacon — Cursor setup](plugins/beacon/docs/platform/cursor.md)
- [Beacon — OpenCode setup](plugins/beacon/docs/platform/opencode.md)

---

## Contributing

See [CONTRIBUTING.md](plugins/beacon/CONTRIBUTING.md) for how to add tech packs, improve skills, or extend the plugin.

Built by [@neotherapper](https://github.com/neotherapper) · Articles at [pilitsoglou.com](https://pilitsoglou.com)
