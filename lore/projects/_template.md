---
# POVINNÉ ---------------------------------------------------------------

# Datum zahájení nebo prvního záznamu projektu (ISO 8601).
date: YYYY-MM-DD

# Kategorie projektu. Přesně jedna hodnota z:
#   internal    interní projekt organizace nebo týmu
#   client      klientský projekt pro externího zákazníka
#   oss         open-source projekt
#   experiment  experimentální projekt, spike, PoC
type: internal

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# Verze schématu. Neměň — aktuální hodnota je "1.0".
schema_version: "1.0"

# Stav projektu:
#   active      projekt běží
#   paused      pozastaveno
#   completed   dokončeno
#   abandoned   zrušeno bez dokončení
status: active

# VOLITELNÉ -------------------------------------------------------------
# Smazat řádky, které nepoužíváš — žádné prázdné hodnoty.

# Lidsky čitelný název projektu.
# title: Název Projektu

# Shrnutí do 500 znaků.
# summary: Co projekt dělá a proč vznikl.

# Datum zahájení (pokud jiné od date).
# started: YYYY-MM-DD

# Datum ukončení (vyplnit při completed/abandoned).
# ended: YYYY-MM-DD

# Členové týmu (lore/personas/<slug> nebo volná jména).
# team:
#   - lore/personas/architect
#   - Jan Novak

# Lekce z projektu (lore/lessons/<slug>).
# lessons:
#   - lore/lessons/2026-04-29-nazev-lekce

# Rozhodnutí projektu (lore/decisions/<slug>).
# decisions:
#   - lore/decisions/2026-04-29-nazev-rozhodnuti

# URL repozitáře.
# repo_url: https://github.com/org/repo

# Autor záznamu.
# author: claude-code

# Kontext projektu.
# context: 1–3 věty o účelu a historii projektu.

# true = zastaralý záznam (nesmazat).
# deprecated: true

# Nástupce.
# superseded_by: lore/projects/novy-projekt
---

# Název projektu

Stručný popis: co projekt dělá, proč vznikl, jaký má scope. 2–4 věty.

Název souboru: `<slug>.md` — bez date-prefix (projekt je entita, ne událost).
