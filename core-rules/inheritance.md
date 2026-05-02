# Load-bearing inheritance mechanism

Claude Code does **not** cascade `CLAUDE.md` up the directory tree — a child session loads the nearest `CLAUDE.md` and nothing above it unless the child explicitly names a parent. There are two documented mechanisms for explicit inheritance, and they behave very differently.

## Primary — `.claude/rules/` symlink (REQUIRED for every registered project)

Each project under `registry.md` MUST carry a symlink at:

    <project-root>/.claude/rules/se-core.md → __SE_CORE_PATH__/core-rules/CLAUDE.md

Claude Code loads every file under `.claude/rules/` **unconditionally** at session start — no approval dialog, no gate, no TTY dependency. This works identically in interactive and `claude -p` headless modes, which is the property that matters: every automated run (scheduled tasks, cron jobs, subagents, CI) must inherit parent rules without human interaction.

Track the symlink in git so the inheritance is visible in repo state and protected from local deletion. If `.claude/` is gitignored in a project, add explicit exceptions for `.claude/rules/` and `.claude/rules/se-core.md` — otherwise the symlink exists only on one machine.

## Secondary — `@`-import in project `CLAUDE.md` (interactive fallback only)

Every project `CLAUDE.md` also carries an `@`-import line pointing at the canonical path:

    @__SE_CORE_PATH__/core-rules/CLAUDE.md

This is kept for belt-and-braces redundancy in **interactive** sessions only. `@`-imports are gated by Claude Code's trust-verification approval dialog, which:

- Cannot fire in `-p` / headless mode — trust verification is explicitly disabled non-interactively (per Claude Code docs). Unapproved imports silently skip.
- Fires once on the first interactive session that encounters a new `@`-import. Approve → persists per project. Decline → permanently disabled for that project with no further prompt.

So the `@`-import is useful only after a human has clicked "approve" at least once in interactive mode. It is never load-bearing for automation and must never be treated as the primary inheritance path.

## Silent-drop invariants

1. If either the symlink target or the `@`-import path does not resolve on disk, Claude Code drops the instruction with **no runtime error, no warning, no user-visible log line.** Detection is only possible via the `InstructionsLoaded` hook (`~/.claude/hooks/log-instructions-loaded.sh` → `~/.claude/instruction-audit.log`), and even that captures `session_start` reliably but not every include-style event.
2. When this parent directory moves, the symlinks in all five projects break at once. Update them in the same filesystem change as the move, or accept that every child session will silently run unparented until the next scheduled audit catches the drift.
3. Never replace the symlink with a file copy. A copy diverges. Divergence kills the whole point of a parent layer.

## Registered-project checklist

Every project in `registry.md` must:

- [ ] Contain `CLAUDE.md` at the project root.
- [ ] Contain `.claude/rules/se-core.md` as a symlink to the canonical core-rules path.
- [ ] Track `.claude/rules/se-core.md` in git (including `.gitignore` exceptions where needed).
- [ ] Contain the `@`-import line in the project `CLAUDE.md` for interactive fallback.
- [ ] Have GitHub branch protection enabled on `main` (see `registry.md` step 5).

## Native git hooks (Unity / non-Node projects)

Projects without `package.json` (Unity, C#, Rust, Go, Python-only, etc.) cannot use husky. They MUST instead enforce the SE Core PR-flow guard via native git hooks:

- Set `git config core.hooksPath` to a tracked directory (e.g., `.githooks/`).
- That directory MUST contain a `pre-push` whose body includes the canonical SE Core PR-flow guard (block direct push to `main`/`master`, `SE_CORE_ALLOW_MAIN_PUSH=1` override).
- The hooks directory and its scripts MUST be tracked in git so the enforcement is visible in repo state and survives a clone.

Reference example: `lume` (Unity 3D) uses `.githooks/pre-push` with `core.hooksPath = .githooks`. The `cross-project-process-audit` rubric skips the husky-presence check when `package.json` is absent and the native-hooks fallback is in place — see `scheduled-tasks/cross-project-process-audit/prompt.md` §3.
