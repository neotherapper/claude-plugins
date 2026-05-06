import json, subprocess, pathlib, sys

def test_run_all_outputs_json():
    script = pathlib.Path(__file__).parent / 'osint.py'
    # invoke python orchestrator
    result = subprocess.run([sys.executable, str(script), 'run_all', '--target', 'example.com'], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    data = json.loads(result.stdout)
    # ensure we have at least one script result
    assert isinstance(data, dict) and len(data) > 0
    for name, info in data.items():
        assert isinstance(info, dict)
        assert 'stdout' in info and 'stderr' in info and 'exit_code' in info
