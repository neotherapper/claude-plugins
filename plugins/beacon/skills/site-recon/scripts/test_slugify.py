import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))
import slugify as S

# (input url, expected slug) — mirrors scaffold.sh's historical sed rule
CASES = [
    ("https://example.com", "example-com"),
    ("http://example.com/", "example-com"),
    ("https://www.jetpens.com", "jetpens-com"),
    ("https://api.example.com:8080/v1/things", "api-example-com"),
    ("HTTPS://Example.COM/Path", "example-com"),
    ("https://msi.nga.mil/NavWarnings", "msi-nga-mil"),
    ("example.com", "example-com"),
]


@pytest.mark.parametrize("url,expected", CASES)
def test_slugify_func(url, expected):
    assert S.slugify(url) == expected


@pytest.mark.parametrize("url,expected", CASES)
def test_slugify_cli(url, expected):
    out = subprocess.run(
        [sys.executable, str(Path(__file__).parent / "slugify.py"), url],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    assert out == expected


def test_cli_no_args_exits_nonzero():
    r = subprocess.run([sys.executable, str(Path(__file__).parent / "slugify.py")],
                       capture_output=True, text=True)
    assert r.returncode != 0


def test_cli_extra_args_exits_nonzero():
    r = subprocess.run([sys.executable, str(Path(__file__).parent / "slugify.py"), "a", "b"],
                       capture_output=True, text=True)
    assert r.returncode != 0
