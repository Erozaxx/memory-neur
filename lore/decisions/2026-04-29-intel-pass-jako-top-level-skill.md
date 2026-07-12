---
date: 2026-04-29
type: architecture
schema_version: "1.0"
status: active
tags:
  - intel-pass
  - lore
  - skills
  - model-invariant
title: /intel-pass jako samostatný skill mimo namespace /lore
summary: >
  Inteligentní analýza ~/.lore/ běží jako top-level /intel-pass, ne jako
  /lore intel-pass. Zajišťuje model invariant: vždy claude-opus-4-7.
source_project: memory-neur
rationale: >
  Pokud by byl /intel-pass subcommand /lore, spustil by se na session modelu
  (typicky Sonnet). Model invariant "vždy Opus + extended thinking" by byl
  potichu porušen. Top-level skill dělá specifikaci modelu explicitní.
options:
  - /lore intel-pass — jednodušší namespace, ale model specifikace skrytá uvnitř subcommandu
  - /intel-pass top-level — model je explicitní v názvu souboru skills/intel-pass/intel-pass.md
consequences: >
  Dvě separátní instalované skills. Uživatel musí vědět o obou. Výhoda:
  přejmenování modelu stačí editovat jeden soubor.
author: claude-code
---

# /intel-pass jako samostatný skill mimo namespace /lore

## Kontext

Inteligentní analýza lore záznamů (hledání vzorů, generování hypotéz pro nové záznamy) je výpočetně náročná operace vhodná pro nejsilnější dostupný model s extended thinking. Původní návrh ji umísťoval jako subcommand `/lore intel-pass`. Problém: Claude Code spouští subcommands na session modelu, který je typicky Sonnet. Model invariant by byl potichu porušen bez jakéhokoli varování.

## Rozhodnutí

`/intel-pass` je samostatný top-level Claude Code skill instalovaný jako `~/.claude/commands/intel-pass.md`. Specifikace modelu je explicitní v souboru skill definice. `/lore` namespace pokrývá CRUD operace; `/intel-pass` pokrývá analytické operace vyžadující jiný model.

## Alternativy

- **/lore intel-pass (subcommand)**: Jednodušší namespace, uživatel si pamatuje jeden příkaz. Nevýhoda: model specifikace je skrytá uvnitř subcommandu, session model může přepsat záměr bez viditelného varování.
- **/intel-pass top-level (zvoleno)**: Model je explicitní v názvu a definici souboru. Přejmenování nebo upgrade modelu stačí editovat jeden soubor (`skills/intel-pass/intel-pass.md`).

## Důsledky

Instalace skills vytváří dvě separátní položky v `~/.claude/commands/`: `lore.md` a `intel-pass.md`. Uživatel musí být obeznámen s oběma příkazy — dokumentace a README je zmiňují odděleně. Výhoda: model invariant je vynucen strukturou, nikoli konvencí.
