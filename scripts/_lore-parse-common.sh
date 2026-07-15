#!/usr/bin/env bash
# _lore-parse-common.sh — sdílená bash knihovna pro parsování ~/.lore/ frontmatteru
# Načítej přes: source "$(dirname "$0")/_lore-parse-common.sh"
# Nepoužívej přímo — žádný vlastní main(), soubor při načtení nic nedělá.
#
# Volající MUSÍ před voláním funkcí nastavit globální proměnnou LORE_ROOT
# (používá ji resolve_target()).
#
# Závislosti: bash, awk, find, sort, grep (žádné yq, jq, python)
# Verze: 1.0
#
# DŮLEŽITÉ: Tento soubor NIKDY nesmí nastavit set -e / set -u / set -o pipefail —
# je to sourcovaná knihovna, nastavení by prosáklo do volajícího skriptu a změnilo
# by mu chování. Každá funkce se snaží končit úspěšným příkazem (return 0), aby
# volající se `set -e` nespadl na neúspěšném [[ ]] / grep uvnitř funkce.
#
# LIMITACE (vědomé, MVP):
#   - emit_refs() parsuje POUZE block-list formu:
#         related:
#           - lessons/foo
#     Inline formu `related: [a, b]` (i pro lessons:/instances:) TIŠE IGNORUJE.
#     V reálných datech (2026-07-12) je 1 výskyt inline listu, a to v
#     intel-pass/drafts/ (vyloučeno filtrem lore_find_records) → reálný dopad 0.
#     Rozšíření na inline listy je extension point, ne MVP.
#   - Parsuje pouze YAML frontmatter (mezi prvním a druhým řádkem '---'), ne tělo
#     záznamu — výjimka: lore_get_title() smí nahlédnout do těla, ale jen jako
#     fallback na první markdown nadpis `# ...`.
#   - emit_refs() čte related:/lessons:/instances: (hrany grafu). Pole mimo tuto
#     trojici (source_records:, projects:, tags:, ...) se pro hrany nečtou vůbec —
#     tags: má vlastní čtečku lore_get_tags(), ne emit_refs(). source_records:
#     (2026-07-12: 50 refs, výhradně nositelé v intel-pass/drafts/, které
#     lore_find_records vylučuje) se VĚDOMĚ nečte — přineslo by 0 hran, jen ghosty.
#   - lore_get_tags() na rozdíl od emit_refs() zvládá i inline formu `[a, b]`,
#     protože se používá jen pro zobrazení v generátoru, ne pro hrany grafu.

# --- interní pomocná funkce (není součástí veřejného kontraktu) ---

# _lore_frontmatter <soubor>
# Vypíše na stdout obsah YAML frontmatteru (mezi prvním a druhým řádkem '---'),
# bez ohraničujících '---'. Tělo záznamu za druhým '---' se neparsuje.
_lore_frontmatter() {
  awk '
    BEGIN { s = 0 }
    /^---[[:space:]]*$/ {
      if (s == 0) { s = 1; next }
      if (s == 1) { s = 2; exit }
    }
    s == 1 { print }
  ' "$1"
  return 0
}

# --- veřejné funkce (kontrakt T-005a — signatury se nesmí měnit) ---

# lore_find_records <lore_root>
# Na stdout: absolutní cesty ke všem ZÁZNAMŮM, 1/řádek, LC_ALL=C sort.
# Kanonický find — jediné místo, kde je definováno "co je záznam".
# Vylučuje: _template.md, _schema.yml, */.git/*, */scripts/*, */map/*, */drafts/*
# (block i top-level drafts/).
lore_find_records() {
  find "$1" -type f -name '*.md' \
    ! -name '_template.md' ! -name '_schema.yml' \
    ! -path '*/.git/*' ! -path '*/scripts/*' ! -path '*/map/*' \
    ! -path '*/drafts/*' 2>/dev/null | LC_ALL=C sort
  return 0
}

# normalize_ref <raw_ref>
# Na stdout: kanonické id. Pořadí kroků (pevně dané, NEMĚNIT):
#   1) strip uvozovek (" i ')
#   2) strip legacy prefixu "lore/"
#   3) strip JEDNÉ koncovky ".md"   ← oprava .md-append bugu dnešního auditu
normalize_ref() {
  local r="$1"
  r="${r//\"/}"; r="${r//\'/}"   # 1) uvozovky
  r="${r#lore/}"                 # 2) legacy prefix
  r="${r%.md}"                   # 3) koncovka .md
  printf '%s\n' "$r"
  return 0
}

# emit_refs <soubor>
# Na stdout: řádky "field<TAB>id" pro každou položku v related:/lessons:/instances:.
# field ∈ {related, lessons, instances}. Detekuje POUZE block-list sekce (hlavička
# na vlastním řádku, ^related:[[:space:]]*$ / ^lessons:[[:space:]]*$ /
# ^instances:[[:space:]]*$) — inline `related: [a, b]` NEOTEVÍRÁ blok (viz LIMITACE
# v hlavičce). Jakýkoli další top-level klíč (tags:, source_records:, ...) sekci
# uzavírá, takže se z něj NIKDY neberou položky.
emit_refs() {
  local file="$1" in_r=false in_l=false in_i=false line ref
  while IFS= read -r line; do
    if [[ "$line" =~ ^related:[[:space:]]*$ ]]; then in_r=true;  in_l=false; in_i=false; continue; fi
    if [[ "$line" =~ ^lessons:[[:space:]]*$ ]]; then in_l=true;  in_r=false; in_i=false; continue; fi
    if [[ "$line" =~ ^instances:[[:space:]]*$ ]]; then in_i=true; in_r=false; in_l=false; continue; fi
    # jakýkoli top-level klíč zavírá blok
    if [[ "$line" =~ ^[a-zA-Z_]+: ]] && ! [[ "$line" =~ ^[[:space:]] ]]; then in_r=false; in_l=false; in_i=false; fi
    if ($in_r || $in_l || $in_i) && [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*)$ ]]; then
      ref="$(normalize_ref "${BASH_REMATCH[1]}")"
      [[ -z "$ref" ]] && continue
      if $in_r; then
        printf 'related\t%s\n' "$ref"
      elif $in_l; then
        printf 'lessons\t%s\n' "$ref"
      else
        printf 'instances\t%s\n' "$ref"
      fi
    fi
  done < <(_lore_frontmatter "$file")
  return 0
}

# resolve_target <id>
# Na stdout: absolutní cesta k .md souboru pro dané id.
# POZOR: čte globální proměnnou $LORE_ROOT nastavenou VOLAJÍCÍM — sama ji
# nenastavuje ani nevaliduje. Bez LORE_ROOT vrátí cestu s prázdným prefixem.
resolve_target() {
  printf '%s\n' "${LORE_ROOT}/$1.md"
  return 0
}

# node_id_from_path <lore_root> <abs_file>
# Na stdout: id (cesta relativní k lore_root, bez koncovky .md).
node_id_from_path() {
  local rel="${2#$1/}"
  printf '%s\n' "${rel%.md}"
  return 0
}

# lore_get_scalar <soubor> <klíč>
# Na stdout: hodnota skalárního pole z frontmatteru, bez uvozovek a bez
# koncového "# komentáře". Vzor podle get_scalar() v scripts/_validate-common.sh,
# navíc strip jedné dvojice obalujících uvozovek (title: bývá v uvozovkách a
# hodnota může obsahovat ':' — proto se NIKDY nepoužívá cut -d:).
# Prázdný string, pokud klíč ve frontmatteru chybí.
lore_get_scalar() {
  local file="$1" key="$2" val
  val="$(_lore_frontmatter "$file" | awk -v k="$key" '
    $0 ~ "^"k":" {
      sub("^"k":[ \t]*", "")
      sub("[ \t]+#.*$", "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      print
      exit
    }')"
  if [[ "$val" == \"*\" && "$val" == *\" ]]; then
    val="${val#\"}"
    val="${val%\"}"
  elif [[ "$val" == \'*\' && "$val" == *\' ]]; then
    val="${val#\'}"
    val="${val%\'}"
  fi
  printf '%s\n' "$val"
  return 0
}

# lore_get_title <soubor>
# Na stdout: titulek záznamu. Fallback pořadí: title: (frontmatter) → první
# markdown nadpis "# ..." v těle záznamu → slug odvozený z názvu souboru.
lore_get_title() {
  local file="$1" val

  val="$(lore_get_scalar "$file" "title")"
  if [[ -n "$val" ]]; then
    printf '%s\n' "$val"
    return 0
  fi

  val="$(awk '
    BEGIN { s = 0 }
    /^---[[:space:]]*$/ {
      if (s == 0) { s = 1; next }
      if (s == 1) { s = 2; next }
    }
    s == 2 && /^#[[:space:]]+/ {
      sub(/^#[[:space:]]+/, "")
      print
      exit
    }
  ' "$file")"
  if [[ -n "$val" ]]; then
    printf '%s\n' "$val"
    return 0
  fi

  val="$(basename "$file")"
  printf '%s\n' "${val%.md}"
  return 0
}

# lore_get_tags <soubor>
# Na stdout: 1 tag/řádek. Zvládá inline formu "tags: [a, b]" i block formu
#   tags:
#     - a
#     - b
# Uvozovky kolem jednotlivých hodnot se odstraní. Bez tags: nevypíše nic.
lore_get_tags() {
  local file="$1" val

  val="$(lore_get_scalar "$file" "tags")"
  if [[ "$val" == \[*\] ]]; then
    local inner="${val#\[}"
    inner="${inner%\]}"
    if [[ -n "${inner//[[:space:]]/}" ]]; then
      local item
      local IFS=','
      for item in $inner; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        item="${item//\"/}"
        item="${item//\'/}"
        [[ -n "$item" ]] && printf '%s\n' "$item"
      done
    fi
    return 0
  fi

  local line
  while IFS= read -r line; do
    line="${line//\"/}"
    line="${line//\'/}"
    printf '%s\n' "$line"
  done < <(_lore_frontmatter "$file" | awk '
    $0 ~ /^tags:[[:space:]]*$/ { in_block = 1; next }
    in_block && /^[[:space:]]+-[[:space:]]+/ {
      s = $0
      sub(/^[[:space:]]+-[[:space:]]+/, "", s)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      print s
      next
    }
    in_block && /^[^[:space:]#]/ { exit }
  ')
  return 0
}
