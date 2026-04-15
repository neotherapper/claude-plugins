# Turso MCP Setup (Optional)

Turso provides optional cross-project analytics for Draftloom. File-based workspace is always primary. Turso is secondary redundancy only.

## When to use

Use Turso if you want to:
- Track post performance analytics across multiple projects
- Query historical eval scores (e.g. "what's my average hook score over 30 days?")
- Build a cross-project writing dashboard

## Prerequisites

- Turso account (turso.tech)
- Turso CLI installed: `brew install tursodatabase/tap/turso`
- Turso MCP configured in Claude Code settings

## Setup steps

### 1. Create a Turso database
```bash
turso db create draftloom-analytics
turso db show draftloom-analytics --url
turso db tokens create draftloom-analytics
```

### 2. Enable in config.json
Add to `.draftloom/config.json`:
```json
{
  "turso_enabled": true,
  "turso_url": "libsql://draftloom-analytics-yourname.turso.io",
  "turso_auth_token": "your-token-here"
}
```

### 3. Schema (created automatically on first use)
```sql
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL,
  profile_id TEXT NOT NULL,
  title TEXT,
  draft_status TEXT,
  latest_aggregate_score INTEGER,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS scores (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  iteration INTEGER NOT NULL,
  aggregate_score INTEGER,
  seo INTEGER,
  hook INTEGER,
  voice INTEGER,
  readability INTEGER,
  timestamp TEXT
);

CREATE TABLE IF NOT EXISTS eval_events (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  iteration INTEGER NOT NULL,
  agent TEXT NOT NULL,
  score INTEGER,
  feedback TEXT,
  sections_affected TEXT,
  timestamp TEXT
);
```

## Failure handling

If the Turso write fails for any reason:
- Log the error to `iterations.log` with tag `[TURSO_ERROR]`
- Continue the eval loop without retrying
- The file-based workspace is always the source of truth

Never block or retry the eval loop on a Turso failure.
