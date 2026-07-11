#!/usr/bin/env python3
"""Beacon fleet ledger + completeness sweep (Subsystem B1).

Sequential-fleet state lives under docs/sites/.fleet/, resolved relative to the
repo root (the cwd convention okf-gate.sh and scaffold.sh already use). The main
session is the single writer; `update` takes an flock for defense in depth.
"""
import argparse
import fcntl
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

FLEET_DIR = os.path.join("docs", "sites", ".fleet")
ACTIVE = os.path.join(FLEET_DIR, "active.json")
TERMINAL = {"complete", "blocked"}
_SCRIPTS = os.path.dirname(os.path.abspath(__file__))
VALIDATE = os.path.join(_SCRIPTS, "okf_validate.py")
SLUGIFY = os.path.join(_SCRIPTS, "slugify.py")


def slug_of(url):
    return subprocess.run(
        [sys.executable, SLUGIFY, url],
        capture_output=True, text=True, check=True,
    ).stdout.strip()


def _now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _stamp():
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + str(os.getpid())


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def ledger_path():
    if not os.path.isfile(ACTIVE):
        return None
    return load(ACTIVE).get("ledger")


def index_path(slug):
    return os.path.join("docs", "sites", slug, "research", "INDEX.md")


def is_complete(slug):
    idx = index_path(slug)
    if not os.path.isfile(idx):
        return False
    return subprocess.run(
        [sys.executable, VALIDATE, "--is-complete", idx],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0


def _render_md(led):
    out = [f"# Fleet ledger — created {led['created']} — state: {led['state']}", "",
           "| slug | status | verdict | url |", "|------|--------|---------|-----|"]
    for slug, s in led["sources"].items():
        out.append(f"| {slug} | {s['status']} | {s['verdict'] or ''} | {s['url']} |")
    return "\n".join(out) + "\n"


def _write(path, led):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(led, f, indent=2)
    with open(path[:-5] + ".md", "w", encoding="utf-8") as f:
        f.write(_render_md(led))


def _mutate(fn):
    """Read-modify-write the active ledger under flock; regenerate the .md."""
    path = ledger_path()
    if not path or not os.path.isfile(path):
        sys.stderr.write("[FLEET-ERROR] no active fleet (missing active.json)\n")
        return None
    with open(path, "r+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            f.seek(0)
            led = json.load(f)
            fn(led)
            data = json.dumps(led, indent=2)   # serialize BEFORE truncating
            f.seek(0)
            f.truncate()
            f.write(data)
            f.flush()
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)
    with open(path[:-5] + ".md", "w", encoding="utf-8") as f:
        f.write(_render_md(led))
    return led


def cmd_init(a):
    resolved = {}
    for url in a.urls:
        s = slug_of(url)
        if s in resolved:
            sys.stderr.write(
                f"[FLEET-ERROR] duplicate slug '{s}' from URLs "
                f"'{resolved[s]}' and '{url}' — one bundle per source; remove one.\n")
            return 2
        resolved[s] = url
    existing = ledger_path()
    if existing and os.path.isfile(existing):
        led = load(existing)
        if any(v["status"] not in TERMINAL for v in led["sources"].values()):
            sys.stderr.write(
                f"[FLEET-ERROR] an unresolved fleet is already active ({existing}). "
                f"Run 'fleet.py pending' to resume it, or 'fleet.py close' to abandon "
                f"it, before starting a new one.\n")
            return 2
    os.makedirs(FLEET_DIR, exist_ok=True)
    led = {"created": _now(), "state": "active",
           "sources": {s: {"url": u, "agent_id": None, "status": "pending",
                           "verdict": None, "retries": 0}
                       for s, u in resolved.items()}}
    path = os.path.join(FLEET_DIR, f"fleet-{_stamp()}.json")
    _write(path, led)
    with open(ACTIVE, "w", encoding="utf-8") as f:
        json.dump({"ledger": path}, f)
    print(f"[FLEET:{path}]")
    return 0


def cmd_update(a):
    def fn(led):
        if a.slug not in led["sources"]:
            raise KeyError(a.slug)
        row = led["sources"][a.slug]
        row["status"] = a.status
        if a.verdict is not None:
            row["verdict"] = a.verdict
        if a.agent_id is not None:
            row["agent_id"] = a.agent_id
    try:
        return 0 if _mutate(fn) is not None else 1
    except KeyError as e:
        sys.stderr.write(f"[FLEET-ERROR] unknown slug {e}\n")
        return 2


def cmd_pending(a):
    # deterministic re-arm: resuming un-pauses so the gate can never stay disarmed
    led = _mutate(lambda l: l.__setitem__("state", "active"))
    if led is None:
        return 1
    for slug, s in led["sources"].items():
        if s["status"] not in TERMINAL:
            print(slug)
    return 0


def cmd_sweep(a):
    path = ledger_path()
    if not path or not os.path.isfile(path):
        sys.stderr.write("[FLEET-ERROR] no active fleet\n")
        return 1
    led = load(path)
    incomplete = []
    for slug, s in led["sources"].items():
        if is_complete(slug):
            continue
        reason = (s["verdict"] or s["status"] or "unknown")
        # fail toward flagging: a missing/invalid INDEX counts as incomplete
        incomplete.append((slug, reason))
    if not incomplete:
        print("[FLEET-COMPLETE]")
    else:
        for slug, reason in incomplete:
            print(f"[FLEET-INCOMPLETE:{slug}:{reason}]")
    return 0


def cmd_pause(a):
    return 0 if _mutate(lambda l: l.__setitem__("state", "paused")) is not None else 1


def cmd_resume(a):
    return 0 if _mutate(lambda l: l.__setitem__("state", "active")) is not None else 1


def cmd_waive(a):
    def fn(led):
        row = led["sources"][a.slug]
        row["status"] = "blocked"
        row["verdict"] = f"blocked:{a.reason or 'waived'}"
    return 0 if _mutate(fn) is not None else 1


def cmd_close(a):
    if os.path.isfile(ACTIVE):
        os.remove(ACTIVE)
    print("[FLEET-CLOSED]")
    return 0


def build_parser():
    p = argparse.ArgumentParser(prog="fleet.py")
    sub = p.add_subparsers(dest="cmd", required=True)
    pi = sub.add_parser("init"); pi.add_argument("urls", nargs="+"); pi.set_defaults(fn=cmd_init)
    pu = sub.add_parser("update")
    pu.add_argument("slug")
    pu.add_argument("--status", required=True)
    pu.add_argument("--verdict")
    pu.add_argument("--agent-id", dest="agent_id")
    pu.set_defaults(fn=cmd_update)
    pp = sub.add_parser("pending"); pp.set_defaults(fn=cmd_pending)
    ps = sub.add_parser("sweep"); ps.set_defaults(fn=cmd_sweep)
    sub.add_parser("pause").set_defaults(fn=cmd_pause)
    sub.add_parser("resume").set_defaults(fn=cmd_resume)
    pw = sub.add_parser("waive"); pw.add_argument("slug"); pw.add_argument("--reason")
    pw.set_defaults(fn=cmd_waive)
    sub.add_parser("close").set_defaults(fn=cmd_close)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
