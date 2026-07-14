#!/usr/bin/env bash
# audit-dangling-refs.sh — Detekuje dangling cross-reference edges v ~/.lore/
# Výstup: 0 dangling refs = exit 0; nalezeny = exit 1
# Použití: bash audit-dangling-refs.sh
set -euo pipefail

LORE_DIR="${HOME}/.lore"

if [[ ! -d "$LORE_DIR" ]]; then
  echo "CHYBA: ${LORE_DIR} neexistuje." >&2
  exit 2
fi

DANGLING=0
DANGLING_REPORT=""

# Najdi všechny záznamy (kromě schémat a šablon)
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Extrahuj hodnoty z polí related: a lessons: (položky začínající "  - ")
  in_related=false
  in_lessons=false

  while IFS= read -r line; do
    # Detekuj začátek sekce
    if [[ "$line" =~ ^related: ]]; then
      in_related=true
      in_lessons=false
      continue
    fi
    if [[ "$line" =~ ^lessons: ]]; then
      in_lessons=true
      in_related=false
      continue
    fi
    # Konec YAML bloku (nová sekce nebo konec frontmatteru)
    if [[ "$line" =~ ^[a-zA-Z_]+: ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then
      in_related=false
      in_lessons=false
    fi
    # Zpracuj položku seznamu
    if ($in_related || $in_lessons) && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      ref="${BASH_REMATCH[1]}"
      ref="${ref//\"/}"  # odstraň uvozovky pokud jsou

      # Parsuj formát <type>/<slug> nebo holý slug
      if [[ "$ref" =~ ^lore/([^/]+)/(.+)$ ]]; then
        ref_type="${BASH_REMATCH[1]}"
        ref_slug="${BASH_REMATCH[2]}"
      elif [[ "$ref" =~ ^([^/]+)/(.+)$ ]]; then
        ref_type="${BASH_REMATCH[1]}"
        ref_slug="${BASH_REMATCH[2]}"
      else
        # Holý slug — přeskočit (nelze ověřit bez znalosti typu)
        continue
      fi

      target="${LORE_DIR}/${ref_type}/${ref_slug}.md"
      if [[ ! -f "$target" ]]; then
        DANGLING=$((DANGLING + 1))
        DANGLING_REPORT="${DANGLING_REPORT}${file} → ${ref_type}/${ref_slug}\n"
      fi
    fi
  done < <(sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | tail -n +2 | head -n -1)

done < <(find "$LORE_DIR" -name "*.md" ! -name "_template.md" ! -name "_schema.yml" 2>/dev/null)

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
