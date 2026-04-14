# Script Distribution — Research Reference

> How Beacon downloads, verifies, and caches runtime scripts. The key design decision: scripts are NOT bundled inside the plugin ZIP. They live on GitHub and are fetched on first use, version-pinned to the installed plugin semver.

## Why Not Bundle Scripts in the Plugin?

Scripts change more frequently than the plugin itself. Bundling means users must upgrade the whole plugin for a script patch. Distributing from GitHub means:
- Script fixes ship instantly without a plugin release
- Community can contribute scripts via PR independently
- Users can inspect exactly what will run before execution

## Download Mechanism

### Base URL Pattern

```
https://raw.githubusercontent.com/neotherapper/beacon-plugin/v{VERSION}/scripts/{category}/{filename}
```

Where `{VERSION}` is the installed plugin's semver tag (e.g., `v0.1.0`). This ensures scripts stay in sync with the plugin version that expects them.

**Never use `main` branch** — `main` may be ahead of the installed version and contain breaking changes.

### Script Categories

```
scripts/
├── core/             # Always downloaded; used on every analysis
│   ├── probe-passive.sh      # robots.txt, sitemap, well-known, HTTP headers
│   ├── fingerprint.sh        # Framework + version detection from headers/HTML
│   └── probe-feeds.sh        # RSS/Atom/JSON-LD/GraphQL detection
├── analysis/         # Downloaded when needed
│   ├── grep-endpoints.sh     # JS bundle endpoint extraction
│   ├── check-sourcemaps.sh   # Source map discovery and download
│   └── har-to-openapi.sh     # HAR capture → OpenAPI spec (wraps har-to-openapi npm)
└── osint/            # Downloaded for OSINT phase
    ├── run-gau.sh            # GetAllURLs wrapper
    ├── wayback-cdx.sh        # Wayback Machine CDX API query
    ├── commoncrawl-cdx.sh    # CommonCrawl CDX API query
    └── github-codesearch.sh  # GitHub code search API query
```

### Download Flow

```
1. Check if script exists in .beacon/scripts/{category}/{filename}
2. If yes AND sha256 matches checksums.sha256 → use cached copy
3. If no → download from GitHub raw URL
4. Verify SHA256 against scripts/checksums.sha256 (also fetched from GitHub)
5. If verification fails → abort with error, DO NOT execute unverified script
6. If GitHub unreachable → use inline Claude generation fallback (see below)
```

### Download Command (bash)

```bash
PLUGIN_VERSION="0.1.0"
SCRIPT_CATEGORY="core"
SCRIPT_NAME="probe-passive.sh"
LOCAL_CACHE=".beacon/scripts/${SCRIPT_CATEGORY}/${SCRIPT_NAME}"
REMOTE_URL="https://raw.githubusercontent.com/neotherapper/beacon-plugin/v${PLUGIN_VERSION}/scripts/${SCRIPT_CATEGORY}/${SCRIPT_NAME}"

mkdir -p ".beacon/scripts/${SCRIPT_CATEGORY}"

if [ ! -f "${LOCAL_CACHE}" ]; then
  curl -fsSL "${REMOTE_URL}" -o "${LOCAL_CACHE}"
  chmod +x "${LOCAL_CACHE}"
fi
```

## SHA256 Verification

The verification manifest lives at:
```
https://raw.githubusercontent.com/neotherapper/beacon-plugin/v{VERSION}/scripts/checksums.sha256
```

Format (one entry per script):
```
a1b2c3d4...  scripts/core/probe-passive.sh
e5f6a7b8...  scripts/core/fingerprint.sh
...
```

Verification:
```bash
# Fetch the checksums file
curl -fsSL "https://raw.githubusercontent.com/neotherapper/beacon-plugin/v${VERSION}/scripts/checksums.sha256" \
  -o ".beacon/checksums.sha256"

# Verify a specific script
EXPECTED=$(grep "scripts/core/probe-passive.sh" .beacon/checksums.sha256 | awk '{print $1}')
ACTUAL=$(shasum -a 256 "${LOCAL_CACHE}" | awk '{print $1}')

if [ "${EXPECTED}" != "${ACTUAL}" ]; then
  echo "ERROR: checksum mismatch for probe-passive.sh" >&2
  rm -f "${LOCAL_CACHE}"
  exit 1
fi
```

### Regenerating Checksums (maintainers)

```bash
find scripts -name "*.sh" -o -name "*.py" | sort | xargs shasum -a 256 > scripts/checksums.sha256
```

## Local Cache Structure

Cache location: `.beacon/` in the user's working directory (gitignored).

```
.beacon/
├── checksums.sha256     # Fetched copy of remote checksums
└── scripts/
    ├── core/
    │   ├── probe-passive.sh
    │   ├── fingerprint.sh
    │   └── probe-feeds.sh
    ├── analysis/
    │   ├── grep-endpoints.sh
    │   └── ...
    └── osint/
        └── ...
```

Add to project's `.gitignore`:
```
.beacon/
```

## Inline Claude Generation Fallback

When GitHub is unreachable AND no cached copy exists, Claude generates the script inline:

```markdown
[GENERATED-INLINE:scripts/core/probe-passive.sh]
```

The skill instructs Claude: "If the download fails, generate the equivalent logic as a bash script inline. Mark the session brief with [GENERATED-INLINE:{path}] so the user knows this is not the canonical version."

Inline generation is a last resort — it is NOT verified and may diverge from the canonical implementation.

## Tech Pack Download

Same mechanism, different path:
```
https://raw.githubusercontent.com/neotherapper/beacon-plugin/v{VERSION}/technologies/{framework}/{major}.x.md
```

Tech packs are markdown, not scripts, so no chmod is needed. SHA256 verification still applies.

Tech pack cache location: `.beacon/tech-packs/{framework}/{major}.x.md`

## Version Pinning Rationale

| Approach | Problem |
|----------|---------|
| `main` branch | May contain unreleased breaking changes |
| `latest` tag | Can shift; non-deterministic |
| Specific semver tag `v0.1.0` | Deterministic; matches installed plugin |

The plugin version is always available to skills via the plugin manifest. Skills should read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` to get `version` before constructing download URLs.

## Graceful Degradation Signals

Log these in the session brief when things go wrong:

| Signal | Meaning |
|--------|---------|
| `[TOOL-UNAVAILABLE:firecrawl]` | Firecrawl CLI/MCP not available |
| `[TOOL-UNAVAILABLE:wappalyzer]` | Wappalyzer MCP not available |
| `[TECH-PACK-UNAVAILABLE:nextjs:15.x]` | Tech pack not found on GitHub |
| `[GENERATED-INLINE:scripts/core/probe-passive.sh]` | Script was generated, not downloaded |
| `[SCRIPT-CACHE-HIT:scripts/core/probe-passive.sh]` | Used cached copy (normal) |
| `[SCRIPT-DOWNLOADED:scripts/core/probe-passive.sh]` | Freshly downloaded (normal) |

## Research Source

Pattern adapted from lex-harness plugin distribution research in nikai project:
- `research/harness/` for original source material
- Design spec: `docs/superpowers/specs/2026-04-13-cartographer-plugin-design.md` §§5–7
