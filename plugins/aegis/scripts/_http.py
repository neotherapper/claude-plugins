#!/usr/bin/env python3
"""Shared stdlib HTTP for aegis clients: fail-safe GET/POST JSON with an on-disk
TTL cache and a courtesy rate-limit. Never raises — every failure returns
{"error": <reason>} so the orchestrator can record 'coverage incomplete' rather
than crash or report a false 'no vulnerabilities'."""
import hashlib
import json
import os
import time
from urllib import request, error

CACHE_DIR = os.path.join(".aegis-cache")
_UA = "aegis-vuln-coverage/0.1 (+https://github.com/neotherapper/claude-plugins)"
_last_call = [0.0]
_MIN_INTERVAL = 0.25  # ~4 req/s courtesy cap


def _cache_path(key):
    h = hashlib.sha256(key.encode()).hexdigest()[:32]
    return os.path.join(CACHE_DIR, h + ".json")


def _cache_get(key, ttl):
    if ttl <= 0:
        return None
    try:
        p = _cache_path(key)
        if os.path.isfile(p) and (time.time() - os.path.getmtime(p)) < ttl:
            with open(p, encoding="utf-8") as f:
                return json.load(f)
    except (OSError, ValueError):
        return None
    return None


def _cache_put(key, value):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(_cache_path(key), "w", encoding="utf-8") as f:
            json.dump(value, f)
    except OSError:
        pass


def _throttle():
    dt = time.time() - _last_call[0]
    if dt < _MIN_INTERVAL:
        time.sleep(_MIN_INTERVAL - dt)
    _last_call[0] = time.time()


def _do(url, timeout, data=None, headers=None, method=None):
    try:
        _throttle()
        req = request.Request(url, data=data, headers=headers or {}, method=method)
        with request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", "replace")
        return json.loads(body)
    except (error.URLError, error.HTTPError) as e:
        return {"error": f"request failed: {e}"}
    except ValueError as e:
        return {"error": f"bad json or url: {e}"}
    except Exception as e:  # never raise from an advisory client
        return {"error": f"unexpected: {e}"}


def get_json(url, headers=None, timeout=20, cache_ttl=86400):
    cached = _cache_get(url, cache_ttl)
    if cached is not None:
        return cached
    h = {"Accept": "application/json", "User-Agent": _UA, **(headers or {})}
    result = _do(url, timeout, headers=h, method="GET")
    if cache_ttl > 0 and not (isinstance(result, dict) and "error" in result):
        _cache_put(url, result)
    return result


def post_json(url, payload, headers=None, timeout=20):
    h = {"Accept": "application/json", "Content-Type": "application/json",
         "User-Agent": _UA, **(headers or {})}
    try:
        data = json.dumps(payload).encode()
    except (TypeError, ValueError) as e:
        return {"error": f"bad payload: {e}"}
    return _do(url, timeout, data=data, headers=h, method="POST")
