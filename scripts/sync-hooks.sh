#!/usr/bin/env bash
# Sync canonical hook scripts to all registered projects.
#
# Reads se-core.config.json for paths.
# Reads registry.md for the project list (rows in "Active projects" table).
# Skips blacklisted projects.
#
# Skill symlinks are not synced — they are symlinks to canonical and
# update automatically. This script handles only the .sh hook *copies*
# under <project>/.claude/hooks/.
#
# Usage:
#   sync-hooks.sh              # interactive: confirm before each project
#   sync-hooks.sh --dry-run    # show what would change, no writes
#   sync-hooks.sh --yes        # non-interactive, sync everywhere
#   sync-hooks.sh <name>       # only that project (must be in registry)

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

CANONICAL_HOOKS_DIR="$SOURCE_ROOT/core-rules/hooks"
REGISTRY="$SE_CORE_ROOT/registry.md"
BLACKLIST="$SE_CORE_ROOT/blacklist.md"

[ -d "$CANONICAL_HOOKS_DIR" ] || { echo "canonical hooks dir missing: $CANONICAL_HOOKS_DIR" >&2; exit 1; }
[ -f "$REGISTRY" ]            || { echo "registry.md missing: $REGISTRY" >&2; exit 1; }

REGISTRY_ROWS=()
while IFS= read -r line; do
  [ -n "$line" ] && REGISTRY_ROWS+=("$line")
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
  local registry_path="$2"
  local proj
  proj="$(pg_resolve_project_path "$name" "$registry_path")"

  if [ ! -d "$proj" ]; then
    echo "skip (not on disk): $name → $proj"
    return
  fi
  if [ ! -d "$proj/.claude/hooks" ]; then
    echo "skip (no .claude/hooks/): $name"
    return
  fi

  echo "== $name =="
  local changed=0
  for src in "$CANONICAL_HOOKS_DIR"/*.sh; do
    local fn dst src_sha dst_sha
    fn="$(basename "$src")"
    dst="$proj/.claude/hooks/$fn"

    if [ ! -f "$dst" ]; then
      echo "  + would add: $fn"
      $DRY_RUN || { cp "$src" "$dst"; chmod +x "$dst"; }
      changed=$((changed+1))
      continue
    fi

    src_sha="$(shasum -a 256 "$src" | awk '{print $1}')"
    dst_sha="$(shasum -a 256 "$dst" | awk '{print $1}')"
    if [ "$src_sha" != "$dst_sha" ]; then
      echo "  ~ would update: $fn"
      $DRY_RUN || { cp "$src" "$dst"; chmod +x "$dst"; }
      changed=$((changed+1))
    fi
  done

  if [ "$changed" -eq 0 ]; then
    echo "  (in sync)"
  fi
}

# Filter target list
TARGETS=()
if [ -n "$ONLY_PROJECT" ]; then
  for row in "${REGISTRY_ROWS[@]}"; do
    IFS=$'\t' read -r n p <<< "$row"
    [ "$n" = "$ONLY_PROJECT" ] && TARGETS+=("$row")
  done
  if [ "${#TARGETS[@]}" -eq 0 ]; then
    echo "project not in registry: $ONLY_PROJECT" >&2
    exit 1
  fi
else
  for row in "${REGISTRY_ROWS[@]}"; do
    IFS=$'\t' read -r n p <<< "$row"
    if is_blacklisted "$n"; then
      echo "skip (blacklisted): $n"
      continue
    fi
    TARGETS+=("$row")
  done
fi

TARGET_NAMES=()
for row in "${TARGETS[@]}"; do
  IFS=$'\t' read -r n p <<< "$row"
  TARGET_NAMES+=("$n")
done
echo "Targets: ${TARGET_NAMES[*]}"
$DRY_RUN && echo "(dry-run mode — no writes)"

if ! $ASSUME_YES && ! $DRY_RUN; then
  printf "Proceed? [y/N] "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "aborted"; exit 0; }
fi

for row in "${TARGETS[@]}"; do
  IFS=$'\t' read -r n p <<< "$row"
  sync_one "$n" "$p"
done

echo "== done =="
$DRY_RUN || echo "Reminder: commit changes in each project (chore: sync hooks to canonical)."
