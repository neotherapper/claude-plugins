#!/usr/bin/env python3
"""
coverage-metrics.py — Deterministic coverage-gate metrics for the reframe skill.

Reads a crawled page in Markdown format (as returned by Jina Reader / Firecrawl)
and computes the four numeric metrics that the reframe "coverage-first" pipeline
gates on (Phases 3–4, see references/crawl-and-coverage.md).

Usage:
    python3 coverage-metrics.py <path-to-markdown-file>
    python3 coverage-metrics.py --stdin

Exits 0 on success, 2 on usage/IO error (message on stderr).
Output: a single JSON object on stdout.
"""

import argparse
import json
import re
import sys

# ---------------------------------------------------------------------------
# Gate thresholds — used verbatim in gate-signal names; do not rename.
# References: crawl-and-coverage.md § Phase 3
# ---------------------------------------------------------------------------

# Render gate: body text under this → SPA shell, needs JS re-render.
RENDER_MIN_BODY_CHARS = 200
# Render gate: zero nav links → SPA shell (all content rendered client-side).
RENDER_MIN_NAV_LINKS = 1  # must have at least 1

# Content-sufficiency gate: both must be true simultaneously.
GREENFIELD_MAX_UNIQUE_HEADINGS = 2   # exclusive: < 2 means 0 or 1
GREENFIELD_MAX_PROSE_WORDS = 150     # exclusive: < 150


# ---------------------------------------------------------------------------
# Metric: body_text_chars
# ---------------------------------------------------------------------------

def compute_body_text_chars(markdown: str) -> int:
    """
    Count of non-whitespace characters of *visible* body text.

    Stripping strategy (applied in order so earlier passes don't confuse later ones):
      1. Multi-line fenced code blocks (``` or ~~~) — removed entirely; code is
         not visible prose in the rendered view most users see.
      2. Inline code (`...`) — removed entirely.
      3. Markdown images ![alt](url) — removed entirely (not text).
      4. Markdown links [text](url) → replaced by the visible link text only.
      5. Heading markers (leading # characters + space) — stripped; heading text
         stays because it IS visible.
      6. Blockquote markers (leading >) — stripped; quote text stays.
      7. List bullet markers (-, *, +, or ordered `1.`) at line start — stripped.
      8. Table pipe characters (|) — stripped.
      9. Emphasis / strong / strikethrough markers (* _ ~ in pairs) — stripped.
     10. HTML tags if any leaked through — stripped.

    After all stripping, count non-whitespace characters via
        len(re.sub(r'\\s+', '', cleaned))
    so that every visible letter, digit, and punctuation mark counts once.
    """
    text = markdown

    # 1. Fenced code blocks (``` or ~~~, possibly with language tag)
    text = re.sub(r'```[\s\S]*?```', '', text)
    text = re.sub(r'~~~[\s\S]*?~~~', '', text)

    # 2. Inline code
    text = re.sub(r'`[^`]*`', '', text)

    # 3. Markdown images: ![alt](url) → remove
    text = re.sub(r'!\[([^\]]*)\]\([^)]*\)', '', text)

    # 4. Markdown links: [text](url) → keep text
    text = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', text)

    # Process line-by-line for structural markers
    lines = text.splitlines()
    cleaned_lines = []
    for line in lines:
        # 5. Heading markers: strip leading #+ and the mandatory space
        line = re.sub(r'^#{1,6}\s+', '', line)
        # 6. Blockquote: strip leading > (possibly nested)
        line = re.sub(r'^(\s*>\s*)+', '', line)
        # 7. List bullets: -, *, + or ordered digit(s) + period/paren at line start
        line = re.sub(r'^\s*[-*+]\s+', '', line)
        line = re.sub(r'^\s*\d+[.)]\s+', '', line)
        # 8. Table pipes
        line = line.replace('|', '')
        # 9. Emphasis/strong/strikethrough (greedy pairs of *, _, ~)
        line = re.sub(r'\*{1,3}(.*?)\*{1,3}', r'\1', line)
        line = re.sub(r'_{1,3}(.*?)_{1,3}', r'\1', line)
        line = re.sub(r'~~(.*?)~~', r'\1', line)
        # 10. Residual HTML tags
        line = re.sub(r'<[^>]+>', '', line)
        cleaned_lines.append(line)

    cleaned = '\n'.join(cleaned_lines)
    # Count non-whitespace characters
    return len(re.sub(r'\s', '', cleaned))


# ---------------------------------------------------------------------------
# Metric: nav_link_count
# ---------------------------------------------------------------------------

def compute_nav_link_count(markdown: str) -> int:
    """
    Number of Markdown hyperlinks [text](url) in the document.

    Used as a structural proxy: zero links → client-side SPA shell (renders nothing
    without JS), which triggers the render gate.

    Counting rules:
      - Matches [text](url) where url is non-empty.
      - Excludes Markdown images (![alt](url)) via a negative lookbehind on '!'.
      - Does NOT require 'url' to be an http URL — relative paths and anchors count;
        the metric is a structural proxy, not an external-link checker.
      - Reference-style links ([text][ref]) are NOT counted because their resolution
        requires a second-pass lookup; Jina/Firecrawl output uses inline links.
    """
    # Negative lookbehind for '!' to exclude images
    pattern = re.compile(r'(?<!!)\[([^\]]*)\]\(([^)]+)\)')
    return len(pattern.findall(markdown))


# ---------------------------------------------------------------------------
# Metric: unique_headings
# ---------------------------------------------------------------------------

def compute_unique_headings(markdown: str) -> int:
    """
    Number of DISTINCT heading texts in the document.

    A heading line matches ^#{1,6}\\s+ (ATX-style Markdown headings, levels 1–6).
    The heading marker is stripped, and the remaining text is lowercased and
    stripped of surrounding whitespace before deduplication.

    Setext-style headings (underlined with === or ---) are NOT counted; Jina Reader
    and Firecrawl consistently emit ATX-style output.

    Distinctness is case-insensitive so "About Us" and "about us" count once.
    """
    heading_pattern = re.compile(r'^#{1,6}\s+(.*)', re.MULTILINE)
    seen = set()
    for match in heading_pattern.finditer(markdown):
        heading_text = match.group(1).strip().lower()
        if heading_text:
            seen.add(heading_text)
    return len(seen)


# ---------------------------------------------------------------------------
# Metric: non_nav_prose_words
# ---------------------------------------------------------------------------

def compute_non_nav_prose_words(markdown: str) -> int:
    """
    Word count of prose text — words on lines that are NOT headings, NOT blank,
    and NOT "nav-only" list items.

    Exact rule implemented (each condition must hold for the line to be excluded):
      Heading lines: ^#{1,6}\\s+ — always excluded.
      Blank lines: lines whose stripped content is empty — always excluded.
      Nav-only list items: a line is excluded when:
        (a) it starts with a list bullet (-, *, +) or an ordered marker (digit + . or )),
        AND (b) after stripping the bullet, ALL remaining content consists solely of
            Markdown links [text](url) and whitespace — i.e. no free prose remains.
        This catches nav menus rendered as bullet lists of bare links.

    Lines that are part of fenced code blocks are also excluded (code is not prose).

    Words are counted by splitting on whitespace after stripping emphasis/link markup
    from the surviving text so that "[Click here](url)" on a prose line does not
    count "Click](url)" as one word.
    """
    # First, strip fenced code blocks
    text = re.sub(r'```[\s\S]*?```', '', markdown)
    text = re.sub(r'~~~[\s\S]*?~~~', '', text)

    heading_re = re.compile(r'^#{1,6}\s+')
    bullet_re = re.compile(r'^\s*[-*+]\s+|^\s*\d+[.)]\s+')
    link_re = re.compile(r'\[([^\]]*)\]\([^)]*\)')
    image_re = re.compile(r'!\[([^\]]*)\]\([^)]*\)')

    total_words = 0

    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        if heading_re.match(stripped):
            continue

        # Check for nav-only list item
        bullet_match = bullet_re.match(stripped)
        if bullet_match:
            content_after_bullet = stripped[bullet_match.end():]
            # Remove all link syntax from the content
            no_links = image_re.sub('', content_after_bullet)
            no_links = link_re.sub('', no_links)
            # If only whitespace remains, it's a nav-only item — skip
            if not no_links.strip():
                continue

        # This is a prose line — count words after light cleanup
        # Remove images, collapse links to their text, strip emphasis
        line = stripped
        line = image_re.sub('', line)
        line = link_re.sub(r'\1', line)
        line = re.sub(r'\*{1,3}(.*?)\*{1,3}', r'\1', line)
        line = re.sub(r'_{1,3}(.*?)_{1,3}', r'\1', line)
        line = re.sub(r'~~(.*?)~~', r'\1', line)
        # Strip blockquote, list, table markers
        line = re.sub(r'^(\s*>\s*)+', '', line)
        line = re.sub(r'^\s*[-*+]\s+|^\s*\d+[.)]\s+', '', line)
        line = line.replace('|', '')
        # Strip inline code (content still considered prose length, but clean tokens)
        line = re.sub(r'`[^`]*`', '', line)
        line = re.sub(r'<[^>]+>', '', line)

        words = line.split()
        total_words += len(words)

    return total_words


# ---------------------------------------------------------------------------
# Gate signals
# ---------------------------------------------------------------------------

def compute_signals(
    body_text_chars: int,
    nav_link_count: int,
    unique_headings: int,
    non_nav_prose_words: int,
) -> list:
    """
    Emit gate signals based on metric values.

    Render gate   → [RENDER-ESCALATED]   when body_text_chars < 200 OR nav_link_count == 0
    Content gate  → [GREENFIELD-MODE]    when unique_headings < 2 AND non_nav_prose_words < 150

    Signal names are verbatim — the reframe skill reads them by exact string match.
    """
    signals = []

    if body_text_chars < RENDER_MIN_BODY_CHARS or nav_link_count < RENDER_MIN_NAV_LINKS:
        signals.append("[RENDER-ESCALATED]")

    if unique_headings < GREENFIELD_MAX_UNIQUE_HEADINGS and non_nav_prose_words < GREENFIELD_MAX_PROSE_WORDS:
        signals.append("[GREENFIELD-MODE]")

    return signals


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def analyse(markdown: str) -> dict:
    """Compute all four metrics and gate signals for the given markdown string."""
    body_text_chars = compute_body_text_chars(markdown)
    nav_link_count = compute_nav_link_count(markdown)
    unique_headings = compute_unique_headings(markdown)
    non_nav_prose_words = compute_non_nav_prose_words(markdown)
    signals = compute_signals(
        body_text_chars, nav_link_count, unique_headings, non_nav_prose_words
    )
    return {
        "body_text_chars": body_text_chars,
        "nav_link_count": nav_link_count,
        "unique_headings": unique_headings,
        "non_nav_prose_words": non_nav_prose_words,
        "signals": signals,
    }


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Compute coverage-gate metrics from a crawled page in Markdown format. "
            "Prints a JSON object to stdout."
        )
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "file",
        nargs="?",
        metavar="PATH",
        help="Path to the markdown file to analyse.",
    )
    group.add_argument(
        "--stdin",
        action="store_true",
        help="Read markdown from stdin instead of a file.",
    )
    args = parser.parse_args()

    try:
        if args.stdin:
            markdown = sys.stdin.read()
        else:
            with open(args.file, "r", encoding="utf-8") as fh:
                markdown = fh.read()
    except (OSError, IOError) as exc:
        print(f"Error reading input: {exc}", file=sys.stderr)
        sys.exit(2)

    result = analyse(markdown)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
