#!/usr/bin/env bash
# validate-all.sh — orchestrátor validace všech lore/ typů
#
# Použití:
#   scripts/validate-all.sh [<lore-root>]
#
#   lore-root: kořenový adresář lore/ (výchozí: lore/ relativně od skriptu)
#
# Exit kódy:
#   0  vše validní (nebo jen warnings)
#   1  nalezeny errors
#   2  špatné použití
#
# Chování:
#   - Projde všechny .md soubory v lore/<type>/ pro každý podporovaný typ
#   - Přeskočí interní soubory (_*.md, _*.yml)
#   - Agreguje výsledky, vypíše souhrn
#   - WARNING: pokud počet .md souborů v lore/<type>/ přesáhne 50
#     a _index.yml neexistuje → WARNING (S-002 implementace)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LORE_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)/lore}"

SUPPORTED_TYPES=(lessons decisions projects processes personas)

total_ok=0
total_fail=0
total_warn=0

echo "=== validate-all.sh ==="
echo "lore root: $LORE_ROOT"
echo ""

for type in "${SUPPORTED_TYPES[@]}"; do
  type_dir="$LORE_ROOT/$type"

  if [[ ! -d "$type_dir" ]]; then
    echo "SKIP: $type/ (adresář neexistuje)"
    continue
  fi

  # S-002: kontrola _index.yml threshold
  md_count=$(find "$type_dir" -maxdepth 1 -name "*.md" ! -name "_*" | wc -l)
  if [[ $md_count -gt 50 && ! -f "$type_dir/_index.yml" ]]; then
    echo "WARN:  $type/ má $md_count záznamů bez _index.yml — zvažte scripts/build-index.sh"
    total_warn=$((total_warn + 1))
  fi

  # Singularizace pro název validátoru
  case "$type" in
    lessons)   singular="lesson" ;;
    decisions) singular="decision" ;;
    projects)  singular="project" ;;
    processes) singular="process" ;;
    personas)  singular="persona" ;;
    *)         singular="${type%s}" ;;
  esac
  validator="$SCRIPT_DIR/validate-${singular}.sh"

  if [[ ! -x "$validator" ]]; then
    echo "WARN:  validátor $validator neexistuje nebo není spustitelný — přeskakuji $type/"
    total_warn=$((total_warn + 1))
    continue
  fi

  echo "--- $type/ ---"
  while IFS= read -r -d '' md_file; do
    base=$(basename "$md_file")
    [[ "$base" == _* ]] && continue

    result=$("$validator" "$md_file" 2>&1)
    exit_code=$?

    echo "$result"
    if [[ $exit_code -eq 0 ]]; then
      total_ok=$((total_ok + 1))
    else
      total_fail=$((total_fail + 1))
    fi
  done < <(find "$type_dir" -maxdepth 1 -name "*.md" -print0 | sort -z)
  echo ""
done

echo "=== Souhrn ==="
echo "OK:   $total_ok souborů"
echo "FAIL: $total_fail souborů"
echo "WARN: $total_warn varování"
echo ""

if [[ $total_fail -gt 0 ]]; then
  echo "RESULT: FAIL"
  exit 1
fi

echo "RESULT: OK"
exit 0
