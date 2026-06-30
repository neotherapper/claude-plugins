"""Tests for check-output-complete.sh — the reframe output substance gate."""
import subprocess
from pathlib import Path

SCRIPT = Path(__file__).parent / "check-output-complete.sh"
SIX_FILES = ["INDEX.md", "brief.md", "run-sheet.md",
             "content-inventory.md", "ia-map.md", "current-critique.md"]

GOOD_RUNLOG = (
    "## Run log\n"
    "**Phase markers:** [P1✓] [P2✓] [P3✓] [P4✓] [P5✓] "
    "[P6✓] [P7✓] [P8✓] [P9✓]\n"
    "**Signals fired:** [PACK-LOADED:local-service] [TECH-STACK-ABSENT]\n"
)

def _make_output(tmp_path: Path, *, index_extra: str = GOOD_RUNLOG) -> Path:
    d = tmp_path / "redesign"
    d.mkdir()
    for f in SIX_FILES:
        body = "# heading\n\nreal content here\n"
        if f == "INDEX.md":
            body += "\n" + index_extra
        (d / f).write_text(body, encoding="utf-8")
    return d

def _run(d: Path):
    return subprocess.run(["bash", str(SCRIPT), str(d)],
                          capture_output=True, text=True)

def test_complete_run_passes(tmp_path):
    r = _run(_make_output(tmp_path))
    assert r.returncode == 0, r.stdout + r.stderr

def test_missing_phase_marker_fails(tmp_path):
    bad = GOOD_RUNLOG.replace(" [P5✓]", "")  # drop P5
    r = _run(_make_output(tmp_path, index_extra=bad))
    assert r.returncode == 1
    assert "P5" in r.stdout or "phase marker" in r.stdout.lower()

def test_missing_pack_loaded_fails(tmp_path):
    bad = "## Run log\n**Phase markers:** " + " ".join(
        f"[P{i}✓]" for i in range(1, 10)) + "\n**Signals fired:** none\n"
    r = _run(_make_output(tmp_path, index_extra=bad))
    assert r.returncode == 1
    assert "PACK-LOADED" in r.stdout

def test_greenfield_index_only_passes(tmp_path):
    # Greenfield halts after INDEX.md only; gate must not demand the other five.
    d = tmp_path / "redesign"
    d.mkdir()
    (d / "INDEX.md").write_text(
        "# x\n\n## Run log\n**Phase markers:** [GREENFIELD-MODE]\n"
        "**Signals fired:** [GREENFIELD-MODE]\n", encoding="utf-8")
    r = _run(d)
    assert r.returncode == 0, r.stdout + r.stderr

def test_unresolved_token_still_fails(tmp_path):
    d = _make_output(tmp_path)
    (d / "brief.md").write_text("# x\n\n{{UNRESOLVED}}\n", encoding="utf-8")
    r = _run(d)
    assert r.returncode == 1
    assert "{{UNRESOLVED}}" in r.stdout

def test_greenfield_token_in_prose_still_enforces(tmp_path):
    # A complete output (all 6 files) where P5 is absent from the phase markers
    # line, but [GREENFIELD-MODE] appears in prose on the Signals line.
    # The gate must still catch the missing P5 — NOT flip to greenfield mode.
    prose_runlog = (
        "## Run log\n"
        "**Phase markers:** [P1✓] [P2✓] [P3✓] [P4✓] "
        "[P6✓] [P7✓] [P8✓] [P9✓]\n"
        "**Signals fired:** [PACK-LOADED:local-service] "
        "(note: [GREENFIELD-MODE] did not fire)\n"
    )
    r = _run(_make_output(tmp_path, index_extra=prose_runlog))
    assert r.returncode == 1, r.stdout + r.stderr
    assert "P5" in r.stdout
