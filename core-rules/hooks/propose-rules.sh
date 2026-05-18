#!/usr/bin/env bash
# propose-rules.sh — Stop. Scans the just-finished session for patterns worth
# capturing in gotchas.md or core-rules/CLAUDE.md and emits a proposed diff
# for the user to apply (or ignore).
#
# Source: Trellis / core-rules / hooks.md (experimental, Tier 2 opt-in).
#
# Contract:
#   - Opt-in via PROCESS_GATE_PROPOSE_RULES=1. Unset/0 → exit 0 silently.
#   - stop_hook_active guard: if set, exit 0.
#   - Pure chat / no edits: exit 0 (skip).
#   - Returns proposed updates as additionalContext, never blocks.
#   - Budget: 30s soft cap.
#
# Why opt-in: this hook calls a subagent and reads the session transcript.
# Both cost tokens, and the value is uneven across projects. Projects that
# log lessons frequently (Neev, TGSC) opt in; throwaway projects don't.
#
# Status: scaffold. The Claude-API call is wired but the prompt is conservative
# (proposes only when there's a clear correction signal in the last ~10 turns).
# Promote out of "experimental" once n≥2 projects have run it for a month
# without false positives.

set -u

INPUT=$(cat)

# Opt-in gate — silent no-op when disabled.
if [ "${PROCESS_GATE_PROPOSE_RULES:-0}" != "1" ]; then
  exit 0
fi

# Source shared lib (sibling to this script) + enforce jq dependency.
__pr_lib="$(dirname "${BASH_SOURCE[0]}")/lib/deps.sh"
[ -f "$__pr_lib" ] || { echo "propose-rules: missing sibling lib at $__pr_lib — re-run sync-hooks" >&2; exit 1; }
# shellcheck source=lib/deps.sh disable=SC1090
. "$__pr_lib"
_se_require_jq "propose-rules"

# --- Guard 1: stop_hook_active ---
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && exit 0

PROJECT_DIR="${CODEX_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# --- Guard 2: pure-chat turn → nothing to learn from.
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    exit 0
  fi
fi

# --- Guard 3: transcript path. Claude Code writes the session transcript to
# $CLAUDE_TRANSCRIPT_PATH (set by the harness when invoking hooks). Codex
# may surface this differently — for now, accept either env var.
TRANSCRIPT="${CLAUDE_TRANSCRIPT_PATH:-${CODEX_TRANSCRIPT_PATH:-}}"
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  # No transcript available — silent skip. We don't synthesize from scratch.
  exit 0
fi

# --- Guard 4: cheap heuristic. Only run the subagent when the last ~50 lines
# of transcript contain at least one explicit user correction signal. This
# keeps the hook from burning tokens every turn.
TAIL="$(tail -200 "$TRANSCRIPT" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
case "$TAIL" in
  *"no, "*|*"don't "*|*"do not "*|*"actually, "*|*"that's wrong"*|*"stop doing"*|*"never do"*)
    : # correction signal present, proceed
    ;;
  *)
    exit 0
    ;;
esac

# --- Step 1: Dispatch a subagent via a small `claude -p` invocation. The
# subagent reads the transcript tail and the project's gotchas.md, and emits a
# proposed addition (or "no proposal" if nothing concrete found).
#
# Falls back silently if `claude` is not on PATH (e.g., Codex-driven session
# with no Claude CLI installed). The hook is informational anyway.
if ! command -v claude >/dev/null 2>&1; then
  exit 0
fi

GOTCHAS="$PROJECT_DIR/gotchas.md"
[ -f "$GOTCHAS" ] || GOTCHAS="/dev/null"

# Compose the prompt. Keep it small — this runs every Stop turn with the gate set.
# Note: heredoc-in-$() can mishandle apostrophes in some bash versions, so the
# prompt avoids them and uses ASCII-safe phrasing throughout.
PROMPT='You will read the tail of a session transcript and the project gotchas.md.
Propose ONE rule addition for the project gotchas.md if and only if the
transcript shows a clear, surprising correction the user gave the agent that
would help future sessions avoid the same mistake.

If nothing concrete is in the transcript, output exactly: NONE

Otherwise output a single markdown block in this shape (and nothing else):

## <YYYY-MM-DD> — <short title>
**Pattern:** <one-line restatement of the surprising correction>
**Why it matters:** <one short paragraph on why this surprised the agent and
why future sessions will benefit from knowing>
**Rule:** <imperative sentence the agent will read next time>

Do NOT propose rules already in gotchas.md. Do NOT propose rules for trivial
preferences (e.g., use tabs). Do NOT propose rules with weak evidence (one
slip-up is not a pattern).'

OUT="$( {
  printf '%s\n\n--- TRANSCRIPT TAIL ---\n' "$PROMPT"
  tail -300 "$TRANSCRIPT" 2>/dev/null
  printf '\n--- GOTCHAS.MD ---\n'
  cat "$GOTCHAS" 2>/dev/null
} | timeout 30 claude -p --max-turns 1 --output-format text 2>/dev/null )"

# Empty or NONE → no proposal.
case "$OUT" in
  ""|"NONE"|*"NONE"*"NONE"*) exit 0 ;;
esac

# Emit the proposal as additionalContext. Never blocks.
jq -nc --arg ctx "propose-rules: candidate gotchas.md entry below — review and append if useful.\n\n$OUT" '{additionalContext: $ctx}'
exit 0
