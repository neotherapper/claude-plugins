import json
import sys
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))
import _http


class FakeResp:
    def __init__(self, body, status=200):
        self._b = body.encode() if isinstance(body, str) else body
        self.status = status
    def read(self): return self._b
    def __enter__(self): return self
    def __exit__(self, *a): return False


def test_get_json_ok(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(_http.request, "urlopen", lambda *a, **k: FakeResp('{"x": 1}'))
    assert _http.get_json("https://e.com/a", cache_ttl=0) == {"x": 1}


def test_get_json_http_error_is_safe(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    def boom(*a, **k): raise _http.error.URLError("down")
    monkeypatch.setattr(_http.request, "urlopen", boom)
    r = _http.get_json("https://e.com/a", cache_ttl=0)
    assert "error" in r


def test_get_json_bad_json_is_safe(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(_http.request, "urlopen", lambda *a, **k: FakeResp("not json"))
    assert "error" in _http.get_json("https://e.com/a", cache_ttl=0)


def test_cache_hit_avoids_second_call(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    calls = {"n": 0}
    def once(*a, **k):
        calls["n"] += 1
        return FakeResp('{"x": 1}')
    monkeypatch.setattr(_http.request, "urlopen", once)
    _http.get_json("https://e.com/a", cache_ttl=3600)
    _http.get_json("https://e.com/a", cache_ttl=3600)
    assert calls["n"] == 1  # second served from cache


def test_post_json_non_serializable_payload_is_safe(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    r = _http.post_json("https://e.com/a", {"x": {1, 2, 3}})  # set is not JSON-serializable
    assert "error" in r


def test_malformed_url_is_safe(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    assert "error" in _http.get_json("not-a-url", cache_ttl=0)
    assert "error" in _http.post_json("", {"x": 1})


def test_scalar_json_response_does_not_crash(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(_http.request, "urlopen", lambda *a, **k: FakeResp("null"))
    assert _http.get_json("https://e.com/a", cache_ttl=0) is None  # no crash


def test_post_json_ok(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(_http.request, "urlopen", lambda *a, **k: FakeResp('{"ok": true}'))
    assert _http.post_json("https://e.com/a", {"q": 1}) == {"ok": True}


def test_cache_ttl_0_does_not_write(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(_http.request, "urlopen", lambda *a, **k: FakeResp('{"x": 1}'))
    _http.get_json("https://e.com/a", cache_ttl=0)
    assert not (tmp_path / ".aegis-cache").exists()
