import subprocess, sys, tempfile, textwrap, unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "check-skill-portability.py"

def run(root, allow=""):
    al = Path(root) / "allow.txt"
    al.write_text(allow)
    p = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root), "--allowlist", str(al)],
                       capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr

def skill(root, plugin, name, body, files=None):
    d = Path(root) / "plugins" / plugin / "skills" / name
    d.mkdir(parents=True)
    (d / "SKILL.md").write_text(f"---\nname: {name}\ndescription: x\n---\n# {name}\n" + textwrap.dedent(body))
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

    def test_installed_flat_layout(self):
        d = Path(self.root) / "flat"; (d / "a").mkdir(parents=True)
        (d / "a" / "SKILL.md").write_text("# a\nRead `references/missing.md`.\n")
        al = Path(self.root) / "allow.txt"; al.write_text("")
        p = subprocess.run([sys.executable, str(SCRIPT), "--root", str(d), "--allowlist", str(al)],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 1); self.assertIn("R3", p.stdout)

if __name__ == "__main__":
    unittest.main()
