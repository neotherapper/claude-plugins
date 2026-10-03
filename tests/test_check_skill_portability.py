import subprocess, sys, tempfile, textwrap, unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "check-skill-portability.py"

def run(root, allow=""):
    al = Path(root) / "allow.txt"
    al.write_text(allow)
    p = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root), "--allowlist", str(al)],
                       capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr

CONVENTION = ("> Paths in this skill are relative to the folder that contains this SKILL.md. "
              "Resolve them to absolute paths before reading a file or running a script.\n")

def skill(root, plugin, name, body, files=None, convention=True):
    d = Path(root) / "plugins" / plugin / "skills" / name
    d.mkdir(parents=True)
    (d / "SKILL.md").write_text(f"---\nname: {name}\ndescription: x\n---\n# {name}\n"
                                + (CONVENTION if convention else "") + textwrap.dedent(body))
    for rel, txt in (files or {}).items():
        (d / rel).parent.mkdir(parents=True, exist_ok=True)
        (d / rel).write_text(txt)
    return d

class T(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.root = self.tmp.name
    def tearDown(self):
        self.tmp.cleanup()

    def test_clean_skill_passes(self):
        skill(self.root, "p", "a", "Read `references/x.md`.\n", {"references/x.md": "ok"})
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r1_plugin_root(self):
        skill(self.root, "p", "a", "Run `${CLAUDE_PLUGIN_ROOT}/scripts/x.py`.\n")
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R1", out)

    def test_r1_braceless_plugin_root(self):
        skill(self.root, "p", "a", "", {"references/r.md": "See $CLAUDE_PLUGIN_ROOT/skills/a/x.md"})
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R1", out)

    def test_r2_repo_relative_but_not_raw_url(self):
        skill(self.root, "p", "a", "node plugins/p/scripts/x.mjs\n")
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R2", out)

    def test_r2_raw_url_ok(self):
        skill(self.root, "p", "a", "https://raw.githubusercontent.com/o/r/main/plugins/p/x.md\n")
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r2_hyphenated_repo_name_in_url_ok(self):
        skill(self.root, "p", "a", "https://raw.githubusercontent.com/o/claude-plugins/main/plugins/p/x.md\n")
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r3_missing_path(self):
        skill(self.root, "p", "a", "Load `templates/brief.md.template`.\n")
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R3", out)

    def test_r3_placeholder_and_line_suffix_skipped_or_stripped(self):
        skill(self.root, "p", "a", "Write `scripts/test-{slug}.sh`; see `templates/t.md:4,8`.\n",
              {"templates/t.md": "x"})
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r3_resolves_from_skill_root_even_in_references(self):
        skill(self.root, "p", "a", "", {"references/r.md": "See `templates/t.md`.", "templates/t.md": "x"})
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r3_sibling_skill(self):
        skill(self.root, "p", "rec", "", {"technologies/REGISTRY.md": "x"})
        skill(self.root, "p", "intel", "Read `../rec/technologies/REGISTRY.md`.\n")
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r4_escape(self):
        skill(self.root, "p", "a", "", {"scripts/s.sh": 'TPL="$DIR/../../../templates"\n'})
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R4", out)

    def test_allowlisted_is_known_not_failing(self):
        skill(self.root, "p", "a", "Run `${CLAUDE_PLUGIN_ROOT}/x`.\n")
        rc, out = run(self.root, "a  repo-only for now\n"); self.assertEqual(rc, 0, out); self.assertIn("KNOWN", out)

    def test_stale_allowlist_entry_fails(self):
        skill(self.root, "p", "a", "clean\n")
        rc, out = run(self.root, "a  stale\n"); self.assertEqual(rc, 1); self.assertIn("STALE", out)

    def _bad(self, rule, body, files=None):
        skill(self.root, "p", "a", body, files)
        rc, out = run(self.root); self.assertEqual(rc, 1, out); self.assertIn(rule, out)

    def _ok(self, body, files=None):
        skill(self.root, "p", "a", body, files)
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r3_skills_prefix_flagged(self):
        self._bad("R3", "Read `skills/b/references/x.md`.\n")

    def test_r3_markdown_link_target_flagged(self):
        self._bad("R3", "See [guide](references/missing.md).\n")

    def test_r3_markdown_link_existing_and_external_ok(self):
        self._ok("[g](references/x.md#top) [w](https://e.com/references/y) [a](#scripts/z) [m](mailto:a@b.c)\n",
                 {"references/x.md": "x"})

    def test_r3_fenced_block_flagged(self):
        self._bad("R3", "```bash\ncat references/missing.md\n```\n")

    def test_r3_fenced_block_sibling_flagged(self):
        self._bad("R3", "```\nls ../other/scripts/x.sh\n```\n")

    def test_r3_fenced_existing_and_placeholder_ok(self):
        self._ok("```\ncat references/x.md\npython scripts/run-{name}.py \"templates/<slug>.md\"\n```\n",
                 {"references/x.md": "x"})

    def test_r3_fenced_regex_alternation_not_a_path(self):
        self._ok("```\ngrep -oE 'src/Kernel|templates/|at Symfony' f\n```\n")

    def test_r3_prose_outside_fence_not_checked(self):
        self._ok("Read references/missing.md without backticks.\n")

    def test_r3_optional_plugin_manifest_read_ok(self):
        skill(self.root, "p", "a", "Read `version` from `../../.claude-plugin/plugin.json`; if absent, record `unversioned`.\n")
        rc, out = run(self.root); self.assertEqual(rc, 0, out)

    def test_r3_double_dotdot_in_md_flagged(self):
        self._bad("R3", "See ../../README.md for more.\n")

    def test_r4_three_parents(self):
        self._bad("R4", "", {"scripts/s.py": "root = Path(__file__).parent.parent.parent\n"})

    def test_r4_dotdot_without_trailing_slash(self):
        self._bad("R4", "", {"scripts/s.sh": 'ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"\n'})

    def test_r4_node_resolve_three_dotdot_args(self):
        self._bad("R4", "", {"scripts/s.mjs": "const r = path.resolve(__dirname, '..', '..', '..');\n"})

    def test_r4_two_levels_ok(self):
        self._ok("", {"scripts/s.mjs": "const r = path.resolve(__dirname, '..', '..');\n",
                      "scripts/s.py": "p = Path(__file__).parent.parent\n"})

    def test_r5_missing_convention_line(self):
        skill(self.root, "p", "a", "clean\n", convention=False)
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R5 SKILL.md:1: missing path-convention line", out)

    def test_installed_flat_layout(self):
        d = Path(self.root) / "flat"; (d / "a").mkdir(parents=True)
        (d / "a" / "SKILL.md").write_text("# a\nRead `references/missing.md`.\n")
        al = Path(self.root) / "allow.txt"; al.write_text("")
        p = subprocess.run([sys.executable, str(SCRIPT), "--root", str(d), "--allowlist", str(al)],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 1); self.assertIn("R3", p.stdout)

if __name__ == "__main__":
    unittest.main()
