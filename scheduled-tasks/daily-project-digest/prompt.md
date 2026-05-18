# Daily project digest (daily, 08:00)

You are producing a single morning digest that summarizes the current state of every active Trellis-registered project. The user reads this each morning to decide where to spend the day. **Always emit a report** — silent days are not the goal here.

Output is **per-project status, no cross-project ranking**. The user wants the picture, not a recommendation; they will pick the project themselves.

## Inputs

1. Read `__TRELLIS_PATH__/registry.md`.
2. Read `__TRELLIS_PATH__/blacklist.md`.
3. Read `__TRELLIS_PATH__/scheduled-tasks/daily-project-digest/targets.md` for scope, overrides, skip list, and tunables.
4. Target set = `registry \ blacklist`.

### Per-project sources (read inside each project's canonical root)

For each target project at `__PROJECTS_ROOT__/<project>/`:

1. **Canonical root** — resolve via `git rev-parse --git-common-dir` and strip `/.git`. Worktrees share state with the main checkout; the canonical root is the right place to read `context-log.md`.
2. **`context-log.md`** — at canonical root. Read the most recent entry (the file is append-only / overwrite-per-session depending on the hook). Surface: branch, files touched, open todos, last decisions.
3. **Git activity (last 24h and last 7d)**:
   - Last 24h: `git log --since="24 hours ago" --format="%h %ad %s" --date=iso-strict` on the canonical default branch and any active feature branch.
   - Last 7d: `git log --since="7 days ago" --oneline | wc -l` for a commit-count signal.
   - Uncommitted state: `git status --short` and `git branch --show-current`.
4. **Recent audit hits** — scan `__TRELLIS_PATH__/audits/` for files whose **filename date** (`YYYY-MM-DD-…`) falls within the last 7 days — not `mtime`, which gets touched during bulk file ops and over-includes. Within each matching audit, look for project mentions in finding sections (e.g., `### <project>` headers, `**<project>**` bolding, or unambiguous prose mention inside a numbered finding). Surface only **critical** or **warning** findings; skip info-level. Skip the `-remediation.md` and `-plan.md` file classes — those are narratives, not findings.
5. **Project-local `gotchas.md`** — at canonical root. Surface entries added in the last 7 days (look at the date stamps inside the file, not file mtime — gotchas are timestamped per entry by convention).

### Per-project preflight

Before any per-project read, verify the project path exists. If not:
- Path missing under `/personal/` → record `path-missing` finding, continue to next project.
- `/personal/` itself not connected to this session → emit the connected-folder warning (see Sensible failure modes) and write a stub report.

## Process

### 1. Build per-project blocks (independent, order-preserving)

Iterate `registry.md` in **table order** (registry is the canonical sort key — preserves the user's mental ordering). For each project:

- Compose the status block (template below).
- Infer a **suggested next move** from the signals available. Examples of valid inferences:
  - Context-log says "stopped mid-refactor of X" + no commits in 24h → "Resume the X refactor (paused yesterday)."
  - Recent audit flagged `test-health` red → "Investigate test failure flagged by Monday's `test-health` audit."
  - 7d commit count = 0 + no audit hits + no context-log activity → "Dormant — no signal this week."
  - Critical CVE in `dep-vulnerabilities` → "Patch <pkg> CVE (critical)."
- If no signal supports any inference, write "No suggested move — pick based on your own priorities."
- **Never invent priority.** If the signals are weak, say so. Inference is fine; fabrication is not.

### 2. Compose summary line

One sentence at the top: how many projects had activity in the last 24h, how many had critical audit findings open, how many appear dormant (no commits in 7d).

### 3. Suggested next moves are inference, not authority

The user explicitly chose "no cross-project ranking." Do not add a "top priority across projects" section. Do not order projects by anything other than registry order. Per-project suggestions stay scoped to that project.

## Output

Write to `__TRELLIS_PATH__/audits/YYYY-MM-DD-daily-project-digest.md`:

```
# Daily project digest — <YYYY-MM-DD>

## Summary

<one sentence: N projects scanned, M with activity in last 24h, K with open critical findings, D dormant (no commits in 7d)>

## Per-project status

### <project-name>
- **Branch:** <branch-name> · **Last commit:** <short-sha> <iso-date> (<relative-time>)
- **Last 7d:** <N> commits · **Uncommitted:** <clean | N files modified>
- **Last context-log entry:** <one-line summary from the most recent context-log section>
- **Open concerns:** <bulleted list of warning+ findings from recent audits, or "none">
- **Recent gotchas (7d):** <one-liner per recent gotcha entry, or omit row if none>
- **Suggested next move:** <inference, or "No suggested move — pick based on your own priorities.">

<repeat per project in registry order>

## What this digest is not

This is a status digest, not a priority list. Suggested moves are inferences from recent signals; the user decides what to actually touch.
```

## Severity

This task uses severity only **inside** per-project "Open concerns" rows — surface **critical** and **warning** findings from prior audits. **Info** findings are intentionally omitted; this digest is for action, not a complete audit replay.

Run-level severity does not apply — the digest always writes, regardless of project state.

## Boundaries

- **Read-only across all projects.** Never modify project files, never commit, never rewrite git state, never run package-manager install/update commands.
- Do not re-run any underlying audit. The digest reads existing audit reports; it does not invoke `test-health`, `dep-vulnerabilities`, etc.
- Do not write to project directories. Only the file in `/trellis-instance/audits/` is written.
- Do not collapse or summarize across projects beyond the single Summary line at the top — per-project blocks are the load-bearing output.

## Sensible failure modes

- **`/personal/` not connected to this session.** This task was registered from a session that had `/personal/` connected. If runtime detects `/personal/` is missing, write a one-line stub:
  ```
  # Daily project digest — <date>

  Preflight failed: __PROJECTS_ROOT__/ is not connected to this scheduled-task session. The task must be re-registered from a Cowork session that has both /trellis-instance/ and /personal/ connected. See scheduled-tasks/README.md "Connected-folder requirement" for the procedure.
  ```
  Then exit. Do not attempt to read any project.
- **Project path missing under `/personal/`.** Record a `path-missing` row in that project's block and continue. Don't fail the whole digest.
- **`context-log.md` missing for a project.** Note "No context-log — likely never compacted in this project" in the row and proceed.
- **`context-log.md` present but empty / placeholder-only.** Some projects ship a `context-log.md` whose body is the `save-context-log` hook's placeholder (e.g., contains only `*(empty — hook populates on PreCompact)*` and no `## Branch` / `## Last user asks` sections). Treat this the same as missing: note "No compacted session yet — log empty" and proceed. Do not summarize the placeholder text.
- **`audits/` empty or missing.** Note "No prior audits available" once in the Summary line; per-project "Open concerns" rows default to "none".
- **Registry empty.** Write a one-line stub: "Registry is empty — nothing to digest." and exit.
- **A `git` command fails for a single project.** Note `git-error` in that project's block and continue.

## Connected-folder requirement (load-bearing)

This task reads files under `__PROJECTS_ROOT__/<project>/` for every registered project. Per `scheduled-tasks/README.md` "Connected-folder requirement", scheduled tasks capture connected folders at **registration time**. Required folder set: both `__TRELLIS_PATH__/` and `__PROJECTS_ROOT__/`. If the task is ever re-registered, it must come from a Cowork session with both folders connected.
