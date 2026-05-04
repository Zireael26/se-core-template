#!/usr/bin/env bash
# Run all canonical gates + project-local stack-profile validators.
# Usage: run-all.sh [--range=<gitspec>]
# Output: a single verdict block as defined in SKILL.md.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$SKILL_DIR/scripts/lib/common.sh"

# common.sh sets `set -euo pipefail`. The aggregator INTENTIONALLY runs
# child gates that may exit non-zero (warn=2, fail=1) — disable -e so those
# returns get captured into RESULTS rather than exiting the aggregator.
set +e

pg_load_config
RANGE="$(pg_parse_range "$@")"
PROJECT_DIR="$(pg_project_dir)"

# Bash 3.2 compatibility: parallel arrays instead of associative arrays.
LABELS=("PR hygiene" "Secrets" "Bypass markers" "Tests & coverage" "Docs discipline" "Stack profile")
RESULTS=("" "" "" "" "" "")
FINDINGS=("" "" "" "" "" "")

set_result() {
  local idx="$1" status="$2" out="$3"
  RESULTS[$idx]="$status"
  FINDINGS[$idx]="$out"
}

run_gate() {
  local idx="$1" script="$2"
  local out rc
  out="$(bash "$script" --range="$RANGE" 2>&1)"; rc=$?
  case "$rc" in
    0) set_result "$idx" "pass" "$out" ;;
    2) set_result "$idx" "warn" "$out" ;;
    *) set_result "$idx" "fail" "$out" ;;
  esac
}

resolve_stack_validator() {
  local v="$1"

  if [ -z "$v" ]; then
    return 1
  fi

  case "$v" in
    /*)
      [ -x "$v" ] && printf "%s" "$v"
      return
      ;;
  esac

  local dirs=()
  if [ -n "${CODEX_PROJECT_DIR:-}" ]; then
    dirs=(
      "$PROJECT_DIR/.agents/skills/process-gate-local"
      "$PROJECT_DIR/.claude/skills/process-gate-local"
      "$PROJECT_DIR/.agents/skills/process-gate"
      "$PROJECT_DIR/.claude/skills/process-gate"
      "$SKILL_DIR"
    )
  elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    dirs=(
      "$PROJECT_DIR/.claude/skills/process-gate-local"
      "$PROJECT_DIR/.agents/skills/process-gate-local"
      "$PROJECT_DIR/.claude/skills/process-gate"
      "$PROJECT_DIR/.agents/skills/process-gate"
      "$SKILL_DIR"
    )
  else
    dirs=(
      "$PROJECT_DIR/.agents/skills/process-gate-local"
      "$PROJECT_DIR/.claude/skills/process-gate-local"
      "$PROJECT_DIR/.agents/skills/process-gate"
      "$PROJECT_DIR/.claude/skills/process-gate"
      "$SKILL_DIR"
    )
  fi

  local dir candidate
  for dir in "${dirs[@]}"; do
    candidate="$dir/$v"
    if [ -x "$candidate" ]; then
      printf "%s" "$candidate"
      return
    fi
  done
}

run_gate 0 "$SKILL_DIR/scripts/check-pr.sh"
run_gate 1 "$SKILL_DIR/scripts/check-secrets.sh"
run_gate 2 "$SKILL_DIR/scripts/check-bypass.sh"
run_gate 3 "$SKILL_DIR/scripts/check-tests.sh"
run_gate 4 "$SKILL_DIR/scripts/check-docs.sh"

# Stack profile (idx 5)
profile="${PROCESS_GATE_STACK_PROFILE:-}"
if [ -z "$profile" ] || [ "$profile" = "n-a" ]; then
  set_result 5 "n/a" "profile=${profile:-<unset>} (no validators run)"
else
  validators=("${PROCESS_GATE_STACK_VALIDATORS[@]:-}")
  if [ "${#validators[@]}" -eq 0 ]; then
    set_result 5 "warn" "profile=$profile but PROCESS_GATE_STACK_VALIDATORS empty"
  else
    worst="pass"; combined=""
    for v in "${validators[@]}"; do
      [ -z "$v" ] && continue
      vpath="$(resolve_stack_validator "$v")"
      if [ -z "$vpath" ]; then
        combined="${combined}validator missing or not executable: $v"$'\n'
        worst="fail"; continue
      fi
      vout="$(bash "$vpath" --range="$RANGE" 2>&1)"; vrc=$?
      combined="${combined}${vout}"$'\n'
      case "$vrc" in
        0) ;;
        2) [ "$worst" = "pass" ] && worst="warn" ;;
        *) worst="fail" ;;
      esac
    done
    set_result 5 "$worst" "$combined"
  fi
fi

# --- Render verdict --------------------------------------------------------
glyph() {
  case "$1" in
    pass) printf "✅ pass" ;;
    warn) printf "⚠️  warn" ;;
    fail) printf "❌ fail" ;;
    n/a)  printf "➖ n/a"  ;;
    *)    printf "%s" "$1" ;;
  esac
}

overall="MERGEABLE"
for r in "${RESULTS[@]}"; do
  case "$r" in
    fail) overall="BLOCKED"; break ;;
    warn) [ "$overall" = "MERGEABLE" ] && overall="NEEDS CHANGES" ;;
  esac
done

printf "## process-gate verdict\n\n"
for i in 0 1 2 3 4 5; do
  printf "%-18s %s\n" "${LABELS[$i]}:" "$(glyph "${RESULTS[$i]}")"
done
printf "\nOverall: %s\n\n" "$overall"

if [ "$overall" != "MERGEABLE" ]; then
  printf "## Findings\n\n"
  for i in 0 1 2 3 4 5; do
    case "${RESULTS[$i]}" in
      pass|n/a) ;;
      *) printf "### %s\n%s\n\n" "${LABELS[$i]}" "${FINDINGS[$i]}" ;;
    esac
  done
fi

case "$overall" in
  MERGEABLE) exit 0 ;;
  "NEEDS CHANGES") exit 2 ;;
  BLOCKED) exit 1 ;;
esac
