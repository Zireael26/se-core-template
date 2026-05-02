# Weekly process audit — 2026-04-27

## Summary

- Projects audited: 6 (project-a, project-b, project-c, project-d, project-e, project-f)
- Projects with issues: 5 (project-e is the lone clean run)
- Total findings: 28 — critical: 8, warning: 16, info: 4
- Blacklist overdue-for-review: none (Section 1 of `blacklist.md` is empty)
- `--no-verify` bypasses (last 8 days, all 6 projects): **none** — clean on hook bypass
- Canonical reference: `core-rules/CLAUDE.md` sha256 `0b1a072582dd9f45e1489da4d381b52d4605fe4e1e68407ac983d45e723f1d3f`; canonical hook scripts present at `core-rules/hooks/`; canonical husky scripts present at `core-rules/husky/`.

The headline: SE Core rules inheritance is broken in 2 of 6 projects (project-a, project-d) — both run "unparented" in headless `claude -p` mode. Husky `pre-commit` has drifted from canonical in 3 projects (parent updated, projects haven't synced). project-d is the worst offender across the board: no `.claude/hooks/`, no `settings.json`, no symlink, no working husky scripts — effectively running with zero process enforcement.

---

## Findings by project

### project-a
**Status:** 11 findings (3 critical, 7 warning, 1 info)

- **[critical]** SE Core rules inheritance — `.claude/rules/se-core.md` symlink missing → SE Core parent rules not loaded in headless `claude -p` mode. Fix: `ln -s __SE_CORE_PATH__/core-rules/CLAUDE.md .claude/rules/se-core.md && git add .claude/rules/se-core.md`.
- **[critical]** Hook stack incomplete — 5 canonical hooks missing from `.claude/hooks/`: `code-review-subagent.sh`, `post-edit-verify.sh`, `stop-verify.sh`, `truncation-check.sh`, `ui-verify.sh`. Fix: copy from `core-rules/hooks/` and register in `settings.json`.
- **[critical]** `settings.json` does not register the missing hooks above (only registers the 4 hooks present + project-specific `check-module-boundary.sh`). Fix: extend Stop/PostToolUse/SessionStart entries once hooks are copied in.
- **[warning]** Hook drift/staleness — `block-destructive.sh`, `post-compact-context.sh`, `save-context-log.sh`, `session-context.sh` differ from canonical. Project versions predate the `core-rules/hooks/` extraction (project-a was the template seed). Fix: replace with canonical versions; preserve `check-module-boundary.sh` as project-specific extension.
- **[warning]** Husky `pre-commit` drift vs `core-rules/husky/pre-commit`. Fix: replace with canonical (lint-staged-aware version).
- **[warning]** Husky `commit-msg` drift vs canonical. Fix: replace with canonical commitlint-aware version.
- **[warning]** Husky `pre-push` drift vs canonical → SE Core PR-flow guard (block direct push to `main`) may not be in force. Fix: replace with canonical.
- **[warning]** `@__SE_CORE_PATH__/core-rules/CLAUDE.md` import line missing from project `CLAUDE.md`. Fix: add at top of file.
- **[warning]** `CLAUDE.md` is 30,117 bytes / 681 lines — ~6× the <5KB target. Project predates inheritance pattern; substantial overlap with parent. Fix: extract project-specific rules; rely on symlink + `@`-import for inheritance.
- **[warning]** `gotchas.md` missing at project root. Fix: create empty file (or seed with one entry) so the lessons-as-they-happen loop has somewhere to land.
- **[info]** `context-log.md` is present but the project has effectively run without the canonical `save-context-log.sh` hook (its version differs from canonical) — entries written by the local hook may not match the schema other tooling expects.

### project-b
**Status:** 1 finding (1 warning)

- **[warning]** Husky `pre-commit` drifts from canonical. project-b's `commit-msg` and `pre-push` are in sync; only `pre-commit` is stale. Fix: replace with `core-rules/husky/pre-commit`.

Everything else OK: symlink present, target correct, git-tracked; @-import present; all 9 canonical hooks match; `settings.json` registers the full set; `gotchas.md` modified yesterday; `CLAUDE.md` 618 B (well under target).

### project-c
**Status:** 1 finding (1 warning)

- **[warning]** Husky `pre-commit` drifts from canonical (same as project-b — parent has updates not pulled). Fix: replace with canonical.

Everything else OK: symlink + git-tracking + @-import present; all 9 hooks match canonical; `settings.json` complete; `gotchas.md` 2d old; `CLAUDE.md` 2,149 B.

### project-d
**Status:** 8 findings (4 critical, 3 warning, 1 info)

- **[critical]** SE Core rules inheritance — `.claude/rules/se-core.md` symlink missing → parent rules not loaded in headless mode.
- **[critical]** `.claude/hooks/` directory does not exist — none of the 9 canonical hooks are present. The only contents of `.claude/` are an empty `worktrees/` dir.
- **[critical]** `.claude/settings.json` missing — no hooks registered even if scripts were copied in.
- **[critical]** Husky stack non-functional — `.husky/` exists but contains only the husky-managed `_/` shim; the top-level `pre-commit`, `commit-msg`, `pre-push` scripts are all missing. No `prepare` script in `package.json` either. Net effect: SE Core PR-flow guard not enforced; commits can land on `main` directly.
- **[warning]** `@`-import line missing from `CLAUDE.md`.
- **[warning]** `CLAUDE.md` is 22,485 bytes / 501 lines — ~4.5× the <5KB target.
- **[warning]** `gotchas.md` missing.
- **[info]** `context-log.md` missing — expected once `save-context-log.sh` is in place; flagged because the hook itself isn't there to maintain it.

This project is the highest priority for remediation — it is registered/active but has effectively no SE Core enforcement.

### project-e
**Status:** OK

All checks pass. Symlink present + correct target + git-tracked; @-import present; all 9 canonical hooks match; `settings.json` complete; husky `pre-commit`/`commit-msg`/`pre-push` all match canonical; `gotchas.md` modified today; `CLAUDE.md` 3,043 B. Reference example for how a registered project should look.

### project-f
**Status:** 5 findings (1 critical, 3 warning, 1 info)

- **[critical]** Husky stack absent — `.husky/` directory does not exist; `pre-commit`, `commit-msg`, `pre-push` all missing → SE Core PR-flow guard not enforced. Note: this is a Unity 3D project (per registry), so a node-based husky stack is unusual but the registry classifies project-f as active and the rubric expects the standard hooks. If husky isn't appropriate here, the audit needs an exemption row in `blacklist.md` or a project-class carve-out in the rubric. Fix: install husky + canonical scripts, OR document the carve-out.
- **[warning]** `CLAUDE.md` is 6,517 bytes / 103 lines — slightly over the <5KB target (~30% over). Fix: trim project-specific overlap with parent.
- **[warning]** No `package.json` `prepare` script for husky bootstrapping (consistent with husky absence above).
- **[warning]** Hooks in `.claude/hooks/` all match canonical, but the `gotchas.md` file shows only one entry (modified 2d ago) — fine for a project onboarded 2d ago, no action needed yet, just noting.
- **[info]** `context-log.md` missing — expected before any compaction has fired; not actionable.

Symlink, @-import, all 9 canonical claude-hooks, and `settings.json` are all in good shape.

---

## Cross-cutting observations

1. **SE Core rules inheritance is the single highest-impact gap.** 2 of 6 projects (project-a, project-d) lack the `.claude/rules/se-core.md` symlink — meaning every scheduled `claude -p` task that runs against them is operating without parent-rule context. Both also lack the `@`-import. project-b, project-c, project-e, project-f all have both mechanisms wired correctly; the pattern is reproducible — it's just been missed on 2 projects.
2. **Husky `pre-commit` has drifted in the parent and 3 projects haven't pulled the update.** project-b, project-c, project-a all have stale `pre-commit` while their `commit-msg`/`pre-push` are in sync. This suggests the canonical `pre-commit` was updated recently (post-Phase-2-canonicalization) and the propagation step hasn't run. Worth doing one batch refresh.
3. **CLAUDE.md size is creeping up across older projects.** project-a (30KB), project-d (22KB), project-f (6.5KB) all exceed the <5KB target. project-b (618 B), project-c (2.1KB), project-e (3KB) are healthy. The pattern: projects predating the symlink/@-import inheritance pattern still carry duplicated parent text. A mechanical pass to delete content already in `core-rules/CLAUDE.md` would bring all three under target.
4. **Husky absence (project-f, project-d) means PR-flow guard isn't enforced on those repos.** A direct `git push origin main` would not be blocked. project-d is the riskier of the two — it's web-app code, not a Unity binary; project-f's risk is lower but the rubric still flags it.
5. **No `--no-verify` bypasses anywhere in the last 8 days.** Reflog is also clean. Whatever the gaps in hook *presence* above, the hooks that *are* installed have not been bypassed.

---

## Next actions

In priority order:

1. **Fix critical SE Core inheritance gaps (project-a, project-d).**
   ```
   cd __PROJECTS_ROOT__/project-a
   mkdir -p .claude/rules
   ln -s __SE_CORE_PATH__/core-rules/CLAUDE.md .claude/rules/se-core.md
   git add .claude/rules/se-core.md
   # repeat for project-d
   ```
2. **Bring project-d to baseline.** Copy `core-rules/hooks/*.sh` → `.claude/hooks/`; create `.claude/settings.json` from `core-rules/templates/`; install husky and copy `core-rules/husky/{pre-commit,commit-msg,pre-push}` → `.husky/`. This is the riskiest project to leave as-is.
3. **Refresh stale hooks across the board.**
   - project-a: replace 4 stale hooks with canonical, copy in 5 missing canonical hooks, update `settings.json`.
   - project-b, project-c, project-a: refresh husky `pre-commit` from canonical.
4. **Decide on project-f's husky.** Either install the standard husky stack on the Unity project, or add a class-level carve-out (e.g., "Unity projects skip node-based husky") to the rubric and to the registry's `Class` column.
5. **Slim down oversized `CLAUDE.md`s.** Mechanical pass on project-a, project-d, project-f — delete lines duplicated in `core-rules/CLAUDE.md`; rely on the symlink + `@`-import for inheritance.
6. **Add `gotchas.md` to project-a and project-d** — even an empty stub establishes the slot for the lessons-as-they-happen loop.
7. **Add `@`-import lines** to project-a and project-d `CLAUDE.md` (after symlink fix in #1; the import is the secondary mechanism and complements the symlink).

Suggested grouping for a single remediation pass: do step 1 across both projects, then step 3 (single batched hook refresh), then step 2 (project-d rebuild), then steps 4–7 as cleanup. Steps 1, 3, 7 can be done as a single small commit per project; step 2 is a larger setup commit; step 5 is its own commit per project.
