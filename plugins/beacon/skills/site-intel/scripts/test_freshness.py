import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
SCRIPT = HERE / "freshness.py"


def write_index(tmp_path, ts_line):
    # ts_line is a full "timestamp: ...\n" line, or "" to omit it
    p = tmp_path / "INDEX.md"
    p.write_text("---\ntype: site-index\n" + ts_line + "status: complete\n---\n# x\n")
    return p


def run(index, now=None):
    args = [sys.executable, str(SCRIPT), str(index)]
    if now:
        args += ["--now", now]
    return subprocess.run(args, capture_output=True, text=True)


def test_fresh(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-07-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-06T00:00:00Z")  # 5 days
    assert r.returncode == 0
    assert r.stdout.strip() == "[RESEARCH-FRESH:5d]"


def test_stale(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")  # 45 days
    assert r.stdout.strip() == "[RESEARCH-STALE:45d]"


def test_boundary_30_is_fresh(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-01T00:00:00Z")  # exactly 30 days
    assert r.stdout.strip() == "[RESEARCH-FRESH:30d]"


def test_boundary_31_is_stale(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2026-06-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-02T00:00:00Z")  # 31 days
    assert r.stdout.strip() == "[RESEARCH-STALE:31d]"


def test_missing_timestamp(tmp_path):
    idx = write_index(tmp_path, "")  # no timestamp line
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_garbage_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "not-a-date"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_missing_file(tmp_path):
    r = run(tmp_path / "nope.md", now="2026-07-16T00:00:00Z")
    assert r.returncode == 0
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_future_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: "2027-01-01T00:00:00Z"\n')
    r = run(idx, now="2026-07-16T00:00:00Z")
    assert r.stdout.strip() == "[RESEARCH-DATE-UNKNOWN]"


def test_date_only_timestamp(tmp_path):
    idx = write_index(tmp_path, 'timestamp: 2026-06-01\n')  # date-only, unquoted
    r = run(idx, now="2026-07-16T00:00:00Z")  # 45 days
    assert r.stdout.strip() == "[RESEARCH-STALE:45d]"
