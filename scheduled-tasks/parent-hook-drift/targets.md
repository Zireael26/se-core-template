# Targets — parent-hook-drift

Reads `__SE_CORE_PATH__/registry.md` at
runtime. Target set = `registry \ blacklist`.

## Scope

- Weekly, Sunday at 9 PM — deliberately end-of-week and late, so the
  Monday morning audits can act on findings the same week.
- Compares each project's `.claude/hooks/` against canonical in
  `__SE_CORE_PATH__/core-rules/hooks/`.

## Canonical hook manifest

Maintained in the prompt. As of 2026-04-20 the nine canonical hooks are:

```
session-context.sh
save-context-log.sh
post-compact-context.sh
block-destructive.sh
post-edit-verify.sh
truncation-check.sh
ui-verify.sh
stop-verify.sh
code-review-subagent.sh
```

Update both `prompt.md` and this file when adding or removing a canonical
hook.

## Per-project allowlisted extras

Projects are allowed to have hooks beyond the canonical set. Known extras:

```
msme-neev: check-module-boundary.sh
```

No other project-specific hooks as of 2026-04-20. If new ones appear, add
them here so they're not flagged as "unexpected".

## Universally allowed config files

Non-hook files in `.claude/hooks/` that any project may ship. Not flagged as
unexpected extras.

```
config.sh    # per-project env overrides (UI_PORT, UI_PATH, TODOS_FILE,
             # REVIEW_*). Sourced by ui-verify.sh (v2 canonical, 2026-04-24),
             # stop-verify.sh, code-review-subagent.sh.
```
