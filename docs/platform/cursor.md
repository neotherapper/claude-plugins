# Beacon — Cursor Setup

## Option 1: `.cursor/rules/` (recommended — on-demand)

```bash
git clone https://github.com/neotherapper/claude-plugins.git
mkdir -p .cursor/rules
cp -r claude-plugins/plugins/beacon/skills/site-recon .cursor/rules/
cp -r claude-plugins/plugins/beacon/skills/site-intel .cursor/rules/
```

Cursor auto-discovers SKILL.md files in `.cursor/rules/` and activates them when relevant.

## Option 2: `.cursorrules` (always-on)

```bash
cat claude-plugins/plugins/beacon/skills/site-recon/SKILL.md >> .cursorrules
echo -e "\n---\n" >> .cursorrules
cat claude-plugins/plugins/beacon/skills/site-intel/SKILL.md >> .cursorrules
```

## Option 3: Notepads (explicit reference)

1. Open Cursor Notepads
2. Create a notepad called `beacon-site-recon`
3. Paste the contents of `skills/site-recon/SKILL.md`
4. Reference in chat: `Use @beacon-site-recon to analyse https://example.com`

## Usage tips

- `.cursor/rules/` is the cleanest approach — rules activate only when relevant
- Keep `.cursorrules` short (2-3 skills max) to avoid bloating context
- All output goes to `docs/research/{site-name}/` in your project
