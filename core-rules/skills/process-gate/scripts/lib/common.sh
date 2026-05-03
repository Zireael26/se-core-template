#!/usr/bin/env bash
# Shared helpers for process-gate validators.
# Sourced by every check-*.sh script. Do not run directly.

set -euo pipefail

# Colors — only when stdout is a TTY.
if [ -t 1 ]; then
  PG_RED=$'\033[31m'; PG_YEL=$'\033[33m'; PG_GRN=$'\033[32m'
  PG_DIM=$'\033[2m'; PG_RST=$'\033[0m'
else
  PG_RED=""; PG_YEL=""; PG_GRN=""; PG_DIM=""; PG_RST=""
fi

# pg_log <level> <msg>   level ∈ pass|warn|fail|info
pg_log() {
  local lvl="$1"; shift
  case "$lvl" in
    pass) printf "%spass%s %s\n" "$PG_GRN" "$PG_RST" "$*" ;;
    warn) printf "%swarn%s %s\n" "$PG_YEL" "$PG_RST" "$*" ;;
    fail) printf "%sfail%s %s\n" "$PG_RED" "$PG_RST" "$*" ;;
    info) printf "%sinfo%s %s\n" "$PG_DIM" "$PG_RST" "$*" ;;
    *)    printf "%s\n" "$*" ;;
  esac
}

# pg_finding <file>:<line>: <msg>
pg_finding() {
  printf "  %s\n" "$*"
}

# Resolve project root. Trust $CLAUDE_PROJECT_DIR if set, else fall back to git.
pg_project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    printf "%s" "$CLAUDE_PROJECT_DIR"
  else
    git rev-parse --show-toplevel 2>/dev/null
  fi
}

# Source local.config.sh if present. Idempotent.
pg_load_config() {
  local pdir
  pdir="$(pg_project_dir)" || return 0
  local cfg="$pdir/.claude/skills/process-gate/local.config.sh"
  if [ -f "$cfg" ]; then
    # shellcheck source=/dev/null
    . "$cfg"
  fi
}

# Parse --range=<spec> from "$@" -> echo the gitspec.
# Defaults to "main..HEAD" if not provided and main exists, else "HEAD~1..HEAD".
pg_parse_range() {
  local range=""
  for arg in "$@"; do
    case "$arg" in
      --range=*) range="${arg#--range=}" ;;
    esac
  done
  if [ -z "$range" ]; then
    if git rev-parse --verify main >/dev/null 2>&1; then
      range="main..HEAD"
    elif git rev-parse --verify master >/dev/null 2>&1; then
      range="master..HEAD"
    else
      range="HEAD~1..HEAD"
    fi
  fi
  printf "%s" "$range"
}

# pg_diff_files <range> -> emit changed files in range
pg_diff_files() {
  local range="$1"
  git diff --name-only --diff-filter=ACMR "$range" 2>/dev/null
}

# pg_diff_stats <range> -> emit "<additions> <deletions>"
pg_diff_stats() {
  local range="$1"
  local stats
  stats="$(git diff --shortstat "$range" 2>/dev/null || true)"
  local add del
  add="$(printf "%s" "$stats" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)"
  del="$(printf "%s" "$stats" | grep -oE '[0-9]+ deletion'  | grep -oE '[0-9]+' || echo 0)"
  printf "%s %s" "${add:-0}" "${del:-0}"
}

# Lockfile / generated detection. Echoes 1 if the path is excluded for size purposes.
pg_is_lockfile() {
  case "$1" in
    *pnpm-lock.yaml|*package-lock.json|*yarn.lock|*Cargo.lock|*go.sum|*poetry.lock|*Pipfile.lock|*Gemfile.lock|*composer.lock) return 0 ;;
    *) return 1 ;;
  esac
}

# pg_exit_code <pass|warn|fail> -> 0|2|1 (warn=2 to differentiate)
pg_exit_code() {
  case "$1" in
    pass) return 0 ;;
    warn) return 2 ;;
    fail) return 1 ;;
    *)    return 1 ;;
  esac
}
