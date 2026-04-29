---
# STUB — minimální šablona. Plná implementace závisí na uživatelově vizi.
# Nerozšiřuj bez konzultace.

# POVINNÉ ---------------------------------------------------------------

# Datum první formulace persony (ISO 8601).
date: YYYY-MM-DD

# Kategorie persony. Přesně jedna hodnota z:
#   ai-agent    AI agent (Claude, GPT, vlastní agent)
#   human-role  lidská role v týmu nebo projektu
#   composite   kombinace více rolí nebo agentů
type: ai-agent

# Štítky pro vyhledávání. Min. 1 položka, kebab-case.
tags:
  - example-tag

# Verze schématu. Neměň — aktuální hodnota je "1.0".
schema_version: "1.0"

# VOLITELNÉ (stub) -------------------------------------------------------

# Jméno nebo označení persony.
# title: Název Persony

# Stručný popis role.
# summary: Co tato persona dělá a kde se uplatní.

# Stručný popis role a odpovědností.
# role: Popis role.

# Autor záznamu.
# author: claude-code

# true = zastaralý záznam (nesmazat).
# deprecated: true

# Nástupce.
# superseded_by: lore/personas/nova-persona
---

# Název persony

Stručný popis: kdo nebo co tato persona je, v jakém kontextu se uplatní. 2–3 věty.

Název souboru: `<slug>.md` — bez date-prefix (persona je entita, ne událost).

> STUB: Tato šablona je záměrně minimální. Plná implementace (strengths, scope, gallup profil,
> atd.) bude definována zvlášť dle uživatelovy vize.
