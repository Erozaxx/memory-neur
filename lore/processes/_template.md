---
# POVINNÉ ---------------------------------------------------------------

# Datum první formulace procesu (ISO 8601).
date: YYYY-MM-DD

# Kategorie procesu. Přesně jedna hodnota z:
#   workflow     sekvenční nebo větvený postup
#   checklist    kontrolní seznam kroků
#   ritual       opakující se ceremonie (weekly review, retrospektiva)
#   automation   automatizovaný proces spouštěný skriptem nebo CI
type: workflow

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# Verze schématu. Neměň — aktuální hodnota je "1.0".
schema_version: "1.0"

# Stav procesu:
#   active      aktuálně používaný
#   draft       návrh, dosud neověřený
#   deprecated  zastaralý, nahrazen nebo zrušen
status: active

# VOLITELNÉ -------------------------------------------------------------
# Smazat řádky, které nepoužíváš — žádné prázdné hodnoty.

# Lidsky čitelný název.
# title: Název Procesu

# Shrnutí do 500 znaků.
# summary: Co proces dělá a kdy se používá.

# Kdy nebo čím se proces spouští.
# trigger: Každý pátek nebo při detekci XYZ.

# Vlastník procesu (lore/personas/<slug> nebo jméno).
# owner: lore/personas/lead-engineer

# Ordered list kroků.
# steps:
#   - Krok 1: popis
#   - Krok 2: popis
#   - Krok 3: popis

# Kdo vykonává (lore/personas/<slug>).
# personas:
#   - lore/personas/developer

# Nástroje a systémy.
# tools:
#   - GitHub Actions
#   - Slack

# Autor záznamu.
# author: claude-code

# Kontext procesu.
# context: 1–3 věty.

# true = zastaralý záznam (nesmazat).
# deprecated: true

# Nástupce.
# superseded_by: lore/processes/novy-proces
---

# Název procesu

Stručný popis: co proces dělá, kdy se spouští, kdo ho vykonává. 2–3 věty.

## Kroky

1. **Krok 1** — popis
2. **Krok 2** — popis
3. **Krok 3** — popis

Název souboru: `<slug>.md` — bez date-prefix (proces je živý dokument).
