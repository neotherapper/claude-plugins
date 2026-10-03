#!/usr/bin/env python3
"""check-skill-portability.py — fail when a skill depends on anything outside its own folder.

Why: `npx skills add <repo>` (Pi, OpenCode, Cline, Kiro, Codex, ... 70+ harnesses) copies ONE skill
folder into the user's project. Nothing outside that folder travels, so a skill that reads a plugin
root resource, a repo-relative path, or climbs out of its folder works in a clone and in Claude Code
but breaks silently everywhere else. Four rules, applied per skill folder (a dir holding SKILL.md):

  R1  ${CLAUDE_PLUGIN_ROOT} or $CLAUDE_PLUGIN_ROOT anywhere (only Claude Code defines it).
  R2  repo-relative `plugins/<name>/` paths (they only exist in a clone). URLs such as
      raw.githubusercontent.com/.../plugins/<name>/... are fine. Files named test_* are skipped.
  R3  in .md files, a backticked path under references|scripts|templates|technologies|categories|
      agents|assets (optionally `../<sibling-skill>/`) must exist relative to the SKILL FOLDER.
      Tokens with { } * < > $ are placeholders or output paths and are skipped.
  R4  in .sh/.py/.mjs/.js, `../../../` or `parents[N]` with N >= 3 (a script reaching out of
      plugins/<p>/skills/<s>/). Files named test_* are skipped.

Violations may be allowlisted per skill in scripts/skill-portability-allowlist.txt, a ratchet: the
checker fails on a STALE line (skill now clean or gone), so the list can only shrink.

  scripts/check-skill-portability.py [--root DIR] [--allowlist FILE]
  exit 0 = clean or only allowlisted violations; exit 1 = new violation or stale allowlist entry.

Root layout: if <root>/plugins exists, scan plugins/*/skills/*/SKILL.md (a repo clone); otherwise
scan <root>/*/SKILL.md (an installed layout such as .agents/skills).
"""
import argparse
import re
import sys
from pathlib import Path

SKIP_DIRS = {"node_modules", ".pytest_cache", "__pycache__"}
SCAN_SUFFIXES = {".md", ".sh", ".py", ".mjs", ".js", ".json", ".txt", ".template"}
CODE_SUFFIXES = {".sh", ".py", ".mjs", ".js"}

R1_RE = re.compile(r"\$\{?CLAUDE_PLUGIN_ROOT\b")
R2_RE = re.compile(r"(?<![/\w])plugins/[A-Za-z0-9._-]+/")
R3_SPAN_RE = re.compile(r"`([^`\n]+)`")
R3_PATH_RE = re.compile(
    r"(?<![\w/.-])(\.\./[a-z0-9][a-z0-9-]*/)?"
    r"(?:references|scripts|templates|technologies|categories|agents|assets)/[^`\s]*"
)
R3_SKIP_CHARS = set("{}*<>$")
LINE_SUFFIX_RE = re.compile(r":\d.*$")
R4_RE = re.compile(r"\.\./\.\./\.\./|parents\[(\d+)\]")


def find_skills(root):
    root = Path(root)
    if (root / "plugins").is_dir():
        found = root.glob("plugins/*/skills/*/SKILL.md")
    else:
        found = root.glob("*/SKILL.md")
    return sorted(p.parent for p in found)


def skill_files(folder):
    for p in sorted(folder.rglob("*")):
        if not p.is_file() or p.suffix not in SCAN_SUFFIXES:
            continue
        if any(part in SKIP_DIRS for part in p.relative_to(folder).parts):
            continue
        yield p


def scan_skill(folder):
    """Return a list of (rule, relpath, lineno, snippet) for one skill folder."""
    out = []
    for path in skill_files(folder):
        rel = path.relative_to(folder).as_posix()
        is_test = path.name.startswith("test_")
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for n, line in enumerate(lines, 1):
            snip = line.strip()[:120]
            if R1_RE.search(line):
                out.append(("R1", rel, n, snip))
            if not is_test and R2_RE.search(line):
                out.append(("R2", rel, n, snip))
            if path.suffix in CODE_SUFFIXES and not is_test:
                for m in R4_RE.finditer(line):
                    if m.group(1) is None or int(m.group(1)) >= 3:
                        out.append(("R4", rel, n, snip))
                        break
            if path.suffix == ".md":
                for span in R3_SPAN_RE.findall(line):
                    for m in R3_PATH_RE.finditer(span):
                        token = LINE_SUFFIX_RE.sub("", m.group(0))
                        if R3_SKIP_CHARS & set(token):
                            continue
                        if not (folder / token).exists():
                            out.append(("R3", rel, n, f"`{token}` not found"))
    return out


def load_allowlist(path):
    allowed = {}
    p = Path(path)
    if not p.is_file():
        return allowed
    for raw in p.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name, _, reason = line.partition(" ")
        allowed[name] = reason.strip()
    return allowed


def main(argv=None):
    here = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=str(here.parent))
    ap.add_argument("--allowlist", default=str(here / "skill-portability-allowlist.txt"))
    args = ap.parse_args(argv)

    allowed = load_allowlist(args.allowlist)
    skills = find_skills(args.root)
    violations = known = 0
    dirty = set()
    for folder in skills:
        name = folder.name
        for rule, rel, n, snip in scan_skill(folder):
            dirty.add(name)
            if name in allowed:
                known += 1
                print(f"KNOWN {name} {rule} {rel}:{n}: {snip}")
            else:
                violations += 1
                print(f"VIOLATION {name} {rule} {rel}:{n}: {snip}")
    stale = sorted(set(allowed) - dirty)
    for name in stale:
        print(f"STALE {name}  (allowlisted but clean or not found — remove the line)")
    print(f"skill portability: {len(skills)} skill(s) scanned, {violations} violation(s), "
          f"{known} known, {len(stale)} stale")
    return 1 if violations or stale else 0


if __name__ == "__main__":
    sys.exit(main())
