#!/usr/bin/env bash
# audit-dangling-refs.sh — Detekuje dangling cross-reference edges v ~/.lore/
# Výstup: 0 dangling refs = exit 0; nalezeny = exit 1; ~/.lore/ neexistuje = exit 2
# Použití: bash audit-dangling-refs.sh
# Parsování frontmatteru je výhradně v _lore-parse-common.sh (I4 — jeden parser).
set -euo pipefail

LORE_ROOT="${HOME}/.lore"

if [[ ! -d "$LORE_ROOT" ]]; then
  echo "CHYBA: ${LORE_ROOT} neexistuje." >&2
  exit 2
fi

source "$(dirname "$0")/_lore-parse-common.sh"

DANGLING=0
DANGLING_REPORT=""

# Projdi všechny záznamy a jejich related:/lessons: reference (lib zajišťuje
# vyloučení _template.md, _schema.yml, drafts/ atd. — viz lore_find_records).
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  while IFS=$'\t' read -r field ref; do
    [[ -z "$ref" ]] && continue

    target="$(resolve_target "$ref")"
    if [[ ! -f "$target" ]]; then
      DANGLING=$((DANGLING + 1))
      DANGLING_REPORT="${DANGLING_REPORT}${file} → ${ref}\n"
    fi
  done < <(emit_refs "$file")

done < <(lore_find_records "$LORE_ROOT")

if [[ $DANGLING -eq 0 ]]; then
  echo "lore: 0 dangling refs"
  echo "Všechny cross-reference záznamy jsou validní."
  exit 0
else
  echo "lore audit: nalezeny dangling refs"
  echo ""
  printf "%-60s → %s\n" "Zdroj" "Chybějící cíl"
  printf "%-60s\n" "$(printf '%0.s-' {1..80})"
  printf "%b" "$DANGLING_REPORT"
  echo ""
  echo "Celkem: ${DANGLING} dangling refs"
  exit 1
fi
