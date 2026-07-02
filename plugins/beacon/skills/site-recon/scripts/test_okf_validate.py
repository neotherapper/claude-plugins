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


def test_bad_utf8_file_produces_error_not_exception():
    with tempfile.TemporaryDirectory() as t:
        p = pathlib.Path(t) / "bad.md"
        p.write_bytes(b"---\ntype: api-surface\ntitle: X\n---\n\xff\xfe bad bytes\n")
        errs = V.validate_node(p)
        assert errs != []


def test_list_valued_enum_field_produces_error_not_exception():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "s.md", """\
            ---
            type: api-surface
            title: X
            access_mode: [open-api]
            auth: none
            verification: live-verified
            status: complete
            ---
            """)
        errs = V.validate_node(p)
        assert any("invalid access_mode" in e for e in errs)


def test_regex_fallback_parser_passes_and_fails_correctly():
    orig = V._YAML
    V._YAML = False
    try:
        with tempfile.TemporaryDirectory() as t:
            good = _write(t, "good.md", """\
                ---
                type: api-surface
                title: X
                access_mode: open-api
                auth: none
                verification: live-verified
                status: complete
                ---
                body
                """)
            assert V.validate_node(good) == []

            bad = _write(t, "bad.md", """\
                ---
                type: api-surface
                title: X
                access_mode: telepathy
                auth: none
                verification: live-verified
                status: complete
                ---
                """)
            assert any("access_mode" in e for e in V.validate_node(bad))
    finally:
        V._YAML = orig


def test_dangling_link_fails():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: complete\n---\nsee [x](missing.md)\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("does not resolve" in e for errs in res.values() for e in errs)

def test_bundle_requires_index_entrypoint():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "tech-stack.md", "---\ntype: tech-stack\ntitle: X\nstatus: complete\n---\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("no INDEX.md entrypoint" in e for errs in res.values() for e in errs)

def test_complete_status_with_unfilled_token_fails():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: complete\n---\nvalue {{FRAMEWORK}}\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert any("unfilled template token" in e for errs in res.values() for e in errs)

def test_draft_stub_with_token_passes():
    with tempfile.TemporaryDirectory() as t:
        _write(t, "INDEX.md", "---\ntype: site-index\ntitle: X\nstatus: draft\n---\nvalue {{FRAMEWORK}}\n")
        res = V.validate_bundle(pathlib.Path(t))
        assert res == {}

def test_empty_bundle_fails_closed():
    with tempfile.TemporaryDirectory() as t:
        res = V.validate_bundle(pathlib.Path(t))
        assert res != {}


def test_is_complete_unquoted_status_true():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "INDEX.md", "---\ntype: site-index\nstatus: complete\n---\nbody\n")
        assert V.is_complete(p) is True


def test_is_complete_quoted_status_true():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "INDEX.md", '---\ntype: site-index\nstatus: "complete"\n---\nbody\n')
        assert V.is_complete(p) is True


def test_is_complete_draft_status_false():
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "INDEX.md", "---\ntype: site-index\nstatus: draft\n---\nbody\n")
        assert V.is_complete(p) is False


def test_is_complete_ignores_body_line_status():
    # frontmatter says draft; a body line that merely reads "status: complete"
    # must not be picked up (parser is frontmatter-anchored, not whole-file grep)
    with tempfile.TemporaryDirectory() as t:
        p = _write(t, "INDEX.md", "---\ntype: site-index\nstatus: draft\n---\nstatus: complete\n")
        assert V.is_complete(p) is False
