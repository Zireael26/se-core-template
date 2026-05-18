---
description: Map an unfamiliar subsystem in a read-only subagent and hand the result back as a file the editing session can load.
argument-hint: <subsystem-or-path>
---

# Explore: $ARGUMENTS

You are exploring `$ARGUMENTS` ahead of an edit. This is the read-only explorer half of the explore-then-edit split: a fresh subagent maps the subsystem, writes a compact summary to disk, and you load that summary before touching code in this session.

This is the fast, ephemeral counterpart to `/primer`. Use it when:

- The user is about to ask for an edit in a subsystem you have never seen.
- You suspect editing without exploration will produce a wrong-shaped change.
- The subsystem is unlikely to stabilise enough for a long-lived primer yet.

If the subsystem is stable enough that the result is worth keeping past this turn, run `/primer <slug>` afterwards to upgrade the ephemeral note into a durable primer.

## Steps

### 0. Resolve canonical root

Run `git rev-parse --git-common-dir` and take its parent. All explore notes land at `<canonical-root>/.claude/primers/_explore/`, parallel to durable primers but under the `_explore/` subdir so the rest of the primer machinery ignores them.

If `<canonical-root>/.claude/primers/` does not exist, create `<canonical-root>/.claude/primers/_explore/`. The primer system is opt-in per `core-rules/CLAUDE.md`; explore notes follow the same opt-in.

### 1. Dispatch the explorer subagent

Use the Agent tool (subagent_type: `Explore` if available, otherwise `general-purpose`) with a self-contained prompt:

```
Read-only exploration of <subsystem-or-path> in this repo. Map it as follows
and write the result to <canonical-root>/.claude/primers/_explore/<slug>-<short-sha>.md
using the Write tool. Do not modify any source files.

Sections:
- Purpose (1-2 sentences)
- Entry points (3-5 file paths)
- Data flow (one paragraph, named files + functions, no line numbers)
- Dependencies (other modules, services, env vars)
- Likely traps for an editor (anything subtle: ordering, hidden invariants, codegen)
- Suggested edit posture (e.g., "edit X then Y; tests live at Z")

Keep under 120 lines. Pin to the current HEAD commit.
```

Slug rule: lowercase, hyphen-separated, derived from `$ARGUMENTS`. Short SHA: first 7 of `git rev-parse HEAD`.

### 2. Wait for the explorer to finish

Single round-trip. Do not start editing while it runs.

### 3. Load the explore note

Read the file the subagent wrote. Treat it as authoritative for *shape*; verify any specific claim against the live tree before acting on it.

### 4. Continue with the edit

You now have the subsystem map in head. Proceed with the user's original request.

### 5. Decide about persistence

After the edit lands, ask the user:

> The explore note for `$ARGUMENTS` is at `<path>`. Promote it to a durable primer via `/primer $ARGUMENTS`, or delete it?

Default to deletion if the subsystem feels too volatile for a primer. The `_explore/` directory is not loaded at session start, so leftover notes are harmless but accumulate — periodically clear them.

## What this command does NOT do

- It does not modify source code itself; it only writes an exploration note.
- It does not update `<canonical-root>/.claude/primers/INDEX.md` — INDEX tracks durable primers only.
- It does not block — if the subagent times out or the file fails to write, fall back to inline exploration and tell the user.

## Why not just explore inline?

Inline exploration mixes read-only context-building with edit-time decisions in the same window. The subagent split keeps the editing session's context clean: you load a 100-line summary instead of paying for the agent's full traversal. This is the pattern called out in the Anthropic best-practices guide ("read-only subagent maps subsystem, writes findings to file; main agent edits with full picture"), shaped to land on Trellis's existing primer infrastructure.
