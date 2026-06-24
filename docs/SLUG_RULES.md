# Site slug derivation (canonical)

All site-analysis plugins (beacon, reframe) MUST derive the same slug so their
output lines up under `docs/sites/{slug}/`. reframe follows this rule today;
beacon aligns in PR-C (v0.7.0). Rule:

1. Lowercase
2. Strip scheme (`https?://`)
3. Strip leading `www.`
4. Strip path (everything from the first `/`)
5. Strip trailing `:port`
6. Replace `.` with `-`

```bash
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
```

| Input | Slug |
|-------|------|
| `https://www.example.com/` | `example-com` |
| `https://api.example.com/v2` | `api-example-com` |
| `http://example.com:8080` | `example-com` |
| `https://Example.COM` | `example-com` |

IDN/Unicode: v1 supports ASCII/punycode input only; non-ASCII is slugified
as-is and should be flagged. Full punycode normalization is a later enhancement.
