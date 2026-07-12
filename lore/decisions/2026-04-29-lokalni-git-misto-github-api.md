---
date: 2026-04-29
type: architecture
schema_version: "1.0"
status: active
tags:
  - lore
  - git
  - github-api
  - offline
title: Lokální git repo pro ~/.lore/ místo GitHub API-first přístupu
summary: >
  ~/.lore/ je lokální git repozitář. Přístup přes GitHub API není
  primární — volitelný přes lore git push na remote.
source_project: memory-neur
rationale: >
  Jednoduchost: lore new, validate, commit funguje offline.
  GitHub API přidává latenci, autentizaci a rate limity pro základní operace.
options:
  - GitHub API-first — přístup z mobilu a jiných strojů bez git klienta
  - Lokální git + volitelný remote — offline první, sync volitelný
consequences: >
  Cross-platform přístup z mobilu vyžaduje git remote + push. Není out-of-box,
  ale dokumentace uvádí postup: git remote add origin + lore git push.
author: claude-code
---

# Lokální git repo pro ~/.lore/ místo GitHub API-first přístupu

## Kontext

Raná iterace návrhu uvažovala GitHub API jako primární transport pro záznamy — zápis přímo přes API, čtení přes API, bez nutnosti lokálního git klienta. Tím by byl systém dostupný z jakéhokoli prostředí. Při implementaci se ukázalo, že GitHub API přidává netriviální složitost: autentizace, rate limity, latence při každém commitu, závislost na síti pro základní operace jako `validate`.

## Rozhodnutí

`~/.lore/` je lokální git repozitář inicializovaný na uživatelově stroji. Skills `/lore new`, `/lore validate`, `/lore git commit` pracují výhradně lokálně. Sync na remote (GitHub, GitLab) je volitelný krok přes `lore git push`.

## Alternativy

- **GitHub API-first**: Záznamy dostupné z mobilu a libovolného stroje bez git klienta. Nevýhoda: nutná autentizace pro každý zápis, rate limity, offline použití nefunguje, složitá implementace skills.
- **Lokální git + volitelný remote (zvoleno)**: Offline první, jednoduchá implementace. Sync je opt-in — uživatel nastaví remote pokud chce přístup z více strojů.

## Důsledky

Cross-platform přístup z mobilu nebo jiného stroje vyžaduje nastavení git remote a pravidelný push. Toto není out-of-box chování — dokumentace uvádí postup. Trade-off je vědomý: jednoduchost základního použití před pokročilou dostupností.
