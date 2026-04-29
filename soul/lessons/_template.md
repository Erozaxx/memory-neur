---
# POVINNÉ ---------------------------------------------------------------

# Datum zápisu lekce, ISO 8601 (YYYY-MM-DD).
date: YYYY-MM-DD

# Typ lekce. Přesně jedna hodnota z:
#   gotcha         technická past, nečekané chování systému
#   anti-pattern   postup vypadající rozumně, ale škodí
#   preference     subjektivní volba týmu (není absolutní pravda)
#   decision       vědomé rozhodnutí se zdůvodněním
#   heuristika     pravidlo palce (platí často, ne vždy)
type: gotcha

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# VOLITELNÉ -------------------------------------------------------------
# Smazat řádky, které nepoužíváš — žádné prázdné hodnoty.

# Subjektivní jistota: low | medium | high
# confidence: medium

# Související lekce (slug bez .md nebo relativní cesta).
# related:
#   - 2026-04-29-jiny-priklad

# 1–3 věty o tom, kde/jak lekce vznikla.
# context: Pozorováno při konsolidaci lessons_learned.md ze starých projektů.

# Projekt, ze kterého byla lekce konsolidována.
# source_project: nazev-projektu

# Lekce, které jsou v rozporu s touto.
# conflict:
#   - 2026-04-30-opacny-nazor

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
