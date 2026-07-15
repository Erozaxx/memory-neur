#!/usr/bin/env bash
# lore-map-gen.sh — generuje ~/.lore/map/graph.json + map/index.html z ~/.lore/ frontmatteru
# Použití: bash lore-map-gen.sh [lore_root]   (lore_root default: $HOME/.lore)
# Exit kódy: 0 = OK; 2 = lore_root neexistuje; 3 = template nenalezen
#   (exit 3 nastává PŘED jakýmkoli zápisem — nikdy se nezapíše poloviční index.html)
#
# Parsování frontmatteru pro seznam záznamů (lore_find_records) je v
# _lore-parse-common.sh (I4 — jeden parser). Samotná EXTRAKCE polí (title/
# date/tags/frontmatter/refs) a JSON emise běží v JEDNÉM awk průchodu níže
# (RC2/iter-006) — logika je 1:1 port _lore-parse-common.sh funkcí
# (lore_get_title/lore_get_scalar/lore_get_tags/emit_refs/normalize_ref),
# jen bez forku na každé pole/soubor. Signatury knihovny se NEMĚNÍ (audit
# skript ji dál sourcuje beze změny).
# Zero-dependency: žádné yq/jq/python v běhu skriptu (I3).
set -euo pipefail

LORE_ROOT="${1:-$HOME/.lore}"

if [[ ! -d "$LORE_ROOT" ]]; then
  echo "CHYBA: ${LORE_ROOT} neexistuje." >&2
  exit 2
fi

SCRIPT_DIR="$(dirname "$0")"
TEMPLATE="$SCRIPT_DIR/lore-map-template.html"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "CHYBA: template nenalezen: $TEMPLATE" >&2
  exit 3
fi

source "$SCRIPT_DIR/_lore-parse-common.sh"

# json_escape — ověřená funkce (impl-decomposition_T-004b_iter-006.md §9.2).
# Pořadí je pevně dané: backslash MUSÍ jít první, jinak vznikne dvojité escapování.
# Nastavuje JSON_ESC (žádný $(...) fork — voláno stovkykrát, fork by opět
# rozbil RC2). Ekvivalentní awk funkce (stejné pořadí, stejný výstup) běží
# uvnitř GEN_AWK níže pro pole frontmatteru/title/tags — obojí ověřeno
# byte-identické (viz handoff).
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"        # 1) BACKSLASH VŽDY PRVNÍ
  s="${s//\"/\\\"}"        # 2) uvozovka
  s="${s//</\\u003c}"      # 3) < → <  (kryje </script> i <!--)
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/}"
  JSON_ESC="$s"
}

mkdir -p "$LORE_ROOT/map"

# RC1 — uklid uniklé temp soubory předchozích běhů (SIGKILL/OOM/zabitý
# terminál obejde `trap ... EXIT` níže a temp zůstane ležet v map/, odkud by
# ho `git add map/graph.json map/index.html` sice už nesebral jmenovitě, ale
# stará cesta `git add map/` by ho stagnula tiše do paměti uživatele).
rm -f "$LORE_ROOT"/map/.graph.json.* "$LORE_ROOT"/map/.index.html.*

TMP_JSON=""
TMP_HTML=""
cleanup() {
  [[ -n "$TMP_JSON" && -f "$TMP_JSON" ]] && rm -f "$TMP_JSON"
  [[ -n "$TMP_HTML" && -f "$TMP_HTML" ]] && rm -f "$TMP_HTML"
  return 0
}
trap cleanup EXIT

# --- Fáze 1: kanonický seznam záznamů (skutečné uzly) ---
mapfile -t RECORD_FILES < <(lore_find_records "$LORE_ROOT")
RECORD_COUNT=${#RECORD_FILES[@]}

# --- Fáze 2+3: JEDEN awk průchod přes všechny záznamy ---
# Pro každý soubor: parsuje frontmatter (title/date/tags/celý frontmatter
# jako pole řádků) + related:/lessons:/instances: hrany. Emituje na stdout:
#   N<TAB>id<TAB>part1<TAB>frontmatter_json   (jeden řádek na ZÁZNAM)
#   R<TAB>src_id<TAB>field<TAB>target_id      (jeden řádek na HRANU)
# part1/frontmatter_json mají vnitřní \n nahrazené \x1f (0x1f), aby řádek
# zůstal jednořádkový pro `mapfile` níže — bash je při skládání převede zpět.
# Všechny "N" řádky jdou PŘED všemi "R" řádky (viz komentář u emit_refs_for
# v GEN_AWK) — hrana může mířit na soubor zpracovaný POZDĚJI v ARGV pořadí;
# kdyby "R" řádek přišel dřív než "N" řádek cíle, bash konzument by uzel
# mylně považoval za ghost a při příchodu skutečného "N" řádku by mu smazal
# už napočítaný degree.
GEN_AWK='
BEGIN {
  ENC = "\037"
  SQ = sprintf("%c", 39)
}

function json_escape(s) {
  gsub(/\\/, "\\\\", s)
  gsub(/"/, "\\\"", s)
  gsub(/</, "\\u003c", s)
  gsub(/\t/, "\\t", s)
  gsub(/\r/, "", s)
  return s
}

function strip_wrap_quotes(val,   n) {
  n = length(val)
  if (n >= 2 && substr(val,1,1) == "\"" && substr(val,n,1) == "\"") {
    return substr(val, 2, n-2)
  }
  if (n >= 2 && substr(val,1,1) == SQ && substr(val,n,1) == SQ) {
    return substr(val, 2, n-2)
  }
  return val
}

function get_scalar_fm(key,   i, line, val, pat) {
  pat = key ":"
  for (i = 1; i <= fm_n; i++) {
    line = fm[i]
    if (substr(line, 1, length(pat)) == pat) {
      val = line
      sub("^" key ":[ \t]*", "", val)
      sub("[ \t]+#.*$", "", val)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      return val
    }
  }
  return ""
}

function extract_tags(   val, inner, tmp, i, n, items, item, out_n, line, in_block, s2) {
  val = strip_wrap_quotes(get_scalar_fm("tags"))
  if (length(val) >= 2 && substr(val,1,1) == "[" && substr(val, length(val), 1) == "]") {
    inner = substr(val, 2, length(val)-2)
    tmp = inner
    gsub(/[[:space:]]/, "", tmp)
    out_n = 0
    if (tmp != "") {
      n = split(inner, items, ",")
      for (i = 1; i <= n; i++) {
        item = items[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
        gsub(/"/, "", item)
        gsub(SQ, "", item)
        if (item != "") {
          out_n++
          TAGS[out_n] = item
        }
      }
    }
    return out_n
  }
  out_n = 0
  in_block = 0
  for (i = 1; i <= fm_n; i++) {
    line = fm[i]
    if (in_block == 0) {
      if (line ~ /^tags:[[:space:]]*$/) in_block = 1
    } else {
      if (line ~ /^[[:space:]]+-[[:space:]]+/) {
        s2 = line
        sub(/^[[:space:]]+-[[:space:]]+/, "", s2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", s2)
        gsub(/"/, "", s2)
        gsub(SQ, "", s2)
        out_n++
        TAGS[out_n] = s2
      } else if (line ~ /^[^[:space:]#]/) {
        break
      }
    }
  }
  return out_n
}

function normalize_ref(r) {
  gsub(/"/, "", r)
  gsub(SQ, "", r)
  if (substr(r,1,5) == "lore/") r = substr(r,6)
  if (length(r) >= 3 && substr(r, length(r)-2) == ".md") r = substr(r, 1, length(r)-3)
  return r
}

function emit_refs_for(id,   i, line, in_r, in_l, in_i, ref, field) {
  in_r = 0; in_l = 0; in_i = 0
  for (i = 1; i <= fm_n; i++) {
    line = fm[i]
    if (line ~ /^related:[[:space:]]*$/) { in_r=1; in_l=0; in_i=0; continue }
    if (line ~ /^lessons:[[:space:]]*$/) { in_l=1; in_r=0; in_i=0; continue }
    if (line ~ /^instances:[[:space:]]*$/) { in_i=1; in_r=0; in_l=0; continue }
    if (line ~ /^[a-zA-Z_]+:/ && line !~ /^[[:space:]]/) { in_r=0; in_l=0; in_i=0 }
    if ((in_r || in_l || in_i) && line ~ /^[[:space:]]+-[[:space:]]+/) {
      ref = line
      sub(/^[[:space:]]+-[[:space:]]+/, "", ref)
      ref = normalize_ref(ref)
      if (ref == "") continue
      if (in_r) field = "related"
      else if (in_l) field = "lessons"
      else field = "instances"
      ref_n++
      REF_ID[ref_n] = id
      REF_FIELD[ref_n] = field
      REF_TGT[ref_n] = ref
    }
  }
}

function compute_id(fname,   id, lrlen) {
  lrlen = length(lore_root)
  id = fname
  if (substr(id, 1, lrlen+1) == lore_root "/") {
    id = substr(id, lrlen+2)
  }
  sub(/\.md$/, "", id)
  return id
}

function finalize_file(   title, type, slug, path, part1, fmfrag, i, sep) {
  if (cur_id == "") return

  type = cur_id; sub(/\/.*$/, "", type)
  slug = cur_id; sub(/^.*\//, "", slug)
  path = cur_id ".md"

  if (title_scalar != "") title = title_scalar
  else if (heading_found) title = heading_text
  else title = slug

  part1 = "    {\n"
  part1 = part1 "      \"id\": \"" json_escape(cur_id) "\",\n"
  part1 = part1 "      \"type\": \"" json_escape(type) "\",\n"
  part1 = part1 "      \"slug\": \"" json_escape(slug) "\",\n"
  part1 = part1 "      \"title\": \"" json_escape(title) "\",\n"
  if (date_scalar != "") {
    part1 = part1 "      \"date\": \"" json_escape(date_scalar) "\",\n"
  }
  if (tags_n == 0) {
    part1 = part1 "      \"tags\": [],\n"
  } else {
    part1 = part1 "      \"tags\": [\n"
    for (i = 1; i <= tags_n; i++) {
      sep = (i < tags_n) ? "," : ""
      part1 = part1 "        \"" json_escape(TAGS[i]) "\"" sep "\n"
    }
    part1 = part1 "      ],\n"
  }
  part1 = part1 "      \"path\": \"" json_escape(path) "\",\n"

  if (fm_n == 0) {
    fmfrag = "      \"frontmatter\": [],\n"
  } else {
    fmfrag = "      \"frontmatter\": [\n"
    for (i = 1; i <= fm_n; i++) {
      sep = (i < fm_n) ? "," : ""
      fmfrag = fmfrag "        \"" json_escape(fm[i]) "\"" sep "\n"
    }
    fmfrag = fmfrag "      ],\n"
  }

  gsub(/\n/, ENC, part1)
  gsub(/\n/, ENC, fmfrag)

  print "N\t" cur_id "\t" part1 "\t" fmfrag
}

FNR == 1 {
  if (NR > 1) { finalize_file() }
  cur_id = compute_id(FILENAME)
  s = 0
  fm_n = 0
  delete fm
  title_scalar = ""
  date_scalar = ""
  tags_n = 0
  delete TAGS
  heading_found = 0
  heading_text = ""
}

{
  line = $0
  if (line ~ /^---[[:space:]]*$/) {
    if (s == 0) { s = 1; next }
    else if (s == 1) {
      s = 2
      title_scalar = strip_wrap_quotes(get_scalar_fm("title"))
      date_scalar = strip_wrap_quotes(get_scalar_fm("date"))
      tags_n = extract_tags()
      emit_refs_for(cur_id)
      next
    }
    else { next }
  } else {
    if (s == 1) {
      fm_n++
      fm[fm_n] = line
    } else if (s == 2) {
      if (!heading_found && line ~ /^#[[:space:]]+/) {
        heading_found = 1
        heading_text = line
        sub(/^#[[:space:]]+/, "", heading_text)
      }
    }
  }
}

END {
  finalize_file()
  for (ri = 1; ri <= ref_n; ri++) {
    print "R\t" REF_ID[ri] "\t" REF_FIELD[ri] "\t" REF_TGT[ri]
  }
}
'

declare -A IS_REAL=()
declare -A NODE_IS_GHOST=()
declare -A NODE_DEGREE=()
declare -A NODE_PART1=()
declare -A NODE_FM=()
EDGE_LINES=()
GHOST_COUNT=0
DANGLING_COUNT=0

if [[ "$RECORD_COUNT" -gt 0 ]]; then
  while IFS=$'\t' read -r marker fa fb fc; do
    if [[ "$marker" == "N" ]]; then
      IS_REAL["$fa"]=1
      NODE_IS_GHOST["$fa"]=0
      NODE_DEGREE["$fa"]=0
      NODE_PART1["$fa"]="$fb"
      NODE_FM["$fa"]="$fc"
    elif [[ "$marker" == "R" ]]; then
      src_id="$fa"; field="$fb"; tgt_id="$fc"

      if [[ -z "${NODE_IS_GHOST[$tgt_id]:-}" ]]; then
        NODE_IS_GHOST["$tgt_id"]=1
        NODE_DEGREE["$tgt_id"]=0
        GHOST_COUNT=$((GHOST_COUNT + 1))
      fi

      target_path="${LORE_ROOT}/${tgt_id}.md"
      if [[ -f "$target_path" ]]; then
        dangling="false"
      else
        dangling="true"
        DANGLING_COUNT=$((DANGLING_COUNT + 1))
      fi

      EDGE_LINES+=("${src_id}"$'\t'"${tgt_id}"$'\t'"${field}"$'\t'"${dangling}")

      NODE_DEGREE["$src_id"]=$(( ${NODE_DEGREE[$src_id]:-0} + 1 ))
      NODE_DEGREE["$tgt_id"]=$(( ${NODE_DEGREE[$tgt_id]:-0} + 1 ))
    fi
  done < <(awk -v lore_root="$LORE_ROOT" "$GEN_AWK" "${RECORD_FILES[@]}")
fi

EDGE_COUNT=${#EDGE_LINES[@]}

# --- Fáze 4: stabilní řazení (LC_ALL=C povinné — jinak locale rozbije idempotenci) ---
# Guard: prázdné asociativní pole by jinak přes `printf '%s\n'` bez argumentů
# vytisklo jeden prázdný řádek → ALL_IDS=("") → pád na "bad array subscript"
# (viz review_T-008_iter-006.md, BLOCKER RB1). Prázdná paměť musí dát prázdný graf.
ALL_IDS=()
if [[ ${#NODE_IS_GHOST[@]} -gt 0 ]]; then
  mapfile -t ALL_IDS < <(printf '%s\n' "${!NODE_IS_GHOST[@]}" | LC_ALL=C sort)
fi
NODE_COUNT=${#ALL_IDS[@]}

SORTED_EDGES=()
if [[ "$EDGE_COUNT" -gt 0 ]]; then
  mapfile -t SORTED_EDGES < <(printf '%s\n' "${EDGE_LINES[@]}" | LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3)
fi

# --- Emise graph.json (meta NEOBSAHUJE generated_at ani lore_root — I7) ---
TMP_JSON="$(mktemp "${LORE_ROOT}/map/.graph.json.XXXXXX")"

{
  printf '{\n'
  printf '  "meta": {\n'
  printf '    "schema": "lore-graph/1.0",\n'
  printf '    "generator_version": "1.0",\n'
  printf '    "node_count": %d,\n' "$NODE_COUNT"
  printf '    "record_count": %d,\n' "$RECORD_COUNT"
  printf '    "ghost_count": %d,\n' "$GHOST_COUNT"
  printf '    "edge_count": %d,\n' "$EDGE_COUNT"
  printf '    "dangling_count": %d\n' "$DANGLING_COUNT"
  printf '  },\n'

  printf '  "nodes": [\n'
  n_total=${#ALL_IDS[@]}
  n_idx=0
  for id in "${ALL_IDS[@]}"; do
    n_idx=$((n_idx + 1))
    degree="${NODE_DEGREE[$id]:-0}"

    if [[ "${IS_REAL[$id]:-0}" == "1" ]]; then
      # part1 (id..path) a frontmatter blok už přišly z awk plně escapované
      # a naformátované — \x1f (0x1f) uvnitř je zpět zakódovaný skutečný
      # newline (aby "N" řádek zůstal jednořádkový pro mapfile výše).
      part1="${NODE_PART1[$id]//$'\037'/$'\n'}"
      fmfrag="${NODE_FM[$id]//$'\037'/$'\n'}"
      printf '%s' "$part1"
      printf '      "degree": %d,\n' "$degree"
      printf '%s' "$fmfrag"
      printf '      "ghost": false\n'
    else
      # Ghost uzel — vznikl jen jako cíl hrany, soubor pro něj neexistuje
      # jako záznam. Pole odvozená čistě z id (bez forků — parameter
      # expansion), json_escape volaný přímo (ne přes $(...)).
      type="${id%%/*}"
      slug="${id##*/}"
      path="${id}.md"
      json_escape "$id"; id_e="$JSON_ESC"
      json_escape "$type"; type_e="$JSON_ESC"
      json_escape "$slug"; slug_e="$JSON_ESC"
      json_escape "$path"; path_e="$JSON_ESC"
      printf '    {\n'
      printf '      "id": "%s",\n' "$id_e"
      printf '      "type": "%s",\n' "$type_e"
      printf '      "slug": "%s",\n' "$slug_e"
      printf '      "title": "%s",\n' "$slug_e"
      printf '      "tags": [],\n'
      printf '      "path": "%s",\n' "$path_e"
      printf '      "degree": %d,\n' "$degree"
      printf '      "ghost": true\n'
    fi

    if [[ "$n_idx" -lt "$n_total" ]]; then
      printf '    },\n'
    else
      printf '    }\n'
    fi
  done
  printf '  ],\n'

  printf '  "edges": [\n'
  e_total=${#SORTED_EDGES[@]}
  e_idx=0
  for line in "${SORTED_EDGES[@]}"; do
    e_idx=$((e_idx + 1))
    IFS=$'\t' read -r esrc etgt efield edangling <<< "$line"
    json_escape "$esrc"; esrc_e="$JSON_ESC"
    json_escape "$etgt"; etgt_e="$JSON_ESC"
    json_escape "$efield"; efield_e="$JSON_ESC"
    printf '    {\n'
    printf '      "source": "%s",\n' "$esrc_e"
    printf '      "target": "%s",\n' "$etgt_e"
    printf '      "field": "%s",\n' "$efield_e"
    printf '      "dangling": %s\n' "$edangling"
    if [[ "$e_idx" -lt "$e_total" ]]; then
      printf '    },\n'
    else
      printf '    }\n'
    fi
  done
  printf '  ]\n'
  printf '}\n'
} > "$TMP_JSON"

mv "$TMP_JSON" "$LORE_ROOT/map/graph.json"
TMP_JSON=""

# --- Injekce do index.html — ověřená technika (impl-decomposition_T-004b_iter-006.md §9.3) ---
TMP_HTML="$(mktemp "${LORE_ROOT}/map/.index.html.XXXXXX")"

awk -v jf="$LORE_ROOT/map/graph.json" '
  /^\/\*__LORE_GRAPH__\*\/$/ { while ((getline line < jf) > 0) print line; close(jf); next }
  { print }
' "$TEMPLATE" > "$TMP_HTML"

mv "$TMP_HTML" "$LORE_ROOT/map/index.html"
TMP_HTML=""

printf 'lore map: %d nodes, %d edges, %d dangling\n' "$NODE_COUNT" "$EDGE_COUNT" "$DANGLING_COUNT"
exit 0
