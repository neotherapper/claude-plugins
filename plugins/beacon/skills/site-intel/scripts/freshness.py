#!/usr/bin/env python3
"""Deterministic research-freshness signal for beacon site-intel.

Reads INDEX.md's OKF `timestamp:` frontmatter (ISO 8601, set at scaffold time),
computes whole days since then against the system clock, and prints exactly one
advisory signal line — ALWAYS exit 0, never a traceback:

  [RESEARCH-STALE:{N}d]     when N > 30
  [RESEARCH-FRESH:{N}d]     when 0 <= N <= 30
  [RESEARCH-DATE-UNKNOWN]   file missing / no frontmatter / bad or future timestamp

site-intel Step 2 runs this and prepends a warning ONLY on the STALE signal.
The date is never something the model should compute in prose — the system
clock here is the source of truth.
"""
import re
import sys
from datetime import datetime, timezone

STALE_AFTER_DAYS = 30

try:
    import yaml  # optional; a regex line-scan is used if absent
    _YAML = True
except ImportError:
    _YAML = False


def _read_timestamp(path):
    """Return the raw `timestamp:` string from the file's frontmatter, or None."""
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except (OSError, UnicodeDecodeError):
        return None
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return None
    block = m.group(1)
    if _YAML:
        try:
            data = yaml.safe_load(block)
            if isinstance(data, dict) and data.get("timestamp") not in (None, ""):
                val = data["timestamp"]
                if val not in (None, ""):
                    return val.isoformat() if hasattr(val, "isoformat") else str(val)
        except yaml.YAMLError:
            pass  # fall through to the line scan
    for line in block.splitlines():
        m2 = re.match(r"\s*timestamp\s*:\s*(.+?)\s*$", line)
        if m2:
            return m2.group(1).strip().strip('"').strip("'") or None
    return None


def _parse_iso(ts):
    """Parse an ISO-8601 (datetime or date-only) string to aware UTC, or None."""
    if not ts:
        return None
    s = str(ts).strip().replace("Z", "+00:00")
    dt = None
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        try:
            dt = datetime.fromisoformat(s[:10])  # date-only fallback
        except ValueError:
            return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def freshness(index_path, now=None):
    """Return the one-line freshness signal for the given INDEX.md path."""
    try:
        if now is None:
            now = datetime.now(timezone.utc)
        elif getattr(now, "tzinfo", None) is None:
            now = now.replace(tzinfo=timezone.utc)  # normalize naive -> aware UTC
        ts = _parse_iso(_read_timestamp(index_path))
        if ts is None:
            return "[RESEARCH-DATE-UNKNOWN]"
        days = (now - ts).days  # timedelta.days floors toward -inf, so future -> negative
        if days < 0:
            return "[RESEARCH-DATE-UNKNOWN]"  # future-dated / clock skew
        if days > STALE_AFTER_DAYS:
            return f"[RESEARCH-STALE:{days}d]"
        return f"[RESEARCH-FRESH:{days}d]"
    except Exception:
        return "[RESEARCH-DATE-UNKNOWN]"  # advisory tool: never raise


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    now = None
    if "--now" in argv:
        i = argv.index("--now")
        if i + 1 >= len(argv):
            print("[RESEARCH-DATE-UNKNOWN]")  # dangling --now flag: fail safe
            return 0
        now = _parse_iso(argv[i + 1])
        del argv[i:i + 2]
        if now is None:
            print("[RESEARCH-DATE-UNKNOWN]")  # present but unparseable: fail safe
            return 0
    if not argv:
        # usage error stays fail-safe: advisory tool never errors out
        print("[RESEARCH-DATE-UNKNOWN]")
        return 0
    print(freshness(argv[0], now=now))
    return 0


if __name__ == "__main__":
    sys.exit(main())
