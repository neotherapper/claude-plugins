#!/usr/bin/env python3
"""OSINT orchestrator for beacon site‑recon.

This script provides a thin Python wrapper around the existing Bash
helpers in this directory.  It uses **google‑fire** to expose a simple
CLI:

    python osint.py run_all --target example.com

`run_all` executes every ``*.sh`` helper that is executable and returns a
JSON document with the collected output (stdout) for each step.

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

def _is_executable(path: Path) -> bool:
    return os.access(path, os.X_OK) and path.suffix == ".sh"

def _run_script(script: Path, target: str) -> Dict[str, str]:
    """Execute a Bash helper.

    Returns a dict with ``stdout`` and ``stderr``.  ``exit_code`` is also
    included for diagnostics.
    """
    try:
        result = subprocess.run(
            [str(script), target],
            capture_output=True,
            text=True,
            check=False,
        )
        return {
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "exit_code": result.returncode,
        }
    except Exception as exc:  # pragma: no cover – defensive
        return {"stdout": "", "stderr": str(exc), "exit_code": -1}

def run_all(target: str) -> str:
    """Run every executable ``*.sh`` script in this directory.

    The function returns a JSON string mapping the script name (without
    ``.sh``) to its output dictionary.
    """
    if not target:
        raise ValueError("--target must be provided")

    results: Dict[str, Dict[str, str]] = {}
    for script in sorted(SCRIPT_DIR.iterdir()):
        if script.name.startswith("__") or not script.is_file():
            continue
        if _is_executable(script):
            name = script.stem
            results[name] = _run_script(script, target)
    return json.dumps(results, indent=2)

def list_scripts() -> List[str]:
    """Return the list of available Bash helpers (names without extension)."""
    return [p.stem for p in SCRIPT_DIR.iterdir() if _is_executable(p)]

if __name__ == "__main__":
    fire.Fire({
        "run_all": run_all,
        "list": list_scripts,
    })
