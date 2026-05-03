#!/usr/bin/env bash
# SE Core project onboarding. Idempotent: never overwrites existing files.
#
# Reads se-core.config.json for paths and harness selection.
# Seeds:
#   - <project>/gotchas.md, <project>/context-log.md
#   - <project>/.claude/rules/se-core.md → canonical CLAUDE.md (symlink)
#   - <project>/.claude/skills/process-gate → canonical skill (symlink)
#   - <project>/.husky/{pre-commit,commit-msg,pre-push}     [if Node project]
#   - <project>/.agents/rules/se-core.md   → canonical CLAUDE.md  [if Codex enabled]
#   - <project>/.agents/skills/process-gate → canonical skill     [if Codex enabled]
#
# Usage: onboard-project.sh <project-path>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/config-load.sh
. "$SCRIPT_DIR/lib/config-load.sh"

TEMPLATES="$SE_CORE_ROOT/core-rules/templates"
HUSKY_CANONICAL="$SE_CORE_ROOT/core-rules/husky"
CANONICAL_RULES="$SE_CORE_ROOT/core-rules/CLAUDE.md"
CANONICAL_SKILLS_DIR="$SE_CORE_ROOT/core-rules/skills"

if [ $# -ne 1 ]; then
  echo "usage: $0 <project-path>" >&2
  exit 2
fi

PROJECT="$1"
[ -d "$PROJECT" ]       || { echo "not a directory: $PROJECT" >&2; exit 1; }
[ -d "$PROJECT/.git" ]  || { echo "not a git repo: $PROJECT" >&2; exit 1; }

# Sanity-check canonical sources exist before we start seeding
[ -f "$CANONICAL_RULES" ]      || { echo "canonical rules missing: $CANONICAL_RULES" >&2; exit 1; }
[ -d "$CANONICAL_SKILLS_DIR" ] || { echo "canonical skills dir missing: $CANONICAL_SKILLS_DIR" >&2; exit 1; }

seed_file() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "skip (exists): ${dst#$PROJECT/}"
  else
    cp "$src" "$dst"
    echo "created: ${dst#$PROJECT/}"
  fi
}

seed_symlink() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [ -L "$link" ]; then
    local cur
    cur="$(readlink "$link")"
    if [ "$cur" = "$target" ]; then
      echo "skip (correct symlink): ${link#$PROJECT/}"
      return
    fi
    echo "WARN: ${link#$PROJECT/} symlinks to '$cur', expected '$target' — leaving as-is" >&2
    return
  fi
  if [ -e "$link" ]; then
    echo "WARN: ${link#$PROJECT/} exists and is not a symlink — leaving as-is" >&2
    return
  fi
  ln -s "$target" "$link"
  echo "linked: ${link#$PROJECT/} → $target"
}

seed_husky_hook() {
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
echo "   se_core_root:  $SE_CORE_ROOT"
echo "   harnesses:     ${HARNESSES[*]}"

# Project root files
seed_file "$TEMPLATES/gotchas.md"     "$PROJECT/gotchas.md"
seed_file "$TEMPLATES/context-log.md" "$PROJECT/context-log.md"

# Claude Code inheritance: rules + skills
seed_symlink "$CANONICAL_RULES"                       "$PROJECT/.claude/rules/se-core.md"
seed_symlink "$CANONICAL_SKILLS_DIR/process-gate"     "$PROJECT/.claude/skills/process-gate"

# Husky / git hooks (Node projects only)
if [ -f "$PROJECT/package.json" ]; then
  mkdir -p "$PROJECT/.husky"
  seed_husky_hook pre-commit
  seed_husky_hook commit-msg
  seed_husky_hook pre-push
else
  echo "info: no package.json — husky skipped. Project must enforce PR-flow guard via .githooks/ (see core-rules/inheritance.md \"Native git hooks\")."
fi

# Codex parity
if pg_has_harness codex; then
  echo "-- codex harness enabled --"
  seed_symlink "$CANONICAL_RULES"                   "$PROJECT/.agents/rules/se-core.md"
  seed_symlink "$CANONICAL_SKILLS_DIR/process-gate" "$PROJECT/.agents/skills/process-gate"
fi

echo "== done =="
echo "Next:"
[ -f "$PROJECT/package.json" ] && echo "  - run install in project so husky activates (pnpm/bun/npm install)"
echo "  - add @-import line to project CLAUDE.md if not present:"
echo "      @$CANONICAL_RULES"
echo "  - register the project in $SE_CORE_ROOT/registry.md (chore: register <name>)"
echo "  - configure project-local skill: $PROJECT/.claude/skills/process-gate/local.config.sh"
