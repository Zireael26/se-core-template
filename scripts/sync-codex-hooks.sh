#!/usr/bin/env bash
# Sync canonical Codex hook assets to all registered projects.
#
# Reads se-core.config.json for paths.
# Reads registry.md for the project list (rows in "Active projects" table).
# Skips blacklisted projects.
#
# Skill symlinks are not synced here; this script handles only the Codex
# project-local hook assets under <project>/.codex/.
#
# Usage:
#   sync-codex-hooks.sh              # interactive: confirm before each project
#   sync-codex-hooks.sh --dry-run    # show what would change, no writes
#   sync-codex-hooks.sh --yes        # non-interactive, sync everywhere
#   sync-codex-hooks.sh <name>       # only that project (must be in registry)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/config-load.sh
. "$SCRIPT_DIR/lib/config-load.sh"

DRY_RUN=false
ASSUME_YES=false
ONLY_PROJECT=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes|-y)  ASSUME_YES=true ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
    *)
      ONLY_PROJECT="$arg"
      ;;
  esac
done

if ! pg_has_harness codex; then
  echo "Codex harness is not enabled in $SE_CORE_CONFIG_PATH; nothing to sync."
  echo "Set harnesses to include \"codex\" before running this script."
  exit 0
fi

CANONICAL_CODEX_DIR="$SOURCE_ROOT/core-rules/codex"
CANONICAL_HOOKS_DIR="$CANONICAL_CODEX_DIR/hooks"
REGISTRY="$SE_CORE_ROOT/registry.md"
BLACKLIST="$SE_CORE_ROOT/blacklist.md"

[ -f "$CANONICAL_CODEX_DIR/hooks.json" ] || { echo "canonical Codex hooks manifest missing: $CANONICAL_CODEX_DIR/hooks.json" >&2; exit 1; }
[ -d "$CANONICAL_HOOKS_DIR" ] || { echo "canonical Codex hooks dir missing: $CANONICAL_HOOKS_DIR" >&2; exit 1; }
[ -f "$REGISTRY" ]            || { echo "registry.md missing: $REGISTRY" >&2; exit 1; }

REGISTRY_NAMES=()
REGISTRY_PATHS=()
while IFS=$'\t' read -r name path; do
  [ -n "$name" ] || continue
  REGISTRY_NAMES+=("$name")
  REGISTRY_PATHS+=("$(pg_resolve_project_path "$name" "$path")")
done < <(pg_registry_rows "$REGISTRY")

BLACKLIST_NAMES=()
while IFS= read -r line; do
  [ -n "$line" ] && BLACKLIST_NAMES+=("$line")
done < <(pg_blacklist_names "$BLACKLIST")

is_blacklisted() {
  local name="$1" b
  [ "${#BLACKLIST_NAMES[@]}" -eq 0 ] && return 1
  for b in "${BLACKLIST_NAMES[@]}"; do
    [ "$b" = "$name" ] && return 0
  done
  return 1
}

sync_one() {
  local name="$1"
  local proj="$2"

  if [ ! -d "$proj" ]; then
    echo "skip (not on disk): $name → $proj"
    return
  fi

  echo "== $name =="
  local changed=0
  local manifest_dst="$proj/.codex/hooks.json"

  if [ ! -f "$manifest_dst" ]; then
    $DRY_RUN && echo "  + would add: .codex/hooks.json" || echo "  added: .codex/hooks.json"
    $DRY_RUN || { mkdir -p "$proj/.codex"; cp "$CANONICAL_CODEX_DIR/hooks.json" "$manifest_dst"; }
    changed=$((changed+1))
  elif ! cmp -s "$CANONICAL_CODEX_DIR/hooks.json" "$manifest_dst"; then
    $DRY_RUN && echo "  ~ would update: .codex/hooks.json" || echo "  updated: .codex/hooks.json"
    $DRY_RUN || cp "$CANONICAL_CODEX_DIR/hooks.json" "$manifest_dst"
    changed=$((changed+1))
  fi

  for src in "$CANONICAL_HOOKS_DIR"/*.sh; do
    local fn dst src_sha dst_sha
    fn="$(basename "$src")"
    dst="$proj/.codex/hooks/$fn"

    if [ ! -f "$dst" ]; then
      $DRY_RUN && echo "  + would add: .codex/hooks/$fn" || echo "  added: .codex/hooks/$fn"
      $DRY_RUN || { mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; chmod +x "$dst"; }
      changed=$((changed+1))
      continue
    fi

    src_sha="$(shasum -a 256 "$src" | awk '{print $1}')"
    dst_sha="$(shasum -a 256 "$dst" | awk '{print $1}')"
    if [ "$src_sha" != "$dst_sha" ]; then
      $DRY_RUN && echo "  ~ would update: .codex/hooks/$fn" || echo "  updated: .codex/hooks/$fn"
      $DRY_RUN || { cp "$src" "$dst"; chmod +x "$dst"; }
      changed=$((changed+1))
    fi
  done

  if [ "$changed" -eq 0 ]; then
    echo "  (in sync)"
  fi
}

# Filter target list
TARGET_NAMES=()
TARGET_PATHS=()
if [ -n "$ONLY_PROJECT" ]; then
  for i in "${!REGISTRY_NAMES[@]}"; do
    n="${REGISTRY_NAMES[$i]}"
    if [ "$n" = "$ONLY_PROJECT" ]; then
      TARGET_NAMES+=("$n")
      TARGET_PATHS+=("${REGISTRY_PATHS[$i]}")
    fi
  done
  if [ "${#TARGET_NAMES[@]}" -eq 0 ]; then
    echo "project not in registry: $ONLY_PROJECT" >&2
    exit 1
  fi
else
  for i in "${!REGISTRY_NAMES[@]}"; do
    n="${REGISTRY_NAMES[$i]}"
    if is_blacklisted "$n"; then
      echo "skip (blacklisted): $n"
      continue
    fi
    TARGET_NAMES+=("$n")
    TARGET_PATHS+=("${REGISTRY_PATHS[$i]}")
  done
fi

echo "Targets: ${TARGET_NAMES[*]}"
$DRY_RUN && echo "(dry-run mode — no writes)"

if ! $ASSUME_YES && ! $DRY_RUN; then
  printf "Proceed? [y/N] "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "aborted"; exit 0; }
fi

for i in "${!TARGET_NAMES[@]}"; do
  sync_one "${TARGET_NAMES[$i]}" "${TARGET_PATHS[$i]}"
done

echo "== done =="
$DRY_RUN || echo "Reminder: commit changes in each project (chore: sync Codex hooks to canonical)."
