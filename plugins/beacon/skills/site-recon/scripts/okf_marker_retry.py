#!/usr/bin/env python3
"""Atomically read-and-decide a beacon recon-active.json marker's `retries`
counter, for okf-gate.sh. An flock (not just separate read/write calls) makes
the read-check-increment sequence atomic, so two hook invocations racing on
the same marker (e.g. overlapping Stop/SubagentStop events) can't both read
the same count and both bump it — a lost update that would let the 2-retry
cap be over- or under-counted.

Prints exactly one line to stdout:
  blocked  -> retries was < 2 and has been incremented; caller should block the stop
  failed   -> retries was already >= 2; caller should release the marker
"""
import fcntl
import json
import sys

path = sys.argv[1]
with open(path, "r+", encoding="utf-8") as f:
    fcntl.flock(f, fcntl.LOCK_EX)
    try:
        f.seek(0)
        data = json.load(f)
        retries = data.get("retries", 0)
        if retries >= 2:
            print("failed")
        else:
            data["retries"] = retries + 1
            f.seek(0)
            f.truncate()
            json.dump(data, f)
            f.flush()
            print("blocked")
    finally:
        fcntl.flock(f, fcntl.LOCK_UN)
