# Targets — cross-project-process-audit

This audit **always** reads `__SE_CORE_PATH__/registry.md` at runtime for the project list. That file is the source of truth; don't hardcode paths here.

## Current expected set

Per `registry.md`, minus `blacklist.md`. Do not hardcode the current project
roster here; this file should stay reusable as the registry changes.

## If you want the audit to skip a project this run

Add it to `blacklist.md` with a short reason. Remove when ready.

## If you want the audit to target a **subset** (not all active projects)

Not supported in the scheduled run. For a one-off narrower scan, start a manual session and pass the subset explicitly to Claude.
