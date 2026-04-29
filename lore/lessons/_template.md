---
# POVINNÉ ---------------------------------------------------------------

# Datum zápisu lekce, ISO 8601 (YYYY-MM-DD).
date: YYYY-MM-DD

# Typ lekce. Přesně jedna hodnota z:
#   gotcha          technická past, nečekané chování systému
#   anti-pattern    postup vypadající rozumně, ale škodí
#   preference      subjektivní volba týmu (není absolutní pravda)
#   decision-minor  vědomé rozhodnutí BEZ alternativ a statusu
#                   → pro rozhodnutí s alternativami použij lore/decisions/
#   heuristika      pravidlo palce (platí často, ne vždy)
#   principle       trvalý axiom nebo heuristika (bez confidence pole)
type: gotcha

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# Verze schématu. Neměň — aktuální hodnota je "1.0".
schema_version: "1.0"

# VOLITELNÉ -------------------------------------------------------------
# Smazat řádky, které nepoužíváš — žádné prázdné hodnoty.

# Lidsky čitelný název lekce.
# title: Krátký popis

# Shrnutí do 500 znaků.
# summary: Co se stalo a proč to záleží.

# Subjektivní jistota: low | medium | high
# (Nepoužívat pro type: principle — principy jsou axiomy)
# confidence: medium

# Projekt, kde lekce vznikla (provenance).
# source_project: nazev-projektu

# Projekty, kde je lekce relevantní (může být víc).
# projects:
#   - lore/projects/nazev-projektu

# Související záznamy (kanonický formát: lore/<type>/<slug>).
# related:
#   - lore/lessons/2026-04-29-jiny-priklad
#   - lore/decisions/2026-04-29-nejaké-rozhodnutí

# Záznamy v rozporu s touto lekcí.
# conflict:
#   - lore/lessons/2026-04-30-opacny-nazor

# Stav konfliktu (jen pokud je vyplněno conflict):
#   open | acknowledged | resolved | superseded
# conflict_status: open

# true = záznam zastaralý (nesmazat).
# deprecated: true

# Nástupce tohoto záznamu (formát: lore/<type>/<slug>).
# superseded_by: lore/lessons/2026-05-01-novejsi-pohled

# Autor zápisu — jméno člověka nebo identifikátor agenta.
# author: claude-code
---

# Krátký nadpis lekce v jedné větě

Tělo lekce: 3–7 řádků prózy. Co se stalo / co platí, proč na tom záleží,
co s tím napříště dělat. Bez bulletpointů, pokud to není nezbytné.
Pokud potřebuješ delší rozbor, je to znamení, že lekci máš rozdělit
na víc atomických.

Název souboru: `YYYY-MM-DD-<slug>.md`, kde `<slug>` je 3–6 slov v
kebab-case popisujících jádro lekce.
