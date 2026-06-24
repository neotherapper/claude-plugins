#!/usr/bin/env python3
"""
test_coverage_metrics.py — Unit tests for coverage-metrics.py.

Uses importlib to load the hyphenated module filename, then exercises
all four metrics and both gate signals across three page archetypes
plus a known-values fixture for deterministic metric assertions.

Run:
    python3 test_coverage_metrics.py -v
"""

import importlib.util
import os
import unittest

# ---------------------------------------------------------------------------
# Load the hyphenated module (can't use `import coverage-metrics` directly)
# ---------------------------------------------------------------------------
_HERE = os.path.dirname(os.path.abspath(__file__))
_MODULE_PATH = os.path.join(_HERE, "coverage-metrics.py")

spec = importlib.util.spec_from_file_location("coverage_metrics", _MODULE_PATH)
cm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cm)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Fixture 1: Empty / near-empty SPA shell.
# No headings, no links, minimal text < 200 visible chars.
# Expects: [RENDER-ESCALATED] fires (body_text_chars < 200 AND nav_link_count == 0).
# [GREENFIELD-MODE] may also fire (0 headings, near-zero prose) — tests use `in`.
FIXTURE_SPA_SHELL = """\
Loading...

Please enable JavaScript to view this page.
"""

# Fixture 2: Thin placeholder / "coming soon" page.
# Exactly one heading, several links (so RENDER is silent), prose < 150 words.
# body_text_chars >= 200 (clears render gate), nav_link_count > 0 (clears render gate),
# but unique_headings < 2 AND non_nav_prose_words < 150 → [GREENFIELD-MODE] fires.
FIXTURE_COMING_SOON = """\
# Coming Soon

We are working hard to bring you something amazing.
Stay tuned for updates and announcements about our launch.
Our team is dedicated to creating the best possible experience for you.

Check back later or [follow us on Twitter](https://twitter.com/example) for news.
[Contact us](mailto:hello@example.com) if you have questions about our upcoming release.
[Learn more about our team](https://example.com/team) in the meantime.
"""

# Fixture 3: Rich, production-quality page.
# Multiple headings, 200+ prose words, many links.
# Expects: NO signals fire.
FIXTURE_RICH_PAGE = """\
# Welcome to Acme Corporation

At Acme we build reliable tools for modern teams. Our products are trusted by
thousands of companies worldwide. We believe in [open source](https://github.com/acme),
transparency, and excellent developer experience.

## Our Products

We offer a [suite of tools](https://acme.com/products) designed to help teams
ship faster and with more confidence.

- [Acme CLI](https://acme.com/cli) — command-line tool for automation
- [Acme Dashboard](https://acme.com/dashboard) — visual project management

## Why Acme

Our platform is built on three core principles:

**Speed** — sub-second response times for all API calls.
Acme processes millions of requests daily without breaking a sweat.
Our infrastructure is designed for reliability and scale.

**Simplicity** — a clean API that you can learn in an afternoon.
We obsess over documentation and developer experience so you spend time building
rather than debugging third-party integrations. Every endpoint is consistent,
versioned, and backward-compatible.

**Support** — humans answer your questions, not bots.
Our team is available around the clock to help you succeed. We monitor all
integrations in real time and proactively reach out when we detect anomalies.

## Getting Started

1. [Sign up for a free account](https://acme.com/signup)
2. Install the CLI: `npm install -g @acme/cli`
3. Run `acme init` in your project directory

Read the [full documentation](https://docs.acme.com) or [contact us](https://acme.com/contact)
to talk to a human on our team.

## Customers

We are proud to work with [Globex](https://globex.com), [Initech](https://initech.com),
and [Umbrella Corp](https://umbrella.com).

## About Us

Founded in 2018, Acme Corporation is headquartered in San Francisco, CA.
[Meet the team](https://acme.com/about) or [join us](https://acme.com/careers) —
we are always looking for great engineers.
"""

# Fixture 4: Known-values fixture for deterministic metric assertions.
# Minimal, carefully crafted so expected values can be hand-verified.
FIXTURE_KNOWN = """\
# Hello World

This is a short sentence with exactly ten words total here.

- [Nav Link One](https://example.com/one)
- [Nav Link Two](https://example.com/two)

## Second Heading

Another prose sentence.
"""
#
# Expected (hand-verified):
#   body_text_chars: headings/bullets stripped, links collapsed to text.
#     Visible text after stripping:
#       "Hello World" (11), "This is a short sentence with exactly ten words total here." (52),
#       "Nav Link One" (11, from nav-only bullet — still counts for body_text_chars),
#       "Nav Link Two" (11), "Second Heading" (14), "Another prose sentence." (22)
#     = 121 non-whitespace chars (approximate; test uses range)
#   nav_link_count: 2 (the two list-item links)
#   unique_headings: 2 ("hello world" and "second heading")
#   non_nav_prose_words: words on non-heading, non-blank, non-nav-only lines
#     Line "This is a short sentence with exactly ten words total here." → 11 words
#     List items are nav-only (bullet + bare link only) → excluded
#     Line "Another prose sentence." → 3 words
#     Total = 14 words


class TestSpaShell(unittest.TestCase):
    """Fixture 1: near-empty SPA shell → [RENDER-ESCALATED] must fire."""

    def setUp(self):
        self.result = cm.analyse(FIXTURE_SPA_SHELL)

    def test_render_escalated_fires(self):
        self.assertIn("[RENDER-ESCALATED]", self.result["signals"])

    def test_body_text_chars_below_threshold(self):
        self.assertLess(self.result["body_text_chars"], cm.RENDER_MIN_BODY_CHARS)

    def test_nav_link_count_is_zero(self):
        self.assertEqual(self.result["nav_link_count"], 0)


class TestComingSoon(unittest.TestCase):
    """Fixture 2: thin coming-soon page → [GREENFIELD-MODE] fires; [RENDER-ESCALATED] does NOT."""

    def setUp(self):
        self.result = cm.analyse(FIXTURE_COMING_SOON)

    def test_greenfield_mode_fires(self):
        self.assertIn("[GREENFIELD-MODE]", self.result["signals"])

    def test_render_escalated_does_not_fire(self):
        self.assertNotIn("[RENDER-ESCALATED]", self.result["signals"])

    def test_has_links_above_zero(self):
        # Has links, so render gate nav condition is clear
        self.assertGreater(self.result["nav_link_count"], 0)

    def test_body_text_chars_above_render_threshold(self):
        # Enough text to clear the render gate
        self.assertGreaterEqual(self.result["body_text_chars"], cm.RENDER_MIN_BODY_CHARS)

    def test_unique_headings_below_greenfield_threshold(self):
        self.assertLess(self.result["unique_headings"], cm.GREENFIELD_MAX_UNIQUE_HEADINGS)

    def test_prose_words_below_greenfield_threshold(self):
        self.assertLess(self.result["non_nav_prose_words"], cm.GREENFIELD_MAX_PROSE_WORDS)


class TestRichPage(unittest.TestCase):
    """Fixture 3: rich production page → NO gate signals fire."""

    def setUp(self):
        self.result = cm.analyse(FIXTURE_RICH_PAGE)

    def test_no_signals(self):
        self.assertEqual(self.result["signals"], [])

    def test_body_text_chars_above_threshold(self):
        self.assertGreaterEqual(self.result["body_text_chars"], cm.RENDER_MIN_BODY_CHARS)

    def test_nav_link_count_many(self):
        self.assertGreater(self.result["nav_link_count"], 5)

    def test_unique_headings_at_least_two(self):
        self.assertGreaterEqual(self.result["unique_headings"], cm.GREENFIELD_MAX_UNIQUE_HEADINGS)

    def test_prose_words_above_threshold(self):
        self.assertGreaterEqual(self.result["non_nav_prose_words"], cm.GREENFIELD_MAX_PROSE_WORDS)


class TestKnownValues(unittest.TestCase):
    """Fixture 4: hand-computable values → metric correctness checks."""

    def setUp(self):
        self.result = cm.analyse(FIXTURE_KNOWN)

    def test_nav_link_count(self):
        # Two explicit [text](url) links in list bullets
        self.assertEqual(self.result["nav_link_count"], 2)

    def test_unique_headings(self):
        # "# Hello World" and "## Second Heading" → 2 distinct headings
        self.assertEqual(self.result["unique_headings"], 2)

    def test_non_nav_prose_words(self):
        # Only two prose lines:
        #   "This is a short sentence with exactly ten words total here." → 11 words
        #   "Another prose sentence." → 3 words
        # Nav-only list items excluded. Total = 14.
        self.assertEqual(self.result["non_nav_prose_words"], 14)

    def test_body_text_chars_is_positive(self):
        self.assertGreater(self.result["body_text_chars"], 0)

    def test_output_keys(self):
        expected_keys = {
            "body_text_chars",
            "nav_link_count",
            "unique_headings",
            "non_nav_prose_words",
            "signals",
        }
        self.assertEqual(set(self.result.keys()), expected_keys)

    def test_signals_is_list(self):
        self.assertIsInstance(self.result["signals"], list)


class TestDuplicateHeadingsAreDeduped(unittest.TestCase):
    """Duplicate headings count once — deduplication is case-insensitive."""

    def test_duplicates_deduped(self):
        md = "# About Us\n\nSome text.\n\n# About Us\n\nMore text.\n\n# about us\n\nEven more.\n"
        result = cm.analyse(md)
        self.assertEqual(result["unique_headings"], 1)


class TestNavOnlyListItemsExcluded(unittest.TestCase):
    """List items that are pure links do not inflate non_nav_prose_words."""

    def test_pure_nav_list_excluded(self):
        md = "# Menu\n\n- [Home](/)\n- [About](/about)\n- [Contact](/contact)\n"
        result = cm.analyse(md)
        # Only the heading text is visible prose, and headings are excluded too,
        # so prose words = 0
        self.assertEqual(result["non_nav_prose_words"], 0)

    def test_mixed_list_item_included(self):
        # A list item with prose after the link is NOT nav-only
        md = "# Menu\n\n- [Home](/) — the best place to start your journey here\n"
        result = cm.analyse(md)
        self.assertGreater(result["non_nav_prose_words"], 0)


if __name__ == "__main__":
    unittest.main()
