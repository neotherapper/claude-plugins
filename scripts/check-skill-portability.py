#!/usr/bin/env python3
"""check-skill-portability.py — fail when a skill depends on anything outside its own folder.

Why: `npx skills add <repo>` (Pi, OpenCode, Cline, Kiro, Codex, ... 70+ harnesses) copies ONE skill
folder into the user's project. Nothing outside that folder travels, so a skill that reads a plugin
root resource, a repo-relative path, or climbs out of its folder works in a clone and in Claude Code
but breaks silently everywhere else. Five rules, applied per skill folder (a dir holding SKILL.md):

  R1  ${CLAUDE_PLUGIN_ROOT} or $CLAUDE_PLUGIN_ROOT anywhere (only Claude Code defines it).
  R2  repo-relative `plugins/<name>/` paths (they only exist in a clone). URLs such as
      raw.githubusercontent.com/.../plugins/<name>/... are fine. Files named test_* are skipped.
  R3  in .md files, a path starting with references|scripts|templates|technologies|categories|
      agents|assets|skills (optionally `../<sibling-skill>/`) must exist relative to the SKILL
      FOLDER. Checked in backticked spans, in Markdown link targets `](target)` (http(s):, #anchor
      and mailto: are skipped), and on every line inside fenced code blocks. `skills/...` is
      plugin-root-relative, so it never resolves from a skill folder and is always flagged.
      Tokens with { } * < > $ are placeholders or output paths and are skipped; a :line suffix
      is stripped; in fenced blocks a path directly followed by `|` (regex alternation) is skipped. Also flagged: any `../../` in a .md file (leaves the plugin's skills dir).
  R4  in .sh/.py/.mjs/.js, anything reaching 3+ levels up out of plugins/<p>/skills/<s>/:
      `../../../` or `../../..` , `parents[N]` with N >= 3, 3+ chained `.parent`, or 3+ `'..'`
      path arguments. Files named test_* are skipped.
  R5  every SKILL.md must contain the path-convention line (see CONVENTION below), telling the
      agent to resolve relative paths against the SKILL.md folder.

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
R2_RE = re.compile(r"(?<![/\w.-])plugins/[A-Za-z0-9._-]+/")
R3_SPAN_RE = re.compile(r"`([^`\n]+)`")
R3_PREFIXES = "references|scripts|templates|technologies|categories|agents|assets|skills"
R3_PATH_RE = re.compile(
    r"(?<![\w/.-])(\.\./[a-z0-9][a-z0-9-]*/)?(?:" + R3_PREFIXES + r")/[^`\s]*"
)
R3_RAW_PATH_RE = re.compile(
    r"(?<![\w/.-])(\.\./[a-z0-9][a-z0-9-]*/)?(?:" + R3_PREFIXES + r")/[^`\s\"'()\[\]|]*"
)
R3_LINK_RE = re.compile(r"\]\(\s*<?([^)\s>]+)")
R3_EXTERNAL_RE = re.compile(r"^(?:https?:|mailto:|#)", re.I)
R3_DOTDOT_RE = re.compile(r"(?<![\w.])\.\./\.\./")
# The one sanctioned climb: an optional read of the plugin manifest (beacon's version stamp),
# which the skill must treat as absent in a skills-CLI copy ("unversioned").
OPTIONAL_PLUGIN_ROOT_READS = ("../../.claude-plugin/plugin.json",)
FENCE_RE = re.compile(r"^\s*(```|~~~)")
CONVENTION = ("> Paths in this skill are relative to the folder that contains this SKILL.md. "
              "Resolve them to absolute paths before reading a file or running a script.")
R3_SKIP_CHARS = set("{}*<>$")
LINE_SUFFIX_RE = re.compile(r":\d.*$")
R4_RE = re.compile(r"\.\./\.\./\.\.(?![\w.])|parents\[(\d+)\]|(?:\.parent\b){3,}"
                   r"|(?:['\"]\.\.['\"]\s*,\s*){2,}['\"]\.\.['\"]")


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
        in_fence = False
        has_convention = any(ln.strip() == CONVENTION for ln in lines)
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
                if FENCE_RE.match(line):
                    in_fence = not in_fence
                    continue
                stripped = line
                for ok in OPTIONAL_PLUGIN_ROOT_READS:
                    stripped = stripped.replace(ok, "")
                if R3_DOTDOT_RE.search(stripped):
                    out.append(("R3", rel, n, "`../../` leaves the skill's plugin"))
                cands = []
                if in_fence:
                    # a path directly followed by `|` is a regex alternation (grep -E 'a/|b/'), not a path
                    cands += [m.group(0) for m in R3_RAW_PATH_RE.finditer(line)
                              if line[m.end():m.end() + 1] != "|"]
                else:
                    for span in R3_SPAN_RE.findall(line):
                        cands += [m.group(0) for m in R3_PATH_RE.finditer(span)]
                    for target in R3_LINK_RE.findall(line):
                        if R3_EXTERNAL_RE.match(target):
                            continue
                        target = target.split("#", 1)[0]
                        if target.startswith("./"):
                            target = target[2:]
                        cands += [m.group(0) for m in R3_PATH_RE.finditer(target)]
                seen = set()
                for raw in cands:
                    token = LINE_SUFFIX_RE.sub("", raw).rstrip(".,;:")
                    if token in seen or R3_SKIP_CHARS & set(token):
                        continue
                    seen.add(token)
                    if not (folder / token).exists():
                        out.append(("R3", rel, n, f"`{token}` not found"))
        if path.name == "SKILL.md" and path.parent == folder and not has_convention:
            out.append(("R5", rel, 1, "missing path-convention line"))
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
