# Site slug derivation (canonical)

All site-analysis plugins (beacon, reframe) MUST derive the same slug so their
output lines up under `docs/sites/{slug}/`. Rule:

1. Strip scheme (`https?://`)
2. Strip leading `www.`
3. Strip path (everything from the first `/`)
4. Strip trailing `:port`
5. Lowercase
6. Replace `.` with `-`

```bash
SLUG=$(printf '%s' "$URL" | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//' | tr 'A-Z' 'a-z' | sed -E 's/\./-/g')
```

| Input | Slug |
|-------|------|
| `https://www.example.com/` | `example-com` |
| `https://api.example.com/v2` | `api-example-com` |
| `http://example.com:8080` | `example-com` |
| `https://Example.COM` | `example-com` |

IDN/Unicode: v1 supports ASCII/punycode input only; non-ASCII is slugified
as-is and should be flagged. Full punycode normalization is a later enhancement.
