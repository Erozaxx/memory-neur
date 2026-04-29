---
date: 2026-04-29
type: decision-minor
schema_version: "1.0"
tags:
  - schema
  - identita
  - graph-db-ready
confidence: medium
context: Návrh schématu pro lore/lessons/ — viz _schema.yml.
source_project: memory-neur
related:
  - 2026-04-29-github-contents-api-base64-newliny
author: claude-code
---

# Slug v názvu souboru jako stabilní ID lekce

Identifikátor lekce je název souboru `YYYY-MM-DD-<slug>.md`, ne UUID
ani sekvenční číslo. Důvod: zápis nové lekce nesmí vyžadovat znalost
celé báze ani volání generátoru ID — repo musí fungovat z mobilu přes
GitHub API i z VM bez git klienta. Slug je čitelný, řaditelný podle
data, a při migraci do graf DB se použije relativní cesta jako
přirozený klíč uzlu. Cena: kolize slugu ve stejném dni řešíme
sufixem `-2`, `-3` (manuálně, validátor to nehlídá).
