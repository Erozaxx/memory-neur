#!/usr/bin/env bash
# lore-map-precommit.sh — regeneruje mapu paměti PŘED commitem do ~/.lore/
#
# Instaluje se jako ~/.lore/.git/hooks/pre-commit-user (viz Makefile target
# install-skills). Chain shim ~/.lore/.git/hooks/pre-commit ho volá AŽ PO
# binárčině enforcement hooku (pre-commit-impl.sh) — pokud enforcement
# selže, tento skript se vůbec nespustí.
#
# KONTRAKT (viz brief T-016 / iter-006):
#   - NIKDY neblokuje commit. Chybějící/rozbitý generátor -> hlasité varování
#     + exit 0. Konzistentní s /lore new (N-7.5) a /lore link (L-9), kde
#     selhání regenu mapy taky nikdy neblokuje zápis do paměti.
#   - NIKDY `git add -A` — pouze `git add map/graph.json map/index.html`
#     (jmenovitě, RC1/iter-006). ~/.lore/ může mít necommitnuté změny
#     uživatele mimo map/ a hook je nesmí nastageovat; jmenovitý add navíc
#     nikdy nestagne uniklý temp soubor generátoru (viz níže).
#   - NIKDY `git commit` uvnitř hooku (nekonečná smyčka).

LORE_DIR="${LORE_PATH:-$HOME/.lore}"
GENERATOR="$LORE_DIR/scripts/lore-map-gen.sh"

if [ ! -f "$GENERATOR" ]; then
  echo "[lore-map-precommit] WARN: generátor mapy nenalezen ($GENERATOR) — regen přeskočen, commit pokračuje." >&2
  exit 0
fi

if ! bash "$GENERATOR" "$LORE_DIR"; then
  echo "[lore-map-precommit] WARN: regenerace mapy SELHALA — commit pokračuje BEZ aktualizace mapy." >&2
  echo "[lore-map-precommit] Zkontroluj ručně: bash $GENERATOR $LORE_DIR" >&2
  exit 0
fi

# Jen mapa — nikdy -A (necommitnuté změny uživatele mimo map/ musí zůstat netknuté).
# JMENOVITĚ (RC1/iter-006): generátor legitimně produkuje jen tyhle dva soubory.
# `git add map/` (celý adresář) by nastageoval i uniklý temp soubor generátoru
# (mktemp v map/, trap EXIT nekryje SIGKILL) — binární smetí do paměti uživatele.
if ! git -C "$LORE_DIR" add map/graph.json map/index.html 2>/dev/null; then
  echo "[lore-map-precommit] WARN: 'git add map/graph.json map/index.html' selhalo — mapa nebyla nastageována do commitu." >&2
fi

exit 0
