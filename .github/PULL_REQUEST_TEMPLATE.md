<!--
Thanks for contributing to neotherapper/claude-plugins!
Fill in the sections below and tick the checklist. CI runs
scripts/validate-marketplace.sh on every PR.
-->

## What & why

<!-- Briefly describe the change and the motivation. Link any related issue. -->

## Type of change

- [ ] New plugin
- [ ] Plugin change (command / agent / skill / hook)
- [ ] Beacon tech pack
- [ ] Docs / repo hygiene
- [ ] Other:

## Checklist

- [ ] `bash scripts/validate-marketplace.sh` passes locally
- [ ] If I added, renamed, or removed a **published** plugin, it is reflected in `.claude-plugin/marketplace.json`
- [ ] I bumped `version` in `plugins/<name>/.claude-plugin/plugin.json` if behaviour changed
- [ ] Any new skill has a specific, trigger-friendly `description` in its `SKILL.md` frontmatter (and `name` matches its folder)
- [ ] Relevant `tests/validate-*.sh` pass (for Beacon changes)
- [ ] `claude plugin validate <plugin>` passes for plugins I touched (if you have the Claude CLI)
