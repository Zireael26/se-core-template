# Parent-hook drift (weekly)

You are verifying that the canonical hook scripts in
`__SE_CORE_PATH__/core-rules/hooks/` are
**byte-identical** to the deployed copies in each registered project's
`.claude/hooks/` directory. The parent layer only has teeth if projects
actually inherit the current version — silent drift defeats the whole
point.

## Inputs

1. Canonical source:
   `__SE_CORE_PATH__/core-rules/hooks/*.sh`
2. Read `__SE_CORE_PATH__/registry.md`
3. Read `__SE_CORE_PATH__/blacklist.md`
4. Target set = `registry \ blacklist`.

## Canonical hook manifest

As of 2026-04-20, the canonical hook set and expected `settings.json`
wiring is:

| Hook | Event | Matcher |
|---|---|---|
| `block-destructive.sh` | PreToolUse | `Bash` |
| `post-edit-verify.sh` | PostToolUse | `Write\|Edit\|MultiEdit` |
| `truncation-check.sh` | PostToolUse | `Grep\|Bash\|Read` |
| `session-context.sh` | SessionStart | (none) |
| `post-compact-context.sh` | SessionStart | (none) |
| `save-context-log.sh` | PreCompact | (none) |
| `stop-verify.sh` | Stop | (none) |
| `code-review-subagent.sh` | Stop | (none) |
| `ui-verify.sh` | Stop | (none) |

Nine canonical hooks total. Each must be present as a file, byte-identical
to canonical, executable, and registered under the expected event + matcher.

The project may have **additional** hooks beyond these — that's fine and
expected (e.g., project-a has `check-module-boundary.sh`). Additional hooks
are not checked by this task.

## Checks per project

### 1. Presence

For each canonical hook, does the project have a file at the expected path?
- `<project>/.claude/hooks/<hook-name>.sh`

Missing file → **critical: hook missing from deployment**.

### 2. Byte-identity

For each present canonical hook, compute SHA256 of the canonical source and
of the project's deployed copy. Compare.

Mismatch → **critical: hook drift** (record both hashes, and a `diff -u` of
the two files, capped at 50 lines).

### 3. Settings.json registration

Read `<project>/.claude/settings.json`. Verify each canonical hook is
registered under the correct event (SessionStart / PreCompact /
PreToolUse / PostToolUse / Stop) with the expected matcher.

Unregistered canonical hook → **critical: hook file exists but is not wired
into settings.json** (this is silent failure — the hook will never run).

### 4. Executable bit

Each deployed `.sh` file must be executable (`chmod +x`). Stat the mode
bits. Not executable → **warning: hook will fail to run when invoked**.

### 5. Extra hooks (informational)

List any `.sh` file in `.claude/hooks/` that is not in the canonical
manifest. This is not a problem — it's a project-specific hook. Just note
it so we know each project's local extensions.

## Output

Write to `__SE_CORE_PATH__/audits/YYYY-MM-DD-parent-hook-drift.md`:

```
# Parent-hook drift — <date>

## Summary
- Projects checked: <N>
- Fully synced (all canonical hooks present + identical + registered + +x): <count>
- Drifted: <count>
- Missing hooks: <count>
- Registration gaps: <count>

## Drifted hooks

### <project-name> / <hook-name>.sh
- Canonical SHA256: <hash>
- Deployed SHA256: <hash>
- Diff (unified, last-edit on deployed side):
  ```
  <up to 50 lines of diff -u>
  ```
- Likely cause: <your read — usually either "someone edited the project copy" or "parent was updated and rollout didn't happen yet">

## Missing hooks (file absent from .claude/hooks/)

| Project | Missing hooks |
|---|---|
| ... | ... |

## Registration gaps (file exists but not in settings.json)

| Project | Hook | Event expected |
|---|---|---|
| ... | ... | ... |

## Executable-bit issues
<list>

## Per-project extras (informational)

| Project | Local-only hooks |
|---|---|
| project-a | check-module-boundary.sh |
| ... | ... |

## Recommended actions

1. <prioritized — usually: "rsync canonical hooks to project X" or "update settings.json to register run-lint.sh">
```

## Severity

- **critical**: hook drift, hook missing from disk, registered-but-missing-file, file-exists-but-not-registered.
- **warning**: hook not executable, stale last-modified-time (>6 months old suggests deployment is forgotten).
- **info**: project-specific extra hooks (just a list).

## Boundaries

- **Do not modify any project's hooks or settings.json.** This audit
  reports; the user (or a separate rollout task) does the syncing.
- Do not modify the canonical source to match a drifted project — that's
  backwards. If a project's version is better, the user decides whether to
  pull it up to canonical.

## Sensible failure modes

- If a project directory doesn't exist on disk, note it and defer to
  `registry-blacklist-health` (which will have already flagged it).
- If a project has no `.claude/` directory at all, note it and defer to
  `cross-project-process-audit`.
- If the canonical hooks directory itself is missing, stop with a clear
  error — nothing to compare against.
