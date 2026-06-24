#!/usr/bin/env python3
"""
detect-category.py — Deterministic category-pack detector for the reframe plugin.

Scores each category pack's detect_signals against a crawled site corpus and
returns the dominant category as JSON.

ASSUMPTIONS AND DESIGN DECISIONS
---------------------------------
1. Frontmatter parsing: The YAML frontmatter is extracted from between the
   first two `---` lines. The `detect_signals:` value is an INLINE list
   formatted as a Python-compatible list literal (e.g. ["cart", "checkout"]).
   We extract the bracketed expression and parse it with ast.literal_eval —
   this is safe (literal_eval cannot execute arbitrary code) and correct as
   long as pack authors follow the convention documented in the template.
   If parsing fails, the pack is treated as having empty signals (score = 0)
   and a warning is emitted to stderr.

2. Signal matching: Signals are matched as case-insensitive substrings of the
   corpus text. A signal like "add to cart" will match anywhere in the corpus
   regardless of surrounding characters. Short signals (e.g. "API") will also
   match within longer tokens (e.g. "APIs") — this is intentional; the skill
   spec says "prefer longer/more-specific signals", which is addressed by
   counting all matching signals (a pack with more specific signals will
   typically outscore one with vague short signals on the same corpus).

3. Winner selection (matches Phase 7 rules and docs/MODULAR_KNOWLEDGE_PACKS.md §3b/§4):
   - Highest total score wins (dominant pick — packs are never merged).
   - If the top score is 0 (no signals matched), winner = "generic" (the
     empty-signals fallback defined in MODULAR_KNOWLEDGE_PACKS.md §3b).
   - On a tie between two or more non-generic packs at the highest score, the
     script CANNOT break the tie deterministically. It sets tie=true, lists
     the tied packs, and sets winner="generic" — the documented safe fallback
     (MODULAR_KNOWLEDGE_PACKS.md §4: "If still equal, fall back to the
     generic/baseline file"). The skill/model then resolves by section coverage
     as described in Phase 7.
   - generic is always excluded from tie consideration (it has no detect_signals
     and would always score 0; it is a fallback, not a competitor).

OUTPUT JSON
-----------
{
  "winner": "<category>",   # category key (filename without .md)
  "scores": { "<category>": <int>, ... },  # all non-generic packs
  "tie": <bool>,            # true only when 2+ non-generic packs share the top score
  "tied": ["<cat>", ...]   # the tied pack names (empty list when tie=false)
}

EXIT CODES
----------
0 — success (JSON printed to stdout)
2 — usage or I/O error
"""

import argparse
import ast
import json
import os
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Frontmatter parsing
# ---------------------------------------------------------------------------

def _extract_frontmatter_block(text: str) -> str:
    """Return the raw text between the first pair of '---' delimiters, or ''."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return ""
    end = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end = i
            break
    if end is None:
        return ""
    return "\n".join(lines[1:end])


def _parse_detect_signals(frontmatter: str, pack_name: str) -> list[str]:
    """
    Find the detect_signals: line in frontmatter and parse its inline list.

    The value is expected to be a Python-compatible list literal on a single
    line: detect_signals: ["a", "b", "c"]. We extract the bracketed expression
    and evaluate it with ast.literal_eval (safe: cannot execute arbitrary code).

    Returns [] on any parse failure, with a warning to stderr.
    """
    for line in frontmatter.splitlines():
        stripped = line.strip()
        if not stripped.startswith("detect_signals:"):
            continue
        # Everything after the key colon
        value_part = stripped[len("detect_signals:"):].strip()
        if not value_part:
            return []
        # Find the outermost [...] expression
        match = re.search(r"\[.*\]", value_part)
        if not match:
            return []
        bracket_expr = match.group(0)
        try:
            result = ast.literal_eval(bracket_expr)
            if isinstance(result, list):
                return [str(s) for s in result]
            _warn(f"detect_signals in '{pack_name}' is not a list — treating as empty")
            return []
        except (ValueError, SyntaxError) as exc:
            _warn(f"Could not parse detect_signals in '{pack_name}': {exc} — treating as empty")
            return []
    # Key not found
    return []


# ---------------------------------------------------------------------------
# Pack loading
# ---------------------------------------------------------------------------

def load_packs(categories_dir: Path) -> dict[str, list[str]]:
    """
    Load all *.md files in categories_dir and parse their detect_signals.

    Returns a dict: { category_key: [signal, ...] }
    where category_key is the filename stem (e.g. "ecommerce").
    """
    packs: dict[str, list[str]] = {}
    md_files = sorted(categories_dir.glob("*.md"))
    if not md_files:
        _die(f"No .md files found in categories directory: {categories_dir}")

    for md_path in md_files:
        if md_path.name.startswith("_"):
            # Skip templates (e.g. _TEMPLATE.md)
            continue
        key = md_path.stem
        try:
            text = md_path.read_text(encoding="utf-8")
        except OSError as exc:
            _warn(f"Could not read '{md_path}': {exc} — skipping")
            continue
        frontmatter = _extract_frontmatter_block(text)
        signals = _parse_detect_signals(frontmatter, key)
        packs[key] = signals

    if "generic" not in packs:
        _die("categories/generic.md not found — it is required as the fallback pack")

    return packs


# ---------------------------------------------------------------------------
# Corpus loading
# ---------------------------------------------------------------------------

def load_corpus(corpus_path: Path) -> str:
    """
    Load the corpus text from a file or directory.

    If corpus_path is a file, read it directly.
    If corpus_path is a directory, concatenate all *.md files found recursively
    under it (sorted for determinism).

    Returns the combined text as a single string.
    """
    if corpus_path.is_file():
        try:
            return corpus_path.read_text(encoding="utf-8")
        except OSError as exc:
            _die(f"Could not read corpus file '{corpus_path}': {exc}")

    if corpus_path.is_dir():
        parts: list[str] = []
        md_files = sorted(corpus_path.rglob("*.md"))
        if not md_files:
            _warn(f"No *.md files found under corpus directory '{corpus_path}' — corpus is empty")
            return ""
        for md_path in md_files:
            try:
                parts.append(md_path.read_text(encoding="utf-8"))
            except OSError as exc:
                _warn(f"Could not read corpus file '{md_path}': {exc} — skipping")
        return "\n".join(parts)

    _die(f"Corpus path '{corpus_path}' is neither a file nor a directory")


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------

def score_packs(packs: dict[str, list[str]], corpus: str) -> dict[str, int]:
    """
    Score each pack by counting how many of its detect_signals appear in
    the corpus as case-insensitive substrings.

    Signals are matched as case-insensitive substrings: a signal matches if
    it appears anywhere in the corpus text regardless of surrounding characters
    (e.g. "API" matches "APIs", "APIV2", etc.). This is intentional — the
    skill prefers longer/more-specific signals to win, and substring matching
    ensures no match is missed due to surrounding context.

    generic always scores 0 (it has no detect_signals) and is excluded from
    the returned scores dict to keep the output clean.
    """
    corpus_lower = corpus.lower()
    scores: dict[str, int] = {}
    for key, signals in packs.items():
        if key == "generic":
            continue  # generic is the fallback, not a competitor
        count = sum(1 for sig in signals if sig.lower() in corpus_lower)
        scores[key] = count
    return scores


# ---------------------------------------------------------------------------
# Winner selection
# ---------------------------------------------------------------------------

def pick_winner(scores: dict[str, int]) -> tuple[str, bool, list[str]]:
    """
    Apply the documented winner-selection rules.

    Returns (winner, tie, tied_list):
      winner  — the winning category key
      tie     — True when two or more non-generic packs share the top score
      tied    — list of tied pack names (empty when tie is False)

    Rules (Phase 7 + MODULAR_KNOWLEDGE_PACKS.md §3b/§4):
    1. If all scores are 0 → winner = "generic" (no signals matched).
    2. If exactly one pack has the highest score → that pack wins.
    3. If two or more packs share the highest score → tie=True, winner="generic"
       (the script cannot break the tie deterministically; the skill/model
       resolves by section coverage).
    """
    if not scores:
        return "generic", False, []

    max_score = max(scores.values())

    if max_score == 0:
        return "generic", False, []

    top_packs = [k for k, v in scores.items() if v == max_score]

    if len(top_packs) == 1:
        return top_packs[0], False, []

    # Tie between 2+ non-generic packs
    return "generic", True, sorted(top_packs)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _warn(msg: str) -> None:
    print(f"WARNING: {msg}", file=sys.stderr)


def _die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(2)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="detect-category",
        description=(
            "Score reframe category packs against a site corpus and print "
            "the dominant category as JSON."
        ),
    )
    parser.add_argument(
        "--categories",
        required=True,
        metavar="DIR",
        help="Path to the directory containing category pack *.md files.",
    )
    parser.add_argument(
        "--corpus",
        required=True,
        metavar="FILE_OR_DIR",
        help=(
            "Path to the site corpus. May be a single text/markdown file or "
            "a directory (all *.md files under it are concatenated)."
        ),
    )
    return parser


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    categories_dir = Path(args.categories)
    if not categories_dir.is_dir():
        _die(f"--categories path is not a directory: {categories_dir}")

    corpus_path = Path(args.corpus)
    if not corpus_path.exists():
        _die(f"--corpus path does not exist: {corpus_path}")

    packs = load_packs(categories_dir)
    corpus = load_corpus(corpus_path)
    scores = score_packs(packs, corpus)
    winner, tie, tied = pick_winner(scores)

    output = {
        "winner": winner,
        "scores": scores,
        "tie": tie,
        "tied": tied,
    }
    print(json.dumps(output, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
