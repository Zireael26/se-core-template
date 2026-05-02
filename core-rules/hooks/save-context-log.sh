#!/usr/bin/env bash
# save-context-log.sh — PreCompact. Dumps a session summary to context-log.md.
# Source: Software Engineering Core / core-rules / hooks.md
#
# Contract:
#   - Runs on PreCompact.
#   - Writes (overwrites) context-log.md in the project root with:
#     branch, files touched this session, open todos, last two user asks,
#     last two assistant decisions.
#   - Side effect is the file write. No stdout needed. Never blocks.
#
# Dependencies: jq (required), git (optional).
#
# Status: new in this core-rules layer.
#
# Note: Claude Code exposes a `transcript_path` field on PreCompact pointing
# at the JSONL conversation log. We parse it for user/assistant messages.
# Todo state comes from $CLAUDE_PROJECT_DIR/.claude/todos.json when present.

set -u

INPUT=$(cat 2>/dev/null || true)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')

OUT="${PROJECT_DIR}/context-log.md"

{
  printf '# Context log\n'
  printf '_Saved: %s_\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # --- Branch ---
  if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
    printf '## Branch\n%s\n\n' "$BRANCH"
  fi

  # --- Files touched this session ---
  # Best-effort: list files edited vs HEAD plus untracked.
  if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TOUCHED=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | awk '{print $2}' | head -40)
    if [ -n "$TOUCHED" ]; then
      printf '## Files touched\n```\n%s\n```\n\n' "$TOUCHED"
    fi
  fi

  # --- Open todos ---
  TODOS_FILE="${PROJECT_DIR}/.claude/todos.json"
  if [ -f "$TODOS_FILE" ]; then
    OPEN=$(jq -r '
      (.. | objects | select(.status? == "in_progress" or .status? == "pending"))
      | "- [\(.status)] \(.content // .task // "?")"
    ' "$TODOS_FILE" 2>/dev/null | head -20)
    if [ -n "$OPEN" ]; then
      printf '## Open todos\n%s\n\n' "$OPEN"
    fi
  fi

  # --- Last two user asks and assistant decisions from the transcript ---
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    USER_MSGS=$(jq -r 'select(.role == "user" or .type == "user") | .content // .message.content // empty' "$TRANSCRIPT" 2>/dev/null \
                | tail -n 2)
    ASSISTANT_MSGS=$(jq -r 'select(.role == "assistant" or .type == "assistant") | .content // .message.content // empty' "$TRANSCRIPT" 2>/dev/null \
                | tail -n 2)

    if [ -n "$USER_MSGS" ]; then
      printf '## Last user asks\n%s\n\n' "$USER_MSGS"
    fi
    if [ -n "$ASSISTANT_MSGS" ]; then
      printf '## Last assistant decisions\n%s\n\n' "$ASSISTANT_MSGS"
    fi
  fi
} > "$OUT" 2>/dev/null || true

exit 0
