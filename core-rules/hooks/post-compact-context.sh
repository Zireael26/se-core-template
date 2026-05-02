#!/usr/bin/env bash
# post-compact-context.sh — SessionStart (source=compact). Re-inject context-log.md.
# Source: Software Engineering Core / core-rules / hooks.md
#
# Contract:
#   - Runs only when SessionStart.source == "compact".
#   - If context-log.md exists in the project root, emits it as additionalContext.
#   - Never blocks. Exit 0 always.
#
# Dependencies: jq (required).
#
# Status: new in this core-rules layer.

set -u

INPUT=$(cat 2>/dev/null || true)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty')
if [ "$SOURCE" != "compact" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG="${PROJECT_DIR}/context-log.md"

if [ ! -f "$LOG" ]; then
  exit 0
fi

# Cap injected content at ~4K chars — compact rehydration should be lean.
CONTENT=$(head -c 4000 "$LOG")
if [ -z "$CONTENT" ]; then
  exit 0
fi

jq -nc \
  --arg ctx "$CONTENT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
