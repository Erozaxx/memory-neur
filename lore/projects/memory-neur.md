---
date: 2026-04-29
type: oss
schema_version: "1.0"
status: active
tags:
  - lore
  - ai-pamet
  - claude-code
  - skills
  - knowledge-management
title: memory-neur — sdílená znalostní báze AI agentů
summary: >
  Repozitář se schématy a Claude Code skills pro ~/.lore/ — globální
  znalostní bázi sdílenou napříč AI projekty. Obsahuje lessons, decisions,
  processes, projects a personas záznamy s validovatelným frontmatterem.
related:
  - lore/lessons/2026-04-29-slug-misto-uuid-jako-id-lekce
  - lore/lessons/2026-04-29-github-contents-api-base64-newliny
author: claude-code
---

# memory-neur — sdílená znalostní báze AI agentů

Repozitář definuje schéma a konvence pro `~/.lore/` a poskytuje
Claude Code skills `/lore` a `/intel-pass`. Účel: AI agenti a lidé
napříč projekty zapisují poznatky jednou a nacházejí je ve všech
budoucích sezeních.

## Klíčová rozhodnutí

- `~/.lore/` globálně (ne v repozitáři projektu) — sdíleno napříč projekty
- Lokální git repo, ne GitHub API-first — offline funkčnost, push volitelný
- Slug jako ID záznamu — čitelné, řaditelné, bez generátoru

## Stav (2026-05-11)

Aktivní. Skills `/lore` a `/intel-pass` jsou nasazené.
Chybějící typy: `personas/`, `principles/` — plánováno.

## Cross-reference

- Schéma: `lore/lessons/_schema.yml`
- Konvence odkazování: viz `lore/README.md`
