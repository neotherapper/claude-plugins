## Query Templates

> Consumed by `plugins/beacon/skills/site-intel/scripts/render_query.sh`. Snippets are
> chosen by the renderer's `auth:` field, not by user phrasing. Snippet names are stable:
> do not rename without updating the renderer and `tests/validate-tech-pack.sh`.

### First record
```bash
# Public surface — fetch the first list-style endpoint and print a few identifying fields.
# {SURFACE_BASE_URL} and {PATH} are substituted by the renderer; PAGE_PARAM/HARD_CAP are left in place
# so per-framework overrides can adjust them.
curl -fsS --max-time 15 "{SURFACE_BASE_URL}{PATH}?per_page=3" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug, title}' || python3 -m json.tool) \
  | head -n 60
```

### Pagination
```bash
# Public surface — paginate explicitly to demonstrate the framework's pagination convention.
curl -fsS --max-time 15 "{SURFACE_BASE_URL}{PATH}?per_page=3&page=1" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug}' || python3 -m json.tool) \
  | head -n 60
```

### Authed first record
```bash
: "${TOKEN:?set TOKEN to the framework-specific credential (API key, OAuth bearer, etc.)}"
curl -fsS --max-time 15 -H "Authorization: Bearer $TOKEN" "{SURFACE_BASE_URL}{PATH}?per_page=3" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug}' || python3 -m json.tool) \
  | head -n 60
```
