#!/usr/bin/env bash
# SE Core project onboarding. Idempotent: never overwrites existing files.
#
# Wires a project into the SE Core process regime:
#   1. Creates the .claude/rules/se-core.md symlink (load-bearing inheritance — see core-rules/inheritance.md).
#   2. Seeds gotchas.md, context-log.md.
#   3. Installs husky hooks (.husky/pre-commit, commit-msg, pre-push).
#   4. Reminds you to add the @-import line to the project's CLAUDE.md.
#
# Usage:
#   ./scripts/onboard-project.sh <project-path>
#
# Auto-detects SE_CORE_PATH from this script's own location, so the script
# is portable as long as it stays inside the SE Core repo.
#
# After running, run your package manager so husky activates:
#   cd <project-path> && (pnpm install | bun install | npm install)

set -euo pipefail

# Auto-detect SE Core root (parent of this script's parent dir).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SE_CORE="$(cd "$SCRIPT_DIR/.." && pwd)"

CANONICAL_RULES="$SE_CORE/core-rules/CLAUDE.md"
TEMPLATES="$SE_CORE/core-rules/templates"
HUSKY_CANONICAL="$SE_CORE/core-rules/husky"

if [ $# -ne 1 ]; then
  echo "usage: $0 <project-path>" >&2
  exit 2
fi

PROJECT="$(cd "$1" && pwd)"
[ -d "$PROJECT" ]       || { echo "not a directory: $PROJECT" >&2; exit 1; }
[ -d "$PROJECT/.git" ]  || { echo "not a git repo: $PROJECT" >&2; exit 1; }
[ -f "$CANONICAL_RULES" ] || { echo "canonical rules missing: $CANONICAL_RULES" >&2; exit 1; }

seed_file() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "skip (exists): ${dst#$PROJECT/}"
  else
    cp "$src" "$dst"
    echo "created: ${dst#$PROJECT/}"
  fi
}

seed_hook() {
  local name="$1"
  local dst="$PROJECT/.husky/$name"
  if [ -e "$dst" ]; then
    echo "skip (exists): .husky/$name"
  else
    cp "$HUSKY_CANONICAL/$name" "$dst"
    chmod +x "$dst"
    echo "created: .husky/$name"
  fi
}

echo "== onboarding $PROJECT =="
echo "   SE Core root: $SE_CORE"

# --- 1. Inheritance symlink (load-bearing — works in headless `claude -p` mode) ---
mkdir -p "$PROJECT/.claude/rules"
SYMLINK_PATH="$PROJECT/.claude/rules/se-core.md"
if [ -L "$SYMLINK_PATH" ]; then
  echo "skip (exists): .claude/rules/se-core.md (symlink)"
elif [ -e "$SYMLINK_PATH" ]; then
  echo "WARN: .claude/rules/se-core.md exists but is NOT a symlink — leaving as-is."
  echo "      Replace it manually with: ln -sf '$CANONICAL_RULES' '$SYMLINK_PATH'"
else
  ln -s "$CANONICAL_RULES" "$SYMLINK_PATH"
  echo "created: .claude/rules/se-core.md -> $CANONICAL_RULES"
fi

# --- 2. Project-local files ---
seed_file "$TEMPLATES/gotchas.md"     "$PROJECT/gotchas.md"
seed_file "$TEMPLATES/context-log.md" "$PROJECT/context-log.md"

# --- 3. Husky hooks (Node projects) ---
if [ -f "$PROJECT/package.json" ]; then
  mkdir -p "$PROJECT/.husky"
  seed_hook pre-commit
  seed_hook commit-msg
  seed_hook pre-push
else
  echo "skip: no package.json — husky not applicable."
  echo "      For native git hooks (Unity / Rust / Go / Python), see core-rules/inheritance.md"
  echo "      'Native git hooks (Unity / non-Node projects)' section."
fi

echo
echo "== done =="
echo
echo "Next steps (manual):"
echo "  1. Add this @-import line at the TOP of $PROJECT/CLAUDE.md:"
echo
echo "       @$CANONICAL_RULES"
echo
echo "  2. Track the symlink in git so it survives a clone:"
echo "       cd '$PROJECT' && git add .claude/rules/se-core.md gotchas.md context-log.md"
if [ -f "$PROJECT/package.json" ]; then
echo "       git add .husky/pre-commit .husky/commit-msg .husky/pre-push"
echo "  3. Install deps so husky activates: cd '$PROJECT' && (pnpm install | bun install | npm install)"
fi
echo "  4. Add the project to $SE_CORE/registry.md."
