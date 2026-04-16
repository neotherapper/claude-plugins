Feature: visual-kit server lifecycle — per-workspace, idempotent start, safe shutdown

  Background:
    Given visual-kit v1.0.0 is installed in Claude Code
    And no other visual-kit server is currently running for workspace "/work/demo"

  # ── Start ───────────────────────────────────────────────────────────────

  Scenario: First start binds a deterministic port for the workspace
    When I run "visual-kit serve --project-dir /work/demo"
    Then the server binds to 127.0.0.1
    And the server port equals the 16-bit hash of "/work/demo" offset into [20000, 60000]
    And the server writes /work/demo/.visual-kit/server/state/server-info atomically
    And the stdout JSON contains: status "running", pid, port, host, url, started_at, project_dir, visual_kit_version

  Scenario: Idempotent restart — existing live server is reused
    Given visual-kit is already running for workspace "/work/demo" at port 34287 with pid 12345
    And kill -0 12345 succeeds
    When I run "visual-kit serve --project-dir /work/demo" again
    Then the command does not start a new server process
    And it prints the same server-info JSON the existing process wrote
    And it exits 0

  Scenario: Stale server-info — process is dead, lock is taken fresh
    Given /work/demo/.visual-kit/server/state/server-info exists
    But the recorded pid is no longer alive
    When I run "visual-kit serve --project-dir /work/demo"
    Then the CLI removes the stale server-info
    And starts a new server
    And writes a fresh server-info

  Scenario: Port collision with a foreign process — auto-increment
    Given the deterministic port for "/work/demo" is 34287
    And port 34287 is already bound by an unrelated process
    When I run "visual-kit serve --project-dir /work/demo"
    Then the server tries 34288, 34289, ... up to 10 attempts
    And binds the first free port in that range
    And records the actual port in server-info

  Scenario: Lock contention — two concurrent starts in the same workspace
    Given two terminal windows are racing "visual-kit serve --project-dir /work/demo"
    When both invocations reach the lock acquisition step
    Then exactly one acquires the advisory lock at server.lock
    And the loser waits briefly, re-reads server-info, and exits 0 with that info

  # ── Multiple workspaces, same machine ───────────────────────────────────

  Scenario: Two workspaces run independent servers
    Given workspace A is "/work/project-a" and workspace B is "/work/project-b"
    When I run "visual-kit serve --project-dir /work/project-a"
    And I run "visual-kit serve --project-dir /work/project-b"
    Then both servers bind different ports (deterministic per workspace)
    And each writes its server-info inside its own workspace directory
    And neither server reads from the other workspace's content directory

  # ── Status & stop ───────────────────────────────────────────────────────

  Scenario: visual-kit status prints info for a live server
    Given visual-kit is running at port 34287 for "/work/demo"
    When I run "visual-kit status --project-dir /work/demo"
    Then the stdout JSON contains the live server-info
    And exit code is 0

  Scenario: visual-kit status reports not running
    Given no visual-kit server is running for "/work/demo"
    When I run "visual-kit status --project-dir /work/demo"
    Then the stdout JSON is {"status":"not-running","project_dir":"/work/demo"}
    And exit code is 0

  Scenario: visual-kit stop terminates the server and cleans up
    Given visual-kit is running at pid 12345 for "/work/demo"
    When I run "visual-kit stop --project-dir /work/demo"
    Then the CLI sends SIGTERM to 12345
    And after the process exits, server-info is removed
    And a server-stopped marker is written

  # ── Inactivity timeout ──────────────────────────────────────────────────

  Scenario: Inactivity timeout — no HTTP and no content writes for 30 minutes
    Given visual-kit has been running for 30 minutes
    And no HTTP request has reached the server in that window
    And no content file has been created or modified
    When the timer fires
    Then the server logs "exiting due to inactivity"
    And removes server-info
    And writes a server-stopped marker
    And the process exits 0

  Scenario: Any HTTP request resets the inactivity timer
    Given visual-kit has been inactive for 29 minutes
    When GET /vk/capabilities is served
    Then the inactivity timer resets to 0
    And the server continues running

  Scenario: Any content write resets the inactivity timer
    Given visual-kit has been inactive for 29 minutes
    When /work/demo/.paidagogos/content/lesson.json is written
    Then the inactivity timer resets to 0
    And the server continues running

  # ── Consumer pre-flight ─────────────────────────────────────────────────

  Scenario: Consumer skill pre-flight — server not running, clear error
    Given no visual-kit server is running for "/work/demo"
    When a paidagogos skill checks /work/demo/.visual-kit/server/state/server-info
    Then the file is absent or contains a server-stopped marker
    And the skill does not write any SurfaceSpec JSON
    And the skill prints: "visual-kit is not running. Run `visual-kit serve --project-dir .` to start it."

  Scenario: Consumer skill pre-flight — server running, skill proceeds
    Given visual-kit is running for "/work/demo"
    And server-info contains status "running" with a live pid
    When a paidagogos skill pre-flights
    Then the pre-flight succeeds
    And the skill writes its SurfaceSpec JSON without further checks
