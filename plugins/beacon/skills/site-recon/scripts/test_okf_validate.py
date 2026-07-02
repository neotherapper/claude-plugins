import pathlib, tempfile, textwrap
import okf_validate as V

def _write(tmp, name, text):
    p = pathlib.Path(tmp) / name
    p.write_text(textwrap.dedent(text), encoding="utf-8")
    return p

def test_valid_api_surface_passes():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", """\
            ---
            type: api-surface
            title: NGA MSI
            access_mode: open-api
            auth: none
            verification: live-verified
            status: complete
            ---
            body
            """)
        assert V.validate_node(p) == []

def test_unknown_type_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "---\ntype: bogus\nstatus: draft\n---\n")
        assert any("unknown type" in e for e in V.validate_node(p))

def test_bad_enum_value_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", """\
            ---
            type: api-surface
            title: X
            access_mode: telepathy
            auth: none
            verification: live-verified
            status: complete
            ---
            """)
        assert any("access_mode" in e for e in V.validate_node(p))

def test_missing_frontmatter_fails_closed():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "no frontmatter here\n")
        assert V.validate_node(p) != []

def test_api_surface_missing_required_field_fails():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", "---\ntype: api-surface\ntitle: X\nstatus: draft\n---\n")
        assert any("access_mode" in e for e in V.validate_node(p))
