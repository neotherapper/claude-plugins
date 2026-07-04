"""Shared skill discovery + YAML frontmatter parsing.

Used by scripts/sync-skills.sh and scripts/validate-marketplace.sh so both scripts
agree on what a skill's frontmatter contains — including folded/literal block
scalars (`description: >`), which a naive line-scan would truncate to the bare
indicator.
"""
import os
import re

# YAML block scalar header: "|" or ">" followed optionally by a chomping
# indicator ("+"/"-") and/or an indentation indicator (a digit 1-9), in either
# order, each at most once. Matches: >, |, >-, |+, >2, |-1, >1+, etc.
_BLOCK_SCALAR_RE = re.compile(r"^[|>]([+-][1-9]?|[1-9][+-]?)?$")
_KEY_RE = re.compile(r"^([A-Za-z_][\w-]*):\s*(.*)$")


def parse_frontmatter(path):
    """Parse a markdown file's `---`-delimited YAML frontmatter into a flat dict.

    Handles plain `key: value` scalars and folded/literal block scalars. Returns
    None if the file has no frontmatter block.
    """
    text = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return None
    lines = m.group(1).split("\n")
    out = {}
    for i, ln in enumerate(lines):
        mm = _KEY_RE.match(ln)
        if not mm:
            continue
        key, val = mm.group(1), mm.group(2).strip()
        if _BLOCK_SCALAR_RE.match(val):
            buf = []
            for nxt in lines[i + 1:]:
                if re.match(r"^\s+", nxt) or nxt.strip() == "":
                    buf.append(nxt.strip())
                else:
                    break
            val = " ".join(x for x in buf if x)
        out.setdefault(key, val.strip("\"'"))
    return out


def discover_skills(root):
    """Walk plugins/<plugin>/skills/<skill>/SKILL.md under repo root.

    Returns (skills, dupes):
      skills: dict of skill-name -> "plugins/<plugin>/skills/<skill>" (first match wins,
              in sorted-plugin order — deterministic but arbitrary on a real collision)
      dupes:  dict of skill-name -> list of every colliding "plugins/<plugin>/skills/<skill>"
              path (including the one that won), for callers to report and act on
    """
    plugins_dir = os.path.join(root, "plugins")
    skills = {}
    dupes = {}
    if not os.path.isdir(plugins_dir):
        return skills, dupes
    for plugin in sorted(os.listdir(plugins_dir)):
        sdir = os.path.join(plugins_dir, plugin, "skills")
        if not os.path.isdir(sdir):
            continue
        for skill in sorted(os.listdir(sdir)):
            if not os.path.isfile(os.path.join(sdir, skill, "SKILL.md")):
                continue
            rel = f"plugins/{plugin}/skills/{skill}"
            if skill in skills:
                dupes.setdefault(skill, [skills[skill]]).append(rel)
            else:
                skills[skill] = rel
    return skills, dupes
