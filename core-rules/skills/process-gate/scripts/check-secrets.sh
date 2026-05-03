#!/usr/bin/env bash
# Gate 2: Secrets scan over the diff range.
# Usage: check-secrets.sh [--range=<gitspec>]

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$SKILL_DIR/scripts/lib/common.sh"

pg_load_config
RANGE="$(pg_parse_range "$@")"
PROJECT_DIR="$(pg_project_dir)"

# Patterns: name|regex (regex evaluated with grep -E on the diff added-lines stream)
PATTERNS=(
  "AWS access key|AKIA[0-9A-Z]{16}"
  "AWS secret|aws_secret_access_key[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9/+=]{40}"
  "Generic API key|(api[_-]?key|secret[_-]?key|access[_-]?token)[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9_-]{20,}['\"]"
  "Private key block|-----BEGIN [A-Z ]*PRIVATE KEY-----"
  "GitHub token (ghp)|ghp_[A-Za-z0-9]{36}"
  "GitHub PAT|github_pat_[A-Za-z0-9_]{82}"
  "Slack token|xox[baprs]-[A-Za-z0-9-]{10,}"
  "Stripe live key|sk_live_[A-Za-z0-9]{24,}"
  "Anthropic key|sk-ant-[A-Za-z0-9_-]{40,}"
  "OpenAI key|sk-[A-Za-z0-9]{48}"
  "DB connection w/ password|(postgres|postgresql|mysql|mongodb|redis)://[^:@/]+:[^@/]+@"
)

# Allowlist (optional)
ALLOWLIST="$PROJECT_DIR/.claude/skills/process-gate/secrets-allowlist.txt"
ALLOW_ENTRIES=()
if [ -f "$ALLOWLIST" ]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf "%s" "$line" | awk '{$1=$1};1')"
    [ -z "$line" ] && continue
    ALLOW_ENTRIES+=("$line")
  done < "$ALLOWLIST"
fi

is_allowed() {
  local file="$1" hit="$2"
  local entry pat
  for entry in "${ALLOW_ENTRIES[@]}"; do
    pat="${entry#*:}"
    epath="${entry%%:*}"
    if [ "$file" = "$epath" ] && printf "%s" "$hit" | grep -qE "$pat"; then
      return 0
    fi
  done
  return 1
}

# .env-style file blocklist
worst="pass"
findings=()

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    .env|.env.*|*.pem|*.key|*.keystore|*.p12|*.pfx|*/secrets/*)
      # .env.example with placeholder values is a special case: pattern scan handles it.
      if [ "$f" != ".env.example" ] && ! [[ "$f" == *.example ]] && ! [[ "$f" == *.sample ]] && ! [[ "$f" == *.template ]]; then
        findings+=("$f: secret-bearing path committed")
        worst="fail"
      fi
      ;;
  esac
done < <(pg_diff_files "$RANGE")

# Pattern scan over added lines
added_lines="$(git diff --no-color --unified=0 "$RANGE" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

if [ -n "$added_lines" ]; then
  while IFS='|' read -r name regex; do
    # Use `--` so patterns that start with `-` don't get parsed as flags by BSD grep
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      # Try to locate file:line for the hit (best-effort)
      loc="$(git diff --no-color --unified=0 "$RANGE" 2>/dev/null \
        | awk -v h="$hit" 'BEGIN{file=""; line=0} \
            /^\+\+\+ b\// {file=substr($0,7)} \
            /^@@ / {match($0, /\+[0-9]+/); line=substr($0,RSTART+1,RLENGTH-1)+0} \
            /^\+/ && !/^\+\+\+/ {if (index($0,h)) {print file":"line; exit} line++}')"
      file="${loc%%:*}"
      lineno="${loc##*:}"
      if [ -n "${file:-}" ] && is_allowed "$file" "$hit"; then
        continue
      fi
      findings+=("${file:-?}:${lineno:-?} — $name")
      worst="fail"
    done < <(printf "%s" "$added_lines" | grep -oE -- "$regex" | sort -u)
  done < <(printf "%s\n" "${PATTERNS[@]}")
fi

case "$worst" in
  pass) pg_log pass "Secrets (range=$RANGE)" ;;
  warn) pg_log warn "Secrets (range=$RANGE)"; for f in "${findings[@]}"; do pg_finding "$f"; done ;;
  fail) pg_log fail "Secrets (range=$RANGE)"; for f in "${findings[@]}"; do pg_finding "$f"; done ;;
esac

pg_exit_code "$worst"
