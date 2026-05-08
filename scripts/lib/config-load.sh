#!/usr/bin/env bash
# Load se-core.config.json into bash variables.
#
# Usage:
#   . "$(dirname "$0")/lib/config-load.sh"
#   echo "$SE_CORE_ROOT"     # /Users/.../projects/se-core
#   echo "$PROJECTS_ROOT"    # /Users/.../projects/personal
#   echo "${HARNESSES[@]}"   # claude codex
#
# Resolves the config file by:
#   1. Walking up from the calling script until se-core.config.json is found.
#   2. If $SE_CORE_CONFIG is set, that path wins.
#
# Requires: jq.

set -euo pipefail

_pgcfg_locate() {
  if [ -n "${SE_CORE_CONFIG:-}" ]; then
    if [ -f "$SE_CORE_CONFIG" ]; then
      printf "%s" "$SE_CORE_CONFIG"
      return 0
    fi
    echo "config-load: SE_CORE_CONFIG=$SE_CORE_CONFIG does not exist" >&2
    return 1
  fi
  # Walk up from invoking script's dir
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/se-core.config.json" ]; then
      printf "%s" "$dir/se-core.config.json"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "config-load: no se-core.config.json found in any parent directory" >&2
  return 1
}

if ! command -v jq >/dev/null 2>&1; then
  echo "config-load: jq is required but not installed" >&2
  echo "  macOS:   brew install jq" >&2
  echo "  Debian:  apt-get install jq" >&2
  return 1 2>/dev/null || exit 1
fi

_PGCFG_PATH="$(_pgcfg_locate)" || return 1
SE_CORE_CONFIG_PATH="$_PGCFG_PATH"
export SE_CORE_CONFIG_PATH

SE_CORE_ROOT="$(jq -r '.se_core_root' "$_PGCFG_PATH")"
PROJECTS_ROOT="$(jq -r '.projects_root' "$_PGCFG_PATH")"
USER_HOME="$(jq -r '.user_home' "$_PGCFG_PATH")"
MAINTAINER_NAME="$(jq -r '.maintainer_name' "$_PGCFG_PATH")"
GITHUB_USER="$(jq -r '.github_user' "$_PGCFG_PATH")"

# HARNESSES as a bash array
HARNESSES=()
while IFS= read -r h; do
  HARNESSES+=("$h")
done < <(jq -r '.harnesses[]' "$_PGCFG_PATH")

# Template config
TEMPLATE_REMOTE="$(jq -r '.template.remote // empty' "$_PGCFG_PATH")"
TEMPLATE_BRANCH="$(jq -r '.template.branch // "main"' "$_PGCFG_PATH")"

SED_FLAVOR="$(jq -r '.sed_flavor // "auto"' "$_PGCFG_PATH")"

export SE_CORE_ROOT PROJECTS_ROOT USER_HOME MAINTAINER_NAME GITHUB_USER
export TEMPLATE_REMOTE TEMPLATE_BRANCH SED_FLAVOR

# Validation
[ -d "$SE_CORE_ROOT" ]    || { echo "config-load: se_core_root not a directory: $SE_CORE_ROOT" >&2; return 1; }
[ -d "$PROJECTS_ROOT" ]   || echo "config-load: warning — projects_root not a directory: $PROJECTS_ROOT" >&2

# Convenience: is harness X enabled?
# Usage:  if pg_has_harness codex; then ...; fi
pg_has_harness() {
  local target="$1" h
  for h in "${HARNESSES[@]}"; do
    [ "$h" = "$target" ] && return 0
  done
  return 1
}
