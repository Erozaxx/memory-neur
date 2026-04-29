#!/usr/bin/env bash
# Validuje frontmatter lesson souboru proti lore/lessons/_schema.yml.
# Závislosti: bash, awk, grep — žádné yq, jq, python (přenositelné).
#
# Použití:
#   scripts/validate-lesson.sh <cesta-k-md-souboru>
#
# Exit kódy:
#   0  validní (nebo interní soubor _*.md/_*.yml přeskočen)
#   1  nevalidní (chyby na stdout)
#   2  špatné použití (chybí argument, soubor neexistuje)

set -u

ALLOWED_TYPES=("gotcha" "anti-pattern" "preference" "decision-minor" "heuristika" "principle")
ALLOWED_CONFIDENCE=("low" "medium" "high")
DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

usage() {
  echo "Použití: $0 <cesta-k-md-souboru>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
file=$1

if [[ ! -f "$file" ]]; then
  echo "ERROR: soubor neexistuje: $file" >&2
  exit 2
fi

# Interní soubory (schéma, šablona) validaci přeskakují.
base=$(basename "$file")
if [[ "$base" == _* ]]; then
  echo "INFO: $base je interní soubor, validace přeskočena"
  exit 0
fi

# Extrahuj frontmatter mezi prvními dvěma řádky tvaru ^---$.
fm=$(awk '
  BEGIN { state = 0 }
  /^---[[:space:]]*$/ {
    if (state == 0) { state = 1; next }
    if (state == 1) { state = 2; exit }
  }
  state == 1 { print }
' "$file")

errors=0
err() { echo "ERROR: $1"; errors=$((errors + 1)); }

if [[ -z "$fm" ]]; then
  err "frontmatter chybí (očekáváno mezi dvěma řádky '---' na začátku souboru)"
  echo "FAIL: $file ($errors chyb)"
  exit 1
fi

# Vrátí hodnotu skalárního pole "klíč: hodnota" (bez # komentáře a bez okolního whitespace).
get_scalar() {
  printf '%s\n' "$fm" | awk -v k="$1" '
    $0 ~ "^"k":" {
      sub("^"k":[ \t]*", "")
      sub("[ \t]+#.*$", "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      print
      exit
    }'
}

has_key() {
  printf '%s\n' "$fm" | grep -qE "^$1:([[:space:]]|$)"
}

# Spočítá položky YAML block listu pod klíčem (řádky začínající "  - ").
count_block_items() {
  printf '%s\n' "$fm" | awk -v k="$1" '
    $0 ~ "^"k":[ \t]*$" { in_block = 1; next }
    in_block && /^[ \t]+-[ \t]+/ { count++; next }
    in_block && /^[^ \t#]/ { exit }
    END { print count + 0 }'
}

# Spočítá položky inline listu "key: [a, b, c]". Vrací 0 pokud klíč není inline list.
count_inline_items() {
  local val
  val=$(get_scalar "$1")
  [[ "$val" =~ ^\[(.*)\]$ ]] || { echo 0; return; }
  local inner=${BASH_REMATCH[1]}
  inner=${inner//[[:space:]]/}
  [[ -z "$inner" ]] && { echo 0; return; }
  awk -F',' '{ print NF }' <<<"$inner"
}

# --- date ---
if ! has_key "date"; then
  err "chybí povinné pole 'date'"
else
  date_val=$(get_scalar "date")
  if [[ ! "$date_val" =~ $DATE_RE ]]; then
    err "pole 'date' nemá formát YYYY-MM-DD: '$date_val'"
  fi
fi

# --- type ---
if ! has_key "type"; then
  err "chybí povinné pole 'type'"
else
  type_val=$(get_scalar "type")
  ok=0
  for t in "${ALLOWED_TYPES[@]}"; do
    [[ "$type_val" == "$t" ]] && ok=1 && break
  done
  if [[ $ok -eq 0 ]]; then
    err "pole 'type' má nepovolenou hodnotu '$type_val' (povolené: ${ALLOWED_TYPES[*]})"
  fi
fi

# --- tags (povinné, min. 1 položka) ---
if ! has_key "tags"; then
  err "chybí povinné pole 'tags'"
else
  inline_count=$(count_inline_items "tags")
  block_count=$(count_block_items "tags")
  total=$((inline_count + block_count))
  if [[ $total -lt 1 ]]; then
    err "pole 'tags' je prázdné — vyžadována alespoň 1 položka"
  fi
fi

# --- confidence (volitelné, ale pokud existuje musí být enum) ---
if has_key "confidence"; then
  conf_val=$(get_scalar "confidence")
  ok=0
  for c in "${ALLOWED_CONFIDENCE[@]}"; do
    [[ "$conf_val" == "$c" ]] && ok=1 && break
  done
  if [[ $ok -eq 0 ]]; then
    err "pole 'confidence' má nepovolenou hodnotu '$conf_val' (povolené: ${ALLOWED_CONFIDENCE[*]})"
  fi
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: $file ($errors chyb)"
  exit 1
fi

echo "OK: $file"
exit 0
