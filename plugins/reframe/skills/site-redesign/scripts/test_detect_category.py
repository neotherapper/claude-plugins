#!/usr/bin/env python3
"""
test_detect_category.py — Unit tests for detect-category.py

Uses only stdlib unittest and tempfile; does NOT depend on the real pack files.
Each test builds its own temporary categories directory so tests are hermetic.

Coverage:
  1. Ecommerce corpus (cart/checkout signals) → winner == ecommerce
  2. Empty/irrelevant corpus → winner == generic
  3. Tie corpus (hits ecommerce AND local-service equally) → tie=True, winner=generic
  4. Single-signal match, no tie → winner is the matched pack
  5. Frontmatter parse fallback: malformed detect_signals treated as []
  6. Corpus as directory (multiple .md files concatenated)
"""

import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

# Load detect-category.py by file path because its hyphenated filename is not
# a valid Python identifier (cannot be imported via a normal `import` statement).
_HERE = Path(__file__).parent
_SCRIPT = _HERE / "detect-category.py"
_spec = importlib.util.spec_from_file_location("detect_category", _SCRIPT)
dc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(dc)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

GENERIC_FRONTMATTER = """---
category: generic
display_name: Generic
detect_signals: []
---

# Generic fallback
"""

ECOMMERCE_FRONTMATTER = """---
category: ecommerce
display_name: E-commerce
detect_signals: ["cart", "checkout"]
---

# E-commerce pack
"""

LOCAL_SERVICE_FRONTMATTER = """---
category: local-service
display_name: Local Service
detect_signals: ["booking", "clinic"]
---

# Local Service pack
"""


def _write_pack(directory: Path, filename: str, content: str) -> None:
    (directory / filename).write_text(content, encoding="utf-8")


def _make_temp_categories(packs: dict[str, str]) -> tempfile.TemporaryDirectory:
    """
    Create a temp directory, write one .md file per key in packs (key = stem).
    Returns the TemporaryDirectory object (caller must keep a reference so it
    isn't cleaned up before use).
    """
    tmpdir = tempfile.TemporaryDirectory()
    p = Path(tmpdir.name)
    for stem, content in packs.items():
        _write_pack(p, f"{stem}.md", content)
    return tmpdir


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestDetectCategory(unittest.TestCase):

    # ------------------------------------------------------------------
    # Test 1: Corpus full of cart/checkout words → winner == ecommerce
    # ------------------------------------------------------------------
    def test_ecommerce_corpus_wins(self):
        """A corpus saturated with ecommerce signals picks ecommerce."""
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            corpus = "Add to cart button, proceed to checkout, view cart summary."
            scores = dc.score_packs(packs, corpus)
            winner, tie, tied = dc.pick_winner(scores)

            self.assertEqual(winner, "ecommerce")
            self.assertFalse(tie)
            self.assertEqual(tied, [])
            # ecommerce must outscore local-service
            self.assertGreater(scores["ecommerce"], scores.get("local-service", 0))

    # ------------------------------------------------------------------
    # Test 2: Empty/irrelevant corpus → winner == generic
    # ------------------------------------------------------------------
    def test_empty_corpus_falls_back_to_generic(self):
        """When no signals match, the winner must be generic (zero-score fallback)."""
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            corpus = "Welcome to our website. We value your privacy."
            scores = dc.score_packs(packs, corpus)
            winner, tie, tied = dc.pick_winner(scores)

            self.assertEqual(winner, "generic")
            self.assertFalse(tie)
            self.assertEqual(tied, [])
            self.assertEqual(scores.get("ecommerce", 0), 0)
            self.assertEqual(scores.get("local-service", 0), 0)

    # ------------------------------------------------------------------
    # Test 3: Tie → tie=True, winner=generic
    # ------------------------------------------------------------------
    def test_tie_resolves_to_generic(self):
        """
        When two non-generic packs score equally, tie=True and winner=generic.
        The script cannot break the tie deterministically; the skill/model resolves
        by section coverage (per MODULAR_KNOWLEDGE_PACKS.md §4).
        """
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            # "cart" matches ecommerce; "booking" matches local-service → equal scores
            corpus = "We have a cart for your items and a booking form for appointments."
            scores = dc.score_packs(packs, corpus)
            winner, tie, tied = dc.pick_winner(scores)

            self.assertTrue(tie, "Expected tie=True when two packs score equally")
            self.assertEqual(winner, "generic")
            self.assertIn("ecommerce", tied)
            self.assertIn("local-service", tied)

    # ------------------------------------------------------------------
    # Test 4: Single clear winner, no tie
    # ------------------------------------------------------------------
    def test_single_winner_no_tie(self):
        """A corpus that matches only local-service signals gives a clean winner."""
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            corpus = "Book an appointment at our clinic today."
            scores = dc.score_packs(packs, corpus)
            winner, tie, tied = dc.pick_winner(scores)

            self.assertEqual(winner, "local-service")
            self.assertFalse(tie)
            self.assertEqual(tied, [])

    # ------------------------------------------------------------------
    # Test 5: Malformed detect_signals treated as []
    # ------------------------------------------------------------------
    def test_malformed_signals_treated_as_empty(self):
        """A pack with an unparseable detect_signals gets score 0 (no crash)."""
        bad_pack = """---
category: badpack
display_name: Bad Pack
detect_signals: [unclosed
---

# Bad pack
"""
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "badpack": bad_pack,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            # badpack signals should have fallen back to []
            self.assertEqual(packs.get("badpack", []), [])

            corpus = "cart checkout badpack"
            scores = dc.score_packs(packs, corpus)

            # ecommerce should win; badpack should score 0
            self.assertEqual(scores.get("badpack", 0), 0)
            self.assertGreater(scores.get("ecommerce", 0), 0)

    # ------------------------------------------------------------------
    # Test 6: Corpus as directory (multiple .md files concatenated)
    # ------------------------------------------------------------------
    def test_corpus_directory_concatenates_md_files(self):
        """When --corpus is a directory, all *.md files are concatenated."""
        tmpdir_cats = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir_cats:
            cats_dir = Path(tmpdir_cats.name)
            packs = dc.load_packs(cats_dir)

            with tempfile.TemporaryDirectory() as corpus_dir_str:
                corpus_dir = Path(corpus_dir_str)
                (corpus_dir / "page1.md").write_text("Visit our clinic for booking.", encoding="utf-8")
                (corpus_dir / "page2.md").write_text("Book your clinic appointment.", encoding="utf-8")
                # No ecommerce signals at all

                corpus = dc.load_corpus(corpus_dir)
                scores = dc.score_packs(packs, corpus)
                winner, tie, tied = dc.pick_winner(scores)

                self.assertEqual(winner, "local-service")
                self.assertFalse(tie)

    # ------------------------------------------------------------------
    # Test 7: Case-insensitive matching
    # ------------------------------------------------------------------
    def test_case_insensitive_matching(self):
        """Signals match regardless of case in the corpus."""
        tmpdir = _make_temp_categories({
            "generic": GENERIC_FRONTMATTER,
            "ecommerce": ECOMMERCE_FRONTMATTER,
            "local-service": LOCAL_SERVICE_FRONTMATTER,
        })
        with tmpdir:
            cats_dir = Path(tmpdir.name)
            packs = dc.load_packs(cats_dir)

            # "CART" and "CHECKOUT" should match signals ["cart", "checkout"]
            corpus = "Click CART to review. Proceed to CHECKOUT now."
            scores = dc.score_packs(packs, corpus)
            winner, tie, tied = dc.pick_winner(scores)

            self.assertEqual(winner, "ecommerce")
            self.assertEqual(scores["ecommerce"], 2)


# ---------------------------------------------------------------------------
# Internal unit tests (parsing helpers)
# ---------------------------------------------------------------------------

class TestFrontmatterParsing(unittest.TestCase):

    def test_extract_frontmatter_basic(self):
        text = "---\nfoo: bar\nbaz: 1\n---\n\n# Body"
        fm = dc._extract_frontmatter_block(text)
        self.assertIn("foo: bar", fm)
        self.assertIn("baz: 1", fm)
        self.assertNotIn("# Body", fm)

    def test_extract_frontmatter_missing_close(self):
        text = "---\nfoo: bar\n\n# Body"
        fm = dc._extract_frontmatter_block(text)
        self.assertEqual(fm, "")

    def test_extract_frontmatter_no_open(self):
        text = "# No frontmatter\nfoo: bar"
        fm = dc._extract_frontmatter_block(text)
        self.assertEqual(fm, "")

    def test_parse_detect_signals_normal(self):
        fm = 'category: test\ndetect_signals: ["cart", "checkout", "shop"]\n'
        signals = dc._parse_detect_signals(fm, "test")
        self.assertEqual(signals, ["cart", "checkout", "shop"])

    def test_parse_detect_signals_empty(self):
        fm = 'category: generic\ndetect_signals: []\n'
        signals = dc._parse_detect_signals(fm, "generic")
        self.assertEqual(signals, [])

    def test_parse_detect_signals_missing_key(self):
        fm = 'category: test\ndisplay_name: Test\n'
        signals = dc._parse_detect_signals(fm, "test")
        self.assertEqual(signals, [])

    def test_parse_detect_signals_malformed(self):
        fm = 'detect_signals: [unclosed\n'
        signals = dc._parse_detect_signals(fm, "bad")
        self.assertEqual(signals, [])


# ---------------------------------------------------------------------------
# Integration test — intentionally NON-hermetic; validates the REAL shipped
# b2b-industrial.md pack file against a realistic B2B distributor corpus.
# Unlike the hermetic tests above (which build their own temp categories dirs),
# this test loads the actual plugins/reframe/categories/ directory so it also
# catches regressions from accidental pack edits.  Future tests of new real
# packs should follow this class's pattern (one method per pack).
# ---------------------------------------------------------------------------

class TestRealPackIntegration(unittest.TestCase):

    def test_b2b_industrial_wins_on_distributor_corpus(self):
        """
        A realistic B2B marine-parts distributor corpus must map to b2b-industrial.

        NON-HERMETIC: loads the real plugins/reframe/categories/ directory so
        it validates the actual shipped pack, not a synthetic stub.
        TDD RED until b2b-industrial.md exists; GREEN after creation.
        """
        real_cats = Path(__file__).parent.parent.parent.parent / "categories"
        corpus = (
            "Request a quote for our industrial valves and marine spare parts. "
            "We are an authorized distributor and OEM supplier. Datasheet PDF, "
            "MOQ, lead time, bulk pricing, RFQ. Wholesale B2B. Ship spares, "
            "on-board repair, technical specifications."
        )
        packs = dc.load_packs(real_cats)
        scores = dc.score_packs(packs, corpus)
        winner, tie, tied = dc.pick_winner(scores)
        self.assertEqual(
            winner,
            "b2b-industrial",
            f"Expected b2b-industrial but got winner={winner!r}; scores={scores}",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
