# Security Policy

## Plugins run code

The plugins in this repository ship commands, agents, skills, and hooks that
**execute on your machine** when invoked by your AI coding agent (Claude Code,
Gemini CLI, GitHub Copilot, Cursor, Windsurf, OpenCode). Review a plugin's
contents before installing, and only install from sources you trust.

## Supported versions

This is an actively maintained personal plugin marketplace. Security fixes land
on the latest version of each plugin on the `main` branch. There is no
long-term-support branch for older releases.

## Reporting a vulnerability

If you find a security issue — for example a hook or script that could leak
data, run unintended commands, or exfiltrate credentials — please report it
**privately**, not in a public issue:

- **Preferred:** open a private
  [GitHub security advisory](https://github.com/neotherapper/claude-plugins/security/advisories/new)
- **Alternative:** reach out via [pilitsoglou.com](https://pilitsoglou.com)

Please include the plugin name, the affected file(s), and steps to reproduce.
You can expect an acknowledgement within a few days, and credit in the advisory
once a fix ships.
