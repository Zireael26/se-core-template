# Targets — daily-project-digest

Reads `__TRELLIS_PATH__/registry.md` at runtime. The registry minus `blacklist.md` is the target set — no hardcoded paths. Iterate **in registry table order** — that order reflects the user's mental model and the digest preserves it.

## Scope

- Daily at 08:00 local time. Weekends included.
- Lookback windows fixed in the prompt: 24h for commit and activity signal, 7d for commit-count and audit-finding scan, 7d for recent gotchas.
- Output: `audits/YYYY-MM-DD-daily-project-digest.md`. Always written (no silent days).

## If you want to skip a project for this digest

Add it to `blacklist.md` with reason `daily-project-digest-suppress` and a review-after date. This is heavier-handed than usual blacklist entries because skipping a project here means it disappears from your morning view entirely — re-evaluate at the review-after date whether it should actually rejoin the registry.

## Per-project overrides

The digest doesn't use per-project tunables today. Sources are uniform across projects:

- canonical-root resolution (`git rev-parse --git-common-dir`)
- `context-log.md` at canonical root
- `git log`, `git status`, `git branch --show-current`
- last-7d audit reports under `trellis-instance/audits/`
- `gotchas.md` at canonical root

If a project ever needs a different signal source (e.g., Unity projects might want a `ProjectSettings/ProjectVersion.txt` reference instead of a context-log entry, since Unity-Trellis context-logging conventions may diverge), document the override here in the form:

```
# <project-name>: <key>=<value>
```

No overrides set as of 2026-05-16.

## Tunable thresholds

| Threshold | Default | Where it lives | Notes |
|---|---|---|---|
| Recent-activity window | 24h | `prompt.md` §Inputs.3 | Drives "active in last 24h" Summary count. |
| Commit-count window | 7d | `prompt.md` §Inputs.3 | Drives 7d commit count and "dormant" Summary count. |
| Audit-scan window | 7d | `prompt.md` §Inputs.4 | Findings older than 7d don't surface — they should have been actioned by now. |
| Recent-gotcha window | 7d | `prompt.md` §Inputs.5 | Avoids re-surfacing the same gotchas every morning. |

If you tune any of these, change them in `prompt.md` and note the change here with date.

## Connected-folder requirement

Same as the dep-* tasks — needs both `__TRELLIS_PATH__/` and `__PROJECTS_ROOT__/` connected at registration time. See `scheduled-tasks/README.md` "Connected-folder requirement" for the procedure. If this task is ever recreated from a session missing `/personal/`, every run will write a stub report and exit.
