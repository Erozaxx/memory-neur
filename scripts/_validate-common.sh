#!/usr/bin/env bash
# _validate-common.sh — sdílená bash knihovna pro per-type validátory
# Načítej přes: source "$(dirname "$0")/_validate-common.sh"
# Nepoužívej přímo — žádný vlastní main().
#
# Závislosti: bash, awk, grep (žádné yq, jq, python)
# Verze: 1.0

# --- Konstanty ---
DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
SCHEMA_VERSION_RE='^[0-9]+\.[0-9]+$'

# --- Globální stav ---
# Volající skript musí inicializovat: errors=0 warnings=0 fm=""
# Tyto funkce inkrementují errors/warnings v kontextu volajícího.

err()  { echo "ERROR: $1"; errors=$((errors + 1)); }
warn() { echo "WARN:  $1"; warnings=$((warnings + 1)); }

# extract_frontmatter <soubor>
# Vypíše frontmatter (bez ohraničujících ---) na stdout.
# Vrátí prázdný string pokud frontmatter chybí.
extract_frontmatter() {
  local file="$1"
  awk '
    BEGIN { state = 0 }
    /^---[[:space:]]*$/ {
      if (state == 0) { state = 1; next }
      if (state == 1) { state = 2; exit }
    }
    state == 1 { print }
  ' "$file"
}

# get_scalar <klíč>
# Čte z proměnné $fm (musí být nastavena volajícím).
# Vrátí hodnotu "klíč: hodnota" bez komentářů a okolního whitespace.
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

# has_key <klíč>
# Vrátí 0 (true) pokud klíč existuje ve frontmatteru $fm.
has_key() {
  printf '%s\n' "$fm" | grep -qE "^$1:([[:space:]]|$)"
}

# count_block_items <klíč>
# Spočítá položky YAML block listu pod klíčem (řádky "  - hodnota").
count_block_items() {
  printf '%s\n' "$fm" | awk -v k="$1" '
    $0 ~ "^"k":[ \t]*$" { in_block = 1; next }
    in_block && /^[ \t]+-[ \t]+/ { count++; next }
    in_block && /^[^ \t#]/ { exit }
    END { print count + 0 }'
}

# count_inline_items <klíč>
# Spočítá položky inline listu "key: [a, b, c]". Vrátí 0 pokud není inline list.
count_inline_items() {
  local val
  val=$(get_scalar "$1")
  [[ "$val" =~ ^\[(.*)\]$ ]] || { echo 0; return; }
  local inner=${BASH_REMATCH[1]}
  inner=${inner//[[:space:]]/}
  [[ -z "$inner" ]] && { echo 0; return; }
  awk -F',' '{ print NF }' <<<"$inner"
}

# count_list_items <klíč>
# Kombinuje block + inline počítání (pro tags, related apod.)
count_list_items() {
  local inline block
  inline=$(count_inline_items "$1")
  block=$(count_block_items "$1")
  echo $((inline + block))
}

# check_date <klíč>
# Ověří přítomnost a formát YYYY-MM-DD pole. Používá globální $fm, err().
check_date() {
  local key="${1:-date}"
  if ! has_key "$key"; then
    err "chybí povinné pole '$key'"
  else
    local val
    val=$(get_scalar "$key")
    if [[ ! "$val" =~ $DATE_RE ]]; then
      err "pole '$key' nemá formát YYYY-MM-DD: '$val'"
    fi
  fi
}

# check_enum <klíč> <povolené hodnoty oddělené mezerou>
# Ověří že hodnota pole je v povolené množině.
check_enum() {
  local key="$1"
  shift
  local allowed=("$@")
  if ! has_key "$key"; then
    err "chybí povinné pole '$key'"
  else
    local val
    val=$(get_scalar "$key")
    local ok=0
    for t in "${allowed[@]}"; do
      [[ "$val" == "$t" ]] && ok=1 && break
    done
    if [[ $ok -eq 0 ]]; then
      err "pole '$key' má nepovolenou hodnotu '$val' (povolené: ${allowed[*]})"
    fi
  fi
}

# check_tags
# Ověří přítomnost a min. 1 položku v poli tags. Používá globální $fm.
check_tags() {
  if ! has_key "tags"; then
    err "chybí povinné pole 'tags'"
  else
    local total
    total=$(count_list_items "tags")
    if [[ $total -lt 1 ]]; then
      err "pole 'tags' je prázdné — vyžadována alespoň 1 položka"
    fi
  fi
}

# check_schema_version
# Ověří přítomnost schema_version. Pokud chybí: WARNING (exit 0), ne error.
check_schema_version() {
  if ! has_key "schema_version"; then
    warn "pole 'schema_version' chybí — defaultuje na '1.0' (přidej pro explicitnost)"
  else
    local val
    val=$(get_scalar "schema_version")
    # Odstraň uvozovky pokud jsou přítomny
    val="${val//\"/}"
    val="${val//\'/}"
    if [[ ! "$val" =~ $SCHEMA_VERSION_RE ]]; then
      err "pole 'schema_version' nemá formát MAJOR.MINOR: '$val'"
    fi
  fi
}

# check_status <povolené hodnoty...>
# Ověří povinné pole status s danými enum hodnotami.
check_status() {
  check_enum "status" "$@"
}

# is_internal_file <basename>
# Vrátí 0 (true) pokud soubor je interní (_*.md, _*.yml).
is_internal_file() {
  local base="$1"
  [[ "$base" == _* ]]
}
