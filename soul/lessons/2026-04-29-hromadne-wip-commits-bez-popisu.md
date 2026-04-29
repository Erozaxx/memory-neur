---
date: 2026-04-29
type: anti-pattern
tags:
  - git
  - commits
  - review
  - bisect
confidence: high
context: Pozorováno opakovaně při auditu starších feature větví.
author: tým
---

# Hromadné WIP commits bez popisu

`git commit -am "wip"` na konci dne sbalí desítky nesouvisejících změn
do jednoho uzlu historie. Důsledky: `git bisect` nedokáže izolovat
regresi, code review nemá rozumné hranice, revert maže i nesouvisející
práci, a budoucí konsolidace lekcí ztratí kontext „proč". Pravidlo:
jeden logický celek = jeden commit s popisným message, i za cenu
interaktivního rebase před otevřením PR.
