import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

HERE = Path(__file__).parent
FLEET = HERE / "fleet.py"


def run(args, cwd):
    return subprocess.run(
        [sys.executable, str(FLEET), *args],
        cwd=cwd, capture_output=True, text=True,
    )


def read_active(root):
    return json.loads((root / "docs/sites/.fleet/active.json").read_text())


def read_ledger(root):
    path = read_active(root)["ledger"]
    return json.loads((root / path).read_text())


def test_init_creates_ledger_and_active(tmp_path):
    r = run(["init", "https://a.com", "https://b.com"], tmp_path)
    assert r.returncode == 0
    assert r.stdout.startswith("[FLEET:")
    led = read_ledger(tmp_path)
    assert led["state"] == "active"
    assert set(led["sources"]) == {"a-com", "b-com"}
    assert led["sources"]["a-com"]["status"] == "pending"


def test_init_rejects_duplicate_slug(tmp_path):
    r = run(["init", "https://a.com/x", "https://a.com/y"], tmp_path)
    assert r.returncode == 2
    assert "duplicate slug" in r.stderr


def test_init_refuses_second_active_fleet(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    r = run(["init", "https://b.com"], tmp_path)
    assert r.returncode == 2
    assert "already active" in r.stderr


def test_update_mutates_row(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    r = run(["update", "a-com", "--status", "reconning", "--agent-id", "x1"], tmp_path)
    assert r.returncode == 0
    led = read_ledger(tmp_path)
    assert led["sources"]["a-com"]["status"] == "reconning"
    assert led["sources"]["a-com"]["agent_id"] == "x1"


def test_pending_lists_non_terminal_and_rearms(tmp_path):
    run(["init", "https://a.com", "https://b.com"], tmp_path)
    run(["update", "a-com", "--status", "complete", "--verdict", "complete"], tmp_path)
    run(["pause"], tmp_path)  # defined in Task 5; import-time presence is fine
    r = run(["pending"], tmp_path)
    assert r.returncode == 0
    assert r.stdout.split() == ["b-com"]
    assert read_ledger(tmp_path)["state"] == "active"  # re-armed


def test_update_unknown_slug_exits_2_and_preserves_ledger(tmp_path):
    run(["init", "https://a.com"], tmp_path)
    before = read_ledger(tmp_path)
    r = run(["update", "nonexistent-slug", "--status", "complete"], tmp_path)
    assert r.returncode == 2
    assert read_ledger(tmp_path) == before  # ledger unchanged, not corrupted
