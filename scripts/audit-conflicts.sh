#!/usr/bin/env bash
# audit-conflicts.sh — projde všechna lore/**/*.md, vypíše záznamy
# s conflict_status: open nebo acknowledged. Exit 1 pokud nalezeny.
#
# Použití:
#   scripts/audit-conflicts.sh [<lore-root>]
#
# Exit kódy:
#   0  žádné otevřené konflikty (nebo lore/ prázdné)
#   1  nalezeny záznamy s conflict_status: open nebo acknowledged
#   2  špatné použití

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LORE_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)/lore}"

if [[ ! -d "$LORE_ROOT" ]]; then
  echo "ERROR: lore root neexistuje: $LORE_ROOT" >&2
  exit 2
fi

source "$SCRIPT_DIR/_validate-common.sh"

found=0

echo "=== audit-conflicts.sh ==="
echo "lore root: $LORE_ROOT"
echo ""

while IFS= read -r -d '' md_file; do
  base=$(basename "$md_file")
  [[ "$base" == _* ]] && continue

  fm=$(extract_frontmatter "$md_file")
  [[ -z "$fm" ]] && continue

  if printf '%s\n' "$fm" | grep -qE "^conflict_status:([[:space:]]|$)"; then
    cs_val=$(printf '%s\n' "$fm" | awk '
      /^conflict_status:/ {
        sub("^conflict_status:[ \t]*", "")
        sub("[ \t]+#.*$", "")
        gsub(/^[ \t]+|[ \t]+$/, "")
        print
        exit
      }')

    case "$cs_val" in
      open|acknowledged)
        echo "CONFLICT [$cs_val]: $md_file"
        found=$((found + 1))
        ;;
    esac
  fi

done < <(find "$LORE_ROOT" -name "*.md" -print0 | sort -z)

echo ""
if [[ $found -gt 0 ]]; then
  echo "RESULT: $found otevřených konfliktů"
  exit 1
fi

echo "RESULT: žádné otevřené konflikty"
exit 0
