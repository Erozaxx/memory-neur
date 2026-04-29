---
# POVINNÉ ---------------------------------------------------------------

# Datum přijetí rozhodnutí (ISO 8601).
date: YYYY-MM-DD

# Doména rozhodnutí. Přesně jedna hodnota z:
#   architecture   strukturní rozhodnutí o systému, technologiích
#   product        feature scope, prioritizace, produktová strategie
#   process        způsob práce, workflow, postup
#   tooling        volba nástroje, knihovny, platformy
#   policy         pravidlo nebo konvence platná pro tým
type: architecture

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# Verze schématu. Neměň — aktuální hodnota je "1.0".
schema_version: "1.0"

# Stav rozhodnutí:
#   proposed     čeká na schválení / diskuzi
#   active       platné a v platnosti
#   superseded   nahrazeno jiným (viz superseded_by)
#   deprecated   zastaralé bez nástupce
status: proposed

# VOLITELNÉ -------------------------------------------------------------
# Smazat řádky, které nepoužíváš — žádné prázdné hodnoty.

# Lidsky čitelný název.
# title: Název rozhodnutí

# Shrnutí do 500 znaků.
# summary: Co bylo rozhodnuto a proč.

# Proč bylo rozhodnutí potřeba (situace, problém, tlak).
# context: Popis kontextu, který vedl k rozhodnutí.

# Zvažované alternativy (volný text, jedna per řádek).
# options:
#   - Alternativa A — popis
#   - Alternativa B — popis

# Proč tato volba oproti alternativám.
# rationale: Zdůvodnění výběru.

# Dopad rozhodnutí — co se změní, co se přijme jako trade-off.
# consequences: Popis dopadů.

# Projekt, kde rozhodnutí vzniklo.
# source_project: nazev-projektu

# Záznamy v rozporu s tímto rozhodnutím.
# conflict:
#   - lore/decisions/2026-04-29-jine-rozhodnutí

# Stav konfliktu (jen pokud je vyplněno conflict):
#   open | acknowledged | resolved | superseded
# conflict_status: open

# Záznam, který konflikt uzavřel.
# resolved_by: lore/decisions/2026-05-01-konflikt-uzavren

# Autor zápisu.
# author: claude-code

# true = zastaralý záznam (nesmazat).
# deprecated: true

# Nástupce (jen pokud status: superseded).
# superseded_by: lore/decisions/2026-05-01-novejsi-rozhodnutí
---

# Název rozhodnutí v jedné větě

## Kontext

Proč bylo rozhodnutí potřeba. 2–5 vět o situaci, problému nebo tlaku.

## Rozhodnutí

Co bylo rozhodnuto. 1–3 věty — konkrétní a jednoznačné.

## Alternativy

- **Alternativa A**: popis — proč nebyla zvolena
- **Alternativa B**: popis — proč nebyla zvolena

## Důsledky

Co se změní. Přijaté trade-offy. 2–4 věty.

Název souboru: `YYYY-MM-DD-<slug>.md`, kde slug popisuje jádro rozhodnutí.
