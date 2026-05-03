#!/usr/bin/env bash
# Gate 4: Tests & coverage — runs project-declared typecheck/lint/test commands.
# Usage: check-tests.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$SKILL_DIR/scripts/lib/common.sh"

pg_load_config
PROJECT_DIR="$(pg_project_dir)"
cd "$PROJECT_DIR"

worst="pass"
findings=()

# Auto-detect package manager if not declared
if [ -z "${PROCESS_GATE_TYPECHECK_CMD:-}${PROCESS_GATE_LINT_CMD:-}${PROCESS_GATE_TEST_CMD:-}" ]; then
  if [ -f "pnpm-lock.yaml" ];      then PM="pnpm"
  elif [ -f "bun.lockb" ];         then PM="bun"
  elif [ -f "package-lock.json" ]; then PM="npm"
  elif [ -f "yarn.lock" ];         then PM="yarn"
  else PM=""
  fi
  if [ -n "$PM" ] && [ -f "package.json" ]; then
    PROCESS_GATE_TYPECHECK_CMD="${PROCESS_GATE_TYPECHECK_CMD:-$PM typecheck}"
    PROCESS_GATE_LINT_CMD="${PROCESS_GATE_LINT_CMD:-$PM lint}"
    PROCESS_GATE_TEST_CMD="${PROCESS_GATE_TEST_CMD:-$PM test}"
  fi
fi

PROCESS_GATE_TEST_TIMEOUT="${PROCESS_GATE_TEST_TIMEOUT:-300}"

run_check() {
  local label="$1" cmd="$2"
  if [ -z "$cmd" ]; then
    findings+=("$label: not declared in local.config.sh and not auto-detectable")
    [ "$worst" = "pass" ] && worst="warn"
    return
  fi

  local out rc
  if command -v timeout >/dev/null 2>&1; then
    out="$(timeout "$PROCESS_GATE_TEST_TIMEOUT" bash -c "$cmd" 2>&1)"; rc=$?
  else
    out="$(bash -c "$cmd" 2>&1)"; rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    findings+=("$label: \`$cmd\` exited $rc")
    # Last 10 lines of output for context
    while IFS= read -r line; do
      findings+=("    $line")
    done < <(printf "%s\n" "$out" | tail -n 10)
    worst="fail"
  fi
}

run_check "typecheck" "${PROCESS_GATE_TYPECHECK_CMD:-}"
run_check "lint"      "${PROCESS_GATE_LINT_CMD:-}"
run_check "tests"     "${PROCESS_GATE_TEST_CMD:-}"

# Optional: coverage
if [ -n "${PROCESS_GATE_COVERAGE_CMD:-}" ]; then
  out="$(bash -c "$PROCESS_GATE_COVERAGE_CMD" 2>&1 || true)"
  pct="$(printf "%s" "$out" | grep -oE 'All files[^|]*\|[[:space:]]*[0-9]+(\.[0-9]+)?' | grep -oE '[0-9]+(\.[0-9]+)?$' | head -1)"
  floor="${PROCESS_GATE_COVERAGE_FLOOR:-0}"
  if [ -n "$pct" ] && [ "$(printf '%.0f' "$pct")" -lt "$floor" ]; then
    findings+=("coverage: ${pct}% < floor ${floor}%")
    [ "$worst" = "pass" ] && worst="warn"
  fi
fi

case "$worst" in
  pass) pg_log pass "Tests & coverage" ;;
  warn) pg_log warn "Tests & coverage"; for f in "${findings[@]}"; do pg_finding "$f"; done ;;
  fail) pg_log fail "Tests & coverage"; for f in "${findings[@]}"; do pg_finding "$f"; done ;;
esac

pg_exit_code "$worst"
