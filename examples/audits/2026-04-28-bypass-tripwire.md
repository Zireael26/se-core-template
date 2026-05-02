# Bypass tripwire — 2026-04-28

## Summary
- Projects scanned: 6 (project-a, project-b, project-c, project-d, project-e, project-f)
- Bypasses found: 3
- Critical: 0, Low-risk: 3

All three findings are husky hook-file modifications. None are bypass keywords (`--no-verify`, `hook-bypass:`, `skip-ci:`, etc.), none are direct-to-main pushes (the only first-parent main-branch commit in window — project-e `55d091b` — carries the `(#39)` squash-merge marker and is properly excluded), and no force pushes to protected branches were observed.

The three flagged commits all modify `.husky/*` files. By the heuristic in the task spec (any change to those files in the last 24h is flagged), they are surfaced. By inspection of the commit messages and bodies, all three are **canonical-sync commits that strengthen rather than weaken the hook stack** (e.g., project-a's pre-push gains the SE Core PR-flow guard blocking direct main pushes, which was previously absent). They appear to close `[warning]` findings from the 2026-04-27 cross-project process audit.

Reporting them per the "noisy heuristic — err on the side of flagging" rule. Recommend confirming and then no further action.

## Findings

### project-a
- **low-risk** husky hook modification — `.husky/{commit-msg,pre-commit,pre-push}` rewritten to SE Core canonical
  - Commit: `7a95f9d80ab7994d860351450529bef05cb6f58c` by __MAINTAINER_NAME__ on Mon Apr 27 17:18:32 2026 +0530
  - Command/message: `chore(config): sync husky to canonical, preserve project-a appendix`
  - Body indicates: pre-commit rewritten to canonical scaffold + project-a appendix preserved; commit-msg replaced verbatim with canonical; pre-push replaced verbatim with canonical AND **adds the SE Core PR-flow guard blocking direct push to main/master, which was absent before**. Co-authored by Claude. Closes drift findings from 2026-04-27 cross-project audit.
  - Classification rationale: this strengthens enforcement (adds a previously-missing guard), it does not disable hooks. Branch is not `main` (no first-parent main commits in window).
  - Recommended fix: confirm intent, then dismiss. If confirmed canonical sync, no remediation.

### project-b
- **low-risk** husky hook modification — `.husky/pre-commit` refreshed to canonical
  - Commit: `53adbc5ca30f1a969dd728ab6fe5011bad9c8d78` by __MAINTAINER_NAME__ on Mon Apr 27 17:20:20 2026 +0530
  - Command/message: `chore(husky): refresh pre-commit to canonical (project-b appendix preserved)`
  - Body indicates: aligns to SE Core canonical scaffold (sh, set -e, lint-staged via direct node_modules binary); preserves project-b-specific process-gate skill scripts and `pnpm tokens:sync --check`. Closes pre-commit drift finding from 2026-04-27 audit.
  - Classification rationale: structural alignment to canonical, project-specific checks preserved. Landed via PR #3 (`Merge pull request #3 from __GITHUB_USER__/chore/se-core-audit-2026-04-27`), so it went through the normal review flow rather than direct-to-main.
  - Recommended fix: confirm intent, then dismiss.

### project-c
- **low-risk** husky hook modification — `.husky/pre-commit` refreshed to canonical
  - Commit: `2b13d076d36b025476927d5208adf718b0abc937` by __MAINTAINER_NAME__ on Mon Apr 27 17:21:08 2026 +0530
  - Command/message: `chore(husky): refresh pre-commit to canonical (project-c appendix preserved)`
  - Body indicates: aligns to the cross-project canonical scaffold structure used by project-a/project-b/project-d post-2026-04-27, drops the outdated SE Core comment header, preserves the project-c-specific `process:check` appendix. Closes drift finding from 2026-04-27 audit.
  - Classification rationale: header cleanup + structure alignment, project-specific checks preserved. Branch is not `main` (no first-parent main commits in window; main reflog last advanced 2026-04-24).
  - Recommended fix: confirm intent, then dismiss.

## What this means
Bypasses circumvent the guardrails we put in place to catch errors before they land. Investigate each one. If legitimate, document the reason; if not, revert and re-land through the normal flow.

In this run, all three findings are remediation work from the 2026-04-27 cross-project process audit — canonical-sync commits that **strengthen** the hook stack (notably, project-a gained a pre-push guard against direct main pushes that it didn't have before). The heuristic flags any change to `.husky/{pre-commit,commit-msg,pre-push}` because someone could be silently weakening hooks mid-flight; here the opposite is true. Confirm and dismiss. If anything in the canonical-sync narrative looks off (e.g., a project-specific check was silently dropped without an appendix preservation note), revisit individually.

## Notes from this run

- Scope check: registry has 6 active projects (project-a, project-b, project-c, project-d, project-e, project-f); blacklist section 1 is empty; all 6 were in scope.
- Direct-push detection used `git log <branch> --first-parent --no-merges --since="24 hours ago"` rather than the broader `--no-merges` form in the spec, because the broader form catches commits that landed on a feature branch and were merged in via PR (creating noise — particularly visible on project-e, which had ~17 such commits all reachable via PR #38 / PR #44 / PR #45). First-parent yielded one match (`55d091b`, project-e), which the squash-merge `(#39)` exclusion correctly filtered. No true direct pushes detected.
- Force-push check: `git reflog show main` for each project showed only `pull --ff-only`, `commit:`, and `merge:` entries in the last 24h. No `forced-update` entries.
- Bypass keyword scan was run against `--all` refs (not just current branch) to catch keywords on feature branches as well; clean across all 6 projects.
