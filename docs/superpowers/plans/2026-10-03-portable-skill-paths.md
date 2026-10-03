# Portable Skill Paths Implementation Plan

> **For agentic workers:** Each task is executed by a fresh Sonnet subagent and reviewed by the
> controller before the next starts. Steps use checkbox (`- [ ]`) syntax. **Subagents run no git
> commands** — the controller reviews the diff, runs the tests and commits. Skill that helps with
> every SKILL.md / AGENTS.md edit: `mattpocock-skills:writing-for-agents`.

**Goal:** A skill installed with `npx skills add neotherapper/claude-plugins` (Pi, OpenCode, Cline,
Kiro, Codex, …) works from its own folder: no `${CLAUDE_PLUGIN_ROOT}`, no plugin-root resources, no
repo-relative paths — while Claude Code marketplace installs keep working unchanged.

**Architecture:** Move every plugin-root resource a skill needs into that skill's folder
(`git mv`, history kept). Skill text uses paths relative to the folder holding its `SKILL.md`,
stated once at the top of each SKILL.md. Scripts locate siblings from their own file location. A
deterministic checker (`scripts/check-skill-portability.py`) with a ratcheting allowlist gates it
in CI, and an end-to-end CI step installs every skill with the real CLI (`--copy`) and re-runs
the checker plus script smoke tests against the copies.

**Tech Stack:** Python 3 stdlib (checker + unittest), bash, GitHub Actions, `skills@latest` CLI.

**Spec:** the open gap documented by PR #55 (`docs/platform/multi-tool-support.md` →
"Portability gap (open)"; README "What a CLI install carries, per plugin").

## Facts established before planning (2026-10-03)

- The CLI copies the **whole** skill folder (root files like `evaluate/evaluator.md` and arbitrary
  subdirs travel), so resources may live in any subfolder of the skill. PR #55 docs implying "only
  `SKILL.md`, `scripts/`, `references/`" are wrong and get corrected in Task 8.
- Claude Code prints "Base directory for this skill: …" when it loads a skill, so skill-relative
  paths do not regress Claude users.
- Baseline (before any change): every `tests/*.sh`, beacon hook tests, `test_render_query.sh`,
  `test_scaffold.sh`, and the four `scripts/` pytest suites pass **except
  `tests/validate-tech-pack.sh`** ("Exactly 10 numbered H2 sections (found: 13)") — pre-existing,
  not ours to fix; it must not get *worse*.
- Repo tags stop at `v0.6.0` (beacon is 0.10.0), so beacon's "fetch tech pack from
  `v{PLUGIN_VERSION}` tag" fallback already 404s.
- idea-forge dispatches its pipeline agents as `general-purpose` + "read the prompt at …"; nothing
  dispatches them by plugin-agent type.
- `paidagogos/scripts/build-index.mjs` needs `ajv` from the plugin's `node_modules`, and rendering
  needs the `visual-kit` Node app — neither can travel in a skill folder.

## Global Constraints

- Path convention line, verbatim, directly under each SKILL.md's H1:
  `> Paths in this skill are relative to the folder that contains this SKILL.md. Resolve them to absolute paths before reading a file or running a script.`
- Sibling-skill references use `../<sibling-skill>/…` and only within the same plugin. A skill that
  needs a sibling says so in one line ("Requires the `site-recon` skill installed alongside").
- `${CLAUDE_PLUGIN_ROOT}` stays allowed in `commands/`, `hooks/`, `agents/` (Claude-only surfaces),
  never inside `plugins/*/skills/`.
- Scripts find resources via their own location (`$(dirname "$0")`, `Path(__file__)`), never cwd,
  and never climb out of the plugin's `skills/` dir.
- Moves use `git mv` (controller runs it — subagents list the moves they made with plain `mv` and
  the controller re-stages; or controller pre-moves before dispatch, see each task).
- No behaviour change beyond paths, except paidagogos-micro's text fallback (Task 2).

## Review Focus

1. **Single-skill install** (`--skill site-intel` without `site-recon`) — site-intel must say plainly
   it needs site-recon rather than fail silently; checker R3 accepts `../site-recon/…` only because
   the full install ships both.
2. **Symlink farm** (`.agents/skills/<s>` → `plugins/<p>/skills/<s>`): `../sibling/` must resolve
   both lexically (farm) and physically (canonical) — holds because the farm mirrors every skill.
3. **Claude Code plugin install**: commands (`aegis-scan.md`) and hooks still point at the new
   script locations; idea-forge agents still register (plugin.json `agents` path).
4. **Placeholders in paths** (`technologies/{framework}/{major}.x.md`, `scripts/test-{slug}.sh`
   — the latter is an *output* path) — checker must skip `{…}`/`*` tokens, not false-fail.
5. **CI under `CI=true`**: the e2e install step must use `NO_COLOR=1` and `</dev/null` like
   `scripts/check-skills-cli.sh` (the PR #55 colour blocker).

---

### Task 1: Portability checker + ratcheting allowlist + CI step

**Files:**
- Create: `scripts/check-skill-portability.py`
- Create: `scripts/skill-portability-allowlist.txt`
- Create: `tests/test_check_skill_portability.py`
- Modify: `.github/workflows/validate.yml` (add one step after "Skills CLI discovery")

**Interfaces:**
- Produces: `python3 scripts/check-skill-portability.py [--root DIR] [--allowlist FILE]`; exit 0 =
  clean or only allowlisted violations; exit 1 = un-allowlisted violation or stale allowlist entry.
  Output lines: `VIOLATION <skill> <rule> <relpath>:<line>: <snippet>` / `KNOWN …` / `STALE <skill>`.
- Allowlist format: one `<skill-name>  <reason>` per line, `#` comments. Keyed by skill name
  (names are unique — `discover_skills` enforces it).

Rules, applied per skill folder (a dir holding `SKILL.md`; skip `node_modules`, `.pytest_cache`,
`__pycache__`; scan suffixes `.md .sh .py .mjs .js .json .txt .template`):
- **R1** literal `${CLAUDE_PLUGIN_ROOT}` anywhere.
- **R2** repo-relative `plugins/<name>/` not preceded by `/` or a word char (so
  `raw.githubusercontent.com/…/main/plugins/beacon/…` URLs pass). Skip files named `test_*`.
- **R3** in `.md` files only: every backticked token matching
  `(\.\./[a-z0-9][a-z0-9-]*/)?(references|scripts|templates|technologies|categories|agents|assets)/[^`\s]*`
  that contains none of `{ } * < > $` must exist (file or dir) relative to the **skill folder**
  (not the md file's own dir); strip a trailing `:<digits>…` line suffix first.
- **R4** in `.sh .py .mjs .js`: `../../../` or `parents[N]` with N ≥ 3. Skip files named `test_*`.

Root discovery: if `<root>/plugins` is a dir → `plugins/*/skills/*/SKILL.md`; else `<root>/*/SKILL.md`
(installed layout, e.g. `.agents/skills`). Default root = repo root (parent of `scripts/`); default
allowlist = `scripts/skill-portability-allowlist.txt`.

- [ ] **Step 1: Write the failing tests** — `tests/test_check_skill_portability.py`, stdlib `unittest`,
  each test builds a temp tree and runs the script via `subprocess` with `--root` and `--allowlist`:

```python
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

    def test_r2_repo_relative_but_not_raw_url(self):
        skill(self.root, "p", "a", "node plugins/p/scripts/x.mjs\n")
        rc, out = run(self.root); self.assertEqual(rc, 1); self.assertIn("R2", out)

    def test_r2_raw_url_ok(self):
        skill(self.root, "p", "a", "https://raw.githubusercontent.com/o/r/main/plugins/p/x.md\n")
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
```

- [ ] **Step 2: Run to verify it fails** — `python3 -m unittest tests/test_check_skill_portability.py -v`
  → errors (script missing).
- [ ] **Step 3: Implement** `scripts/check-skill-portability.py` (executable, stdlib only, module
  docstring stating the four rules and *why*: the CLI copies one folder; nothing outside travels).
  Exit-code semantics and output lines exactly as in **Interfaces**. Print a final summary
  `skill portability: N skill(s) scanned, V violation(s), K known, S stale`.
- [ ] **Step 4: Run tests** → all pass.
- [ ] **Step 5: Seed the allowlist** — run against the repo, then write one line per violating
  skill with its reason. Expected set (verify, don't assume): `site-security`, `site-recon`,
  `site-intel`, `site-fleet`, `evaluate`, `generate`, `site-naming`, `paidagogos-micro`,
  `paidagogos-path`, `site-redesign`. Header comment: "Ratchet: remove a line when the skill is
  fixed; the checker fails on stale lines. `paidagogos-path` is expected to stay (needs the
  plugin's node_modules + visual-kit)." Re-run → exit 0, all `KNOWN`.
- [ ] **Step 6: CI** — in `validate.yml`, after the "Skills CLI discovery" step:

```yaml
      - name: Skill portability (no plugin-root dependencies; ratcheting allowlist)
        run: |
          python3 -m unittest tests/test_check_skill_portability.py
          python3 scripts/check-skill-portability.py
```

- [ ] **Step 7: Report** files changed + checker output. (Controller commits:
  `feat: skill portability checker with ratcheting allowlist`.)

---

### Task 2: namesmith + paidagogos-micro (pure path rewrites; micro text fallback)

**Files:** Modify `plugins/namesmith/skills/site-naming/SKILL.md`,
`plugins/paidagogos/skills/paidagogos-micro/SKILL.md`.

- [ ] **Step 1:** `python3 scripts/check-skill-portability.py --allowlist /dev/null 2>&1 | grep -E 'site-naming|paidagogos-micro'` — record the violations (expected: R1 only).
- [ ] **Step 2:** Add the Global Constraints path-convention line under each H1. Replace every
  `${CLAUDE_PLUGIN_ROOT}/skills/<this-skill>/` prefix with nothing (→ `references/…`, `scripts/…`).
  For bash snippets, write the script as `scripts/check-domains.sh` and keep the convention line
  responsible for resolution — do not invent an env var.
- [ ] **Step 3 (micro fallback):** in paidagogos-micro, where visual-kit fails to start or is not on
  PATH, replace "Halt … Do not present content in chat" with: present the lesson as Markdown in chat
  following `references/lesson-schema.md` section order, and tell the user visual rendering needs the
  `visual-kit` binary (Claude Code plugin or repo clone). Keep the halt only for genuine write errors
  when the server *is* running. Mirror paidagogos-path's existing fallback wording.
- [ ] **Step 4:** checker shows zero violations for both skills
  (`… --allowlist /dev/null | grep -E 'site-naming|paidagogos-micro'` → no `VIOLATION` lines).
- [ ] **Step 5: Report.** Controller removes both allowlist lines, runs checker (exit 0), commits
  `fix(namesmith,paidagogos): skill-relative paths; micro falls back to text without visual-kit`.

---

### Task 3: aegis — move `scripts/` into `site-security`

**Files:**
- Move (controller pre-runs): `git mv plugins/aegis/scripts plugins/aegis/skills/site-security/scripts`
- Modify: `plugins/aegis/skills/site-security/SKILL.md`, `plugins/aegis/commands/aegis-scan.md`,
  `plugins/aegis/README.md`

- [ ] **Step 1:** `cd plugins/aegis/skills/site-security/scripts && python3 -m pytest -q` → passes
  (imports are sibling-relative via `Path(__file__).parent`; confirm). Grep the moved scripts for
  any `parent.parent`/`..` path to plugin root and fix if found.
- [ ] **Step 2:** SKILL.md: convention line; `${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py` →
  `scripts/coverage.py`.
- [ ] **Step 3:** `commands/aegis-scan.md`: `${CLAUDE_PLUGIN_ROOT}/scripts/coverage.py` →
  `${CLAUDE_PLUGIN_ROOT}/skills/site-security/scripts/coverage.py` (both lines). README path refs updated.
- [ ] **Step 4:** `python3 plugins/aegis/skills/site-security/scripts/coverage.py --help` exits 0;
  `bash tests/validate-commands.sh` passes; checker clean for `site-security`.
- [ ] **Step 5: Report.** Controller removes allowlist line, commits
  `refactor(aegis): ship coverage scripts inside the site-security skill`.

---

### Task 4: reframe — move `categories/` and `templates/` into `site-redesign`

**Files:**
- Move (controller pre-runs): `git mv plugins/reframe/categories plugins/reframe/skills/site-redesign/categories`;
  `git mv plugins/reframe/templates plugins/reframe/skills/site-redesign/templates`
- Modify: `plugins/reframe/skills/site-redesign/SKILL.md` (incl. the `:258` "Path note"),
  `…/scripts/test_detect_category.py` (non-hermetic test → new categories path via `Path(__file__)`),
  `tests/validate-reframe-helpers.sh` (`CATS=` line), `plugins/reframe/README.md`,
  any other reframe file the grep below finds.

- [ ] **Step 1:** `grep -rn 'categories\|templates' plugins/reframe tests/validate-reframe-helpers.sh | grep -v node_modules` — list every reference.
- [ ] **Step 2:** SKILL.md: convention line; `${CLAUDE_PLUGIN_ROOT}/categories` → `categories`;
  `${CLAUDE_PLUGIN_ROOT}/skills/site-redesign/scripts/…` → `scripts/…`; rewrite the Path note to
  "`categories/`, `templates/`, `references/` and `scripts/` all live in this skill's folder."
- [ ] **Step 3:** Update `test_detect_category.py` and `tests/validate-reframe-helpers.sh`
  (`CATS="plugins/reframe/skills/site-redesign/categories"`).
- [ ] **Step 4:** `(cd plugins/reframe/skills/site-redesign/scripts && python3 -m pytest -q)` and
  `bash tests/validate-reframe-helpers.sh` pass; checker clean for `site-redesign`.
- [ ] **Step 5: Report.** Controller removes allowlist line, commits
  `refactor(reframe): ship category packs and templates inside the site-redesign skill`.

---

### Task 5: idea-forge — move `agents/` into `evaluate`

**Files:**
- Move (controller pre-runs): `git mv plugins/idea-forge/agents plugins/idea-forge/skills/evaluate/agents`
- Modify: `plugins/idea-forge/.claude-plugin/plugin.json` (add `"agents": "./skills/evaluate/agents"`),
  `skills/evaluate/SKILL.md`, `skills/evaluate/evaluator.md`, `skills/evaluate/agents/orchestrator.md`,
  `skills/evaluate/agents/scoring.md`, `skills/generate/SKILL.md`, `skills/generate/generator.md`,
  `plugins/idea-forge/README.md`.

- [ ] **Step 1:** Convention line in both SKILL.md files.
- [ ] **Step 2:** `${CLAUDE_PLUGIN_ROOT}/agents/<x>.md` → `agents/<x>.md`;
  `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/<y>` → `<y>`; `${CLAUDE_PLUGIN_ROOT}/skills/generate/<y>` → `<y>`.
- [ ] **Step 3:** Subagent-dispatch prompts in `evaluator.md` (the "Read the prompt at … and follow its
  instructions exactly" blocks): a dispatched subagent does not know the skill folder, so the
  dispatcher must pass the **absolute** path. Rewrite each to
  `Read the prompt at <absolute path of this skill's folder>/agents/market-research.md …` and add one
  sentence above the first block: "Substitute the absolute path of this skill's folder before
  dispatching — subagents start without it." Same for lens refs inside `agents/orchestrator.md`
  and `agents/scoring.md` (`references/lenses/{BUSINESS_MODEL}.md` relative to the skill folder,
  i.e. `../references/lenses/…` is **wrong** — keep skill-root-relative and state it).
- [ ] **Step 4:** `bash scripts/validate-marketplace.sh` passes (plugin.json still valid); checker
  clean for `evaluate` and `generate`; `grep -rn CLAUDE_PLUGIN_ROOT plugins/idea-forge/skills` empty.
- [ ] **Step 5: Report.** Controller removes both allowlist lines, commits
  `refactor(idea-forge): ship pipeline agent prompts inside the evaluate skill`.

---

### Task 6: beacon — move `technologies/`, `templates/`, `scripts/core/` into `site-recon`

**Files:**
- Move (controller pre-runs):
  `git mv plugins/beacon/technologies plugins/beacon/skills/site-recon/technologies`;
  `git mv plugins/beacon/templates plugins/beacon/skills/site-recon/templates`;
  `git mv plugins/beacon/scripts/core/har-reconstruct.py plugins/beacon/skills/site-recon/scripts/har-reconstruct.py`
  (`plugins/beacon/scripts/checksums.sha256` stays — remote-download artifact).
- Modify: `skills/site-recon/SKILL.md` + `references/{browser-recon,output-synthesis,session-brief-format,tool-availability}.md`,
  `skills/site-recon/scripts/scaffold.sh` (`TPL="$DIR/../templates/okf"`),
  `skills/site-intel/SKILL.md`, `skills/site-intel/scripts/render_query.sh` (+ its test),
  `skills/site-fleet/SKILL.md`, `tests/validate-{constants-template,fingerprinting,query-proof,har-reconstruct,smoke-test-template,tech-pack,templates,site-intel}.sh`,
  `plugins/beacon/README.md`, `CONTRIBUTING.md`, `agents/site-analyst.md`, `hooks/*` — whatever
  `grep -rn 'technologies\|templates\|scripts/core\|CLAUDE_PLUGIN_ROOT' plugins/beacon tests | grep -v '\.evals/'` finds.
  Do **not** edit `.evals/` snapshots or `CHANGELOG.md` history.

- [ ] **Step 1:** Run the grep above; list every hit to change.
- [ ] **Step 2 (site-recon):** convention line; `${CLAUDE_PLUGIN_ROOT}/technologies/…` → `technologies/…`;
  `${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/…` → `scripts/…`;
  `${CLAUDE_PLUGIN_ROOT}/scripts/core/har-reconstruct.py` → `scripts/har-reconstruct.py`;
  `templates/…` refs stay as written (now resolve inside the skill).
- [ ] **Step 3 (plugin version):** replace "Read `{PLUGIN_VERSION}` from
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` — never use the `main` branch" with: read
  `version` from `../../.claude-plugin/plugin.json` (present in a Claude Code install and a repo
  clone); if absent (skills-CLI copy) record `unversioned`. Tech packs are bundled in
  `technologies/`, so the remote fetch is only a fallback when the bundled file is missing:
  `https://raw.githubusercontent.com/neotherapper/claude-plugins/main/plugins/beacon/skills/site-recon/technologies/{framework}/{major}.x.md`
  (release tags stop at v0.6.0 — the versioned URL never resolved). Apply in site-recon,
  site-intel, `session-brief-format.md`, `output-synthesis.md`.
- [ ] **Step 4 (scripts):** `scaffold.sh` → `TPL="$DIR/../templates/okf"`. `render_query.sh` default
  template → `$DIR/../../site-recon/templates/query-templates.md` (sibling skill; two levels = the
  skills dir, allowed by R4); update its comments and `test_render_query.sh`.
- [ ] **Step 5 (site-intel, site-fleet):** convention line; technologies/templates refs →
  `../site-recon/technologies/…`, `../site-recon/templates/…`; own scripts → `scripts/…`;
  site-fleet's `fleet.py` → `../site-recon/scripts/fleet.py`. Add under each H1: "Requires the
  `site-recon` skill installed alongside (it holds the tech packs, templates and shared scripts)."
- [ ] **Step 6 (tests):** update every `tests/*.sh` path variable to the new locations.
- [ ] **Step 7: Verify** — all pass except the pre-existing `validate-tech-pack.sh` failure, which
  must show the *same* single failure:
  `for t in tests/validate-*.sh plugins/beacon/hooks/test_*.sh plugins/beacon/skills/*/scripts/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo PASS $t || echo FAIL $t; done`;
  `(cd plugins/beacon/skills/site-recon/scripts && python3 -m pytest -q)`;
  `(cd plugins/beacon/skills/site-intel/scripts && python3 -m pytest -q)`;
  checker clean for `site-recon`, `site-intel`, `site-fleet`.
- [ ] **Step 8: Report.** Controller removes three allowlist lines, commits
  `refactor(beacon): ship tech packs, templates and HAR script inside site-recon`.

---

### Task 7: End-to-end CLI install check (CI)

**Files:** Create `scripts/check-skills-cli-install.sh`; modify `.github/workflows/validate.yml`.

- [ ] **Step 1:** Script (`set -euo pipefail`, `ROOT` like `check-skills-cli.sh`):
  temp project (`mktemp -d`, `git init -q`, trap cleanup) →
  `NO_COLOR=1 npx -y skills@latest add "$ROOT" --skill '*' -a universal --copy -y </dev/null` →
  `S="$tmp/.agents/skills"` → `python3 "$ROOT/scripts/check-skill-portability.py" --root "$S"` →
  smoke tests **from the copies**:
  `python3 "$S/site-security/scripts/coverage.py" --help`;
  `python3 "$S/site-redesign/scripts/detect-category.py" --categories "$S/site-redesign/categories" --corpus <fixture written to $tmp>` (exit 0, JSON with a `category` key — match the keys `tests/validate-reframe-helpers.sh` asserts);
  `(cd "$tmp" && URL=https://example.com OUTPUT_ROOT="$tmp/out" bash "$S/site-recon/scripts/scaffold.sh")` (exit 0, `$tmp/out/INDEX.md` exists);
  `python3 "$S/site-recon/scripts/har-reconstruct.py" --help`;
  `test -f "$S/evaluate/agents/scoring.md"`; `test -f "$S/site-recon/technologies/REGISTRY.md"`.
  Print `PASS`/`FAIL` per check; exit 1 on any failure.
- [ ] **Step 2:** Run locally and under `CI=true` → all PASS.
- [ ] **Step 3:** CI step right after "Skill portability": `run: bash scripts/check-skills-cli-install.sh`
  (node is already set up earlier in the job).
- [ ] **Step 4: Report.** Controller commits `ci: install every skill with the skills CLI and smoke-test the copies`.

---

### Task 8: Docs, versions, PR

**Files:** `README.md` ("What a CLI install carries, per plugin" table + wording),
`AGENTS.md` ("Where your skills are" resolution paragraph), `docs/platform/multi-tool-support.md`
("Portability gap (open)" → resolved, keep paidagogos caveat), plugin `CHANGELOG.md`s where they
exist, patch-bump `version` in plugin.json for aegis, beacon, reframe, idea-forge, namesmith,
paidagogos (marketplace.json has no versions to sync unless `validate-marketplace.sh` says so).

- [ ] **Step 1:** Rewrite the per-plugin table: everything **works** from a CLI copy except
  paidagogos (lesson/path rendering needs `visual-kit`; micro falls back to Markdown; path's index
  build is repo-only) and beacon site-intel/site-fleet (need site-recon alongside). Correct the
  "copies carry only SKILL.md, scripts/, references/" claim → whole folder.
- [ ] **Step 2:** AGENTS.md: replace the two-bullet `${CLAUDE_PLUGIN_ROOT}` resolution rule with
  the path convention + the paidagogos caveat (use `mattpocock-skills:writing-for-agents`).
- [ ] **Step 3:** `bash scripts/validate-marketplace.sh`, `bash scripts/sync-skills.sh --check`
  (after `bash scripts/sync-skills.sh`), checker, `bash scripts/check-skills-cli.sh` all pass.
- [ ] **Step 4: Report.** Controller commits `docs: skills-CLI copies now work standalone; bump patch versions`,
  pushes, opens PR stacked on `feat/install-any-harness`.

## Execution order

Task 1 → Tasks 2–6 in parallel (disjoint files: each owns `plugins/<p>/` + that plugin's
`tests/*.sh`; nobody touches the allowlist, `validate.yml` or root docs) → controller merges
allowlist removals → Task 7 → Task 8 → whole-branch review.
