---
date: 2026-04-29
type: gotcha
schema_version: "1.0"
tags:
  - github-api
  - base64
  - encoding
confidence: high
context: Konsolidace lekcí přes GitHub Contents API z VM bez git klienta.
source_project: memory-neur
author: claude-code
---

# GitHub Contents API vrací base64 s newlinami

Endpoint `GET /repos/{owner}/{repo}/contents/{path}` vrací pole `content`
zakódované base64, ale rozdělené po 60 znacích znakem `\n`. `base64 -d`
v coreutils i Pythoní `base64.b64decode` to tolerují, ale strict
dekodéry (naivní implementace v shellu, některé JS knihovny) selžou.
Před dekódováním vždy odstranit whitespace, např. `tr -d '\n\r '`.
