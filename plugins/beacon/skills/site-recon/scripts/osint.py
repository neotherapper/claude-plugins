#!/usr/bin/env python3
"""OSINT orchestrator for beacon site‑recon.

This script provides a thin Python wrapper around the existing Bash
helpers in this directory.  It uses **fire** (Google Python Fire) to
expose a simple CLI:

    python osint.py run_all --target example.com

`run_all` executes every ``*.sh`` helper (via ``bash``, so the executable
bit is irrelevant) and returns a JSON document with the collected output
(stdout) for each step.  Pass ``--exclude a,b`` to skip helpers by name.

The orchestrator is deliberately lightweight – each Bash script already
contains all the heavy‑lifting (curl, amass, nmap, etc.).  By keeping them
as Bash we retain zero‑dependency execution on typical CI runners while
still offering a single entry‑point and testability via Python.

If a helper fails (non‑zero exit code) its ``stderr`` is captured and the
step is marked as ``error`` in the final payload.
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, List

import fire

SCRIPT_DIR = Path(__file__).parent
SWEEP_TIMEOUT = 60  # seconds per helper — testssl.sh/sublist3r have no wall-clock cap of their own

def _is_helper(path: Path) -> bool:
    """A bundled OSINT helper: a ``*.sh`` file that is not the test harness.

    Selection deliberately does NOT depend on the executable bit — helpers are
    invoked via ``bash`` below, so a checkout that lost ``+x`` (zip install,
    cross-platform) still runs them, and ``run_all`` stays in step with the
    SKILL's ``for s in scripts/*.sh`` fallback loop. ``run_osint_tests.sh`` (the
    only ``*_tests.sh``) is excluded; ``test_osint.py`` is excluded by suffix.
    """
    return path.is_file() and path.suffix == ".sh" and not path.name.endswith("_tests.sh")

def _run_script(script: Path, target: str) -> Dict[str, str]:
    """Execute a Bash helper. Returns stdout/stderr/exit_code for diagnostics."""
    try:
        # Helpers read the target from the TARGET env var (not $1); invoke via
        # `bash` so the exec bit is irrelevant. `timeout` caps unbounded helpers
        # (tls_fingerprint.sh, sublist3r.sh) so one hang can't stall the sweep.
        result = subprocess.run(
            ["bash", str(script)],
            capture_output=True,
            text=True,
            check=False,
            env={**os.environ, "TARGET": target},
            timeout=SWEEP_TIMEOUT,
        )
        return {
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "exit_code": result.returncode,
        }
    except subprocess.TimeoutExpired:
        return {"stdout": "", "stderr": f"timed out after {SWEEP_TIMEOUT}s", "exit_code": -1}
    except Exception as exc:  # pragma: no cover – defensive
        return {"stdout": "", "stderr": str(exc), "exit_code": -1}

def run_all(target: str, exclude: str = "") -> str:
    """Run every bundled ``*.sh`` helper; return JSON mapping helper name → output.

    ``exclude`` is a comma-separated list of helper names to skip, e.g.
    ``--exclude cloud-enum,container-scan`` to omit the active-infrastructure
    probes when the engagement does not authorise them.
    """
    if not target:
        raise ValueError("--target must be provided")

    skip = {name.strip() for name in str(exclude).split(",") if name.strip()}
    results: Dict[str, Dict[str, str]] = {}
    for script in sorted(SCRIPT_DIR.iterdir()):
        if script.name.startswith("__") or not _is_helper(script):
            continue
        if script.stem in skip:
            continue
        results[script.stem] = _run_script(script, target)
    return json.dumps(results, indent=2)

def list_scripts() -> List[str]:
    """Return the bundled Bash helper names (without extension)."""
    return [p.stem for p in sorted(SCRIPT_DIR.iterdir()) if _is_helper(p)]

if __name__ == "__main__":
    fire.Fire({
        "run_all": run_all,
        "list": list_scripts,
    })
