---
date: 2026-04-29
type: architecture
schema_version: "1.0"
status: active
tags:
  - lore
  - architektura
  - sdileni
title: Globální ~/.lore/ místo lore/ v každém repozitáři
summary: >
  Záznamy žijí v ~/.lore/ globálně na systému, ne v lore/ adresáři
  každého projektu. Sdílení across projektů bez duplikace.
source_project: memory-neur
rationale: >
  Jeden systém paměti pro všechny projekty. Lore/ v repozitáři
  zůstává pouze jako ukázka a schéma source-of-truth.
options:
  - lore/ v každém repozitáři — izolace, ale duplikace a žádné cross-project sdílení
  - ~/.lore/ globálně — sdíleno, ale vyžaduje instalaci na každém stroji
consequences: >
  Záznamy z memory-neur projektu jsou referenční příklady, nikoli
  produkční lore. Produkce žije v ~/.lore/ na uživatelově systému.
author: claude-code
---

# Globální ~/.lore/ místo lore/ v každém repozitáři

## Kontext

Původní návrh předpokládal, že každý projekt bude mít vlastní `lore/` adresář přímo v repozitáři. Při implementaci se ukázalo, že poznatky (lessons, decisions) jsou hodnotné napříč projekty — opakovat stejné chyby v projektu B jen proto, že lore žije izolovaně v projektu A, postrádá smysl. Zároveň je nepraktické ručně synchronizovat záznamy mezi repozitáři.

## Rozhodnutí

Produkční záznamy žijí v `~/.lore/` na uživatelově systému, globálně sdílené napříč všemi projekty. Adresář `lore/` v repozitáři memory-neur slouží výhradně jako ukázka schématu a dogfooding prostředí — ne jako primární úložiště.

## Alternativy

- **lore/ v každém repozitáři**: Izolace per projekt, žádné závislosti mimo repo. Nevýhoda: duplikace poznatků, žádné cross-project sdílení, nutná manuální synchronizace.
- **~/.lore/ globálně (zvoleno)**: Jeden systém paměti, sdílený automaticky. Vyžaduje instalaci (`make install-skills`) na každém novém stroji.

## Důsledky

Záznamy v `lore/` tohoto repozitáře jsou referenční příklady (dogfooding), nikoli produkční data. Uživatel musí pochopit toto rozdělení — README.md ho explicitně uvádí. Přenositelnost mezi stroji vyžaduje git remote a push `~/.lore/`.
