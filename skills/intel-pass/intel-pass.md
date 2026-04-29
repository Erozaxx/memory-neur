---
name: intel-pass
description: >
  Spustí intel-analyst agenta nad ~/.lore/ — hledá implicitní vzory, mezery,
  protiřečení a latentní heuristiky. Vždy běží na claude-opus-4-7 s extended
  thinking (budget 10 000 tokenů). Výstup jsou hypotézy, nikdy přímý zápis do ~/.lore/.
argument-hint: "[--scope lessons|projects|all] [--focus <text>]"
---

<!--
## Proč je /intel-pass separátní top-level skill (NE subcommand /lore)

Pokud by byl /intel-pass subcommand v /lore, spustil by se na aktuálním
session modelu (typicky Sonnet). Model invariant "vždy Opus + highest reasoning"
by byl potichu porušen. Oddělení do samostatného top-level skillu zaručuje,
že model specifikace je explicitní a viditelná — uživatel nemůže toto omylem obejít.

Model: claude-opus-4-7 — definován NA JEDNOM MÍSTĚ v tomto souboru (viz brief níže).
Pokud je model přejmenován, stačí editovat tento soubor + make install-skills.

## Kde jsou výstupní soubory

Po dokončení intel-analyst zapíše:
  ~/.lore/intel-pass/assessments/assessment_<YYYY-MM-DD>.md
    → Intelligence Assessment Report: patterns, gaps, conflicts, latent heuristics

  ~/.lore/intel-pass/drafts/candidate_<slug>.md
    → Kandidátní lore záznamy jako hypotézy (označeny [HYPOTÉZA], nikdy v ~/.lore/ root)

## Jak číst assessment report

Sections v assessment_<iter>.md:
  - Identified Patterns (HIGH/MEDIUM/LOW confidence + zdrojové záznamy)
  - Gaps (oblasti bez pokrytí)
  - Conflicts (záznamy co si protiřečí → kandidáti na conflict_status)
  - Latent Heuristics (chování z projektů čekající na zobecnění)

Každý kandidátní záznam v draft/ je označen [HYPOTÉZA] a obsahuje sekci
## Reasoning vysvětlující odkud vzorec pochází. Uživatel vždy rozhoduje
co commitne — kandidátní záznamy nejdou automaticky do ~/.lore/.
-->

# Skill: /intel-pass

Spouštím intel-analyst agenta nad `~/.lore/`. Tento skill je záměrně mimo
namespace `/lore` — zajišťuje invariant kvality: analýza VŽDY běží na
`claude-opus-4-7` s extended thinking, bez ohledu na aktuální session model.

---

## Krok 1 — Prerekvizita: existence ~/.lore/

```bash
ls ~/.lore/ 2>/dev/null
```

Pokud `~/.lore/` neexistuje, zastav s chybou:

```
CHYBA: ~/.lore/ neexistuje.
Inicializuj lore repozitář:
  mkdir -p ~/.lore/{lessons,decisions,projects,processes,personas,scripts}
  cd ~/.lore && git init
Pak nainstaluj schemas a templates, a teprve poté spusť /intel-pass.
```

## Krok 2 — Prerekvizita: minimální počet záznamů

```bash
find ~/.lore -name "*.md" | grep -v "_schema\|_template" | wc -l
```

Pokud počet záznamů < 10, zastav s varováním:

```
VAROVÁNÍ: ~/.lore/ obsahuje méně než 10 záznamů (aktuálně: N).
/intel-pass je navržen pro analýzu existující knowledge base.
Přidej záznamy přes /lore new a spusť /intel-pass až bude databáze dostatečně naplněná.
```

## Krok 3 — Parsování parametrů

Z `$ARGUMENTS` extrahuj:

- `--scope <value>` → hodnota: `lessons`, `projects`, nebo `all`; výchozí: `all`
- `--focus "<text>"` → volitelný textový řetězec oblasti zaměření; výchozí: (žádné)

Mapování --scope na lore cesty:
- `all`      → `~/.lore/`
- `lessons`  → `~/.lore/lessons/`
- `projects` → `~/.lore/projects/`

Pokud je zadána neznámá hodnota --scope, zastav s chybou:

```
CHYBA: Neznámá hodnota --scope: "<zadaná hodnota>"
Platné hodnoty: lessons | projects | all
```

## Krok 4 — Upozornění uživateli (cost warning)

Spočítej počet záznamů v scope:
```bash
find <scope_path> -name "*.md" ! -name "_schema*" ! -name "_template*" | wc -l
```

Odhadni spotřebu: ~500 tokenů na záznam + 15 000 fix overhead. Zaokrouhli na tisíce.
Odhadni čas: ~1 minuta na každých 10 000 tokenů.

Zobraz:
```
⚠️  DRAHÁ OPERACE

/intel-pass spustí intel-analyst agenta s:
  Model:    claude-opus-4-7
  Thinking: extended (budget: 10 000 tokenů)
  Záznamy:  <N> souborů v scope
  Odhad tokenů: ~<X> tokenů
  Odhad času:   ~<Y> minut

Scope:  <scope_path>
Focus:  <focus nebo "(bez zaměření)">

Pokračovat? (ano/ne)
```

Čekej na potvrzení uživatele. Pokud uživatel odpoví jinak než "ano" / "yes" / "y",
zastav s informací: "Operace zrušena."

## Krok 5 — Sestavení briefu pro intel-analyst

Sestav brief jako strukturovaný dokument (inline, nepotřebuješ zapisovat soubor):

```
# Brief pro Intel-Analyst

- **Od**: intel-pass skill
- **Datum**: <aktuální datum>
- **Iterace**: <aktuální iterace z orchestration/plans/active.md, pokud dostupná; jinak "standalone">

## Model a konfigurace (KRITICKÝ INVARIANT — NEMĚNIT)

model: claude-opus-4-7
thinking: enabled
thinking_budget_tokens: 10000

Toto není doporučení — je to povinná konfigurace. /intel-pass existuje
právě proto, aby zajistil spuštění na tomto modelu, nikoli na session modelu.

## Scope analýzy

Prohledej záznamy v: <scope_path>
Zahrnuté typy záznamů: <"všechny typy" nebo konkrétní typ dle --scope>

## Focus area (pokud zadán)

<pokud --focus zadán:>
focus_area: "<text z --focus>"
Věnuj zvýšenou pozornost záznamům a vzorcům relevantním pro: <text z --focus>

<pokud --focus nezadán:>
focus_area: (žádné) — analyzuj celý scope bez specifického zaměření

## Zadání

Projdi záznamy v scope jako detektiv. Hledej:
1. **Nevyjádřené vzory** — záznamy říkající totéž různými slovy bez pojmenovaného principu
2. **Mezery** — oblasti kde záznamy chybí, přestože by existovat měly
3. **Protiřečení** — záznamy říkající opačné věci bez vysvětlení
4. **Latentní heuristiky** — chování z projektů/procesů nezdokonalené do lekce

## Výstup — POVINNÉ

Výstupní adresář je vždy `~/.lore/intel-pass/` — globální lokace nezávislá na projektu.

```bash
mkdir -p ~/.lore/intel-pass/assessments ~/.lore/intel-pass/drafts
```

1. Assessment report: `~/.lore/intel-pass/assessments/assessment_<YYYY-MM-DD>.md`
   Strukturuj jako: Identified Patterns | Gaps | Conflicts | Latent Heuristics
   U každého vzoru: confidence level (HIGH/MEDIUM/LOW) + zdrojové záznamy

2. Kandidátní záznamy: `~/.lore/intel-pass/drafts/candidate_<slug>.md`
   Každý označen [HYPOTÉZA], s confidence a sekcí ## Reasoning

KRITICKÝ INVARIANT: Kandidátní záznamy NIKDY NEZAPISUJEŠ přímo do ~/.lore/
Pouze do `~/.lore/intel-pass/drafts/` — human/reviewer rozhoduje o přijetí.
Pro přijetí: `/lore new <type> --from-draft ~/.lore/intel-pass/drafts/<slug>.md`

## Stdout summary po dokončení

Po dokončení analýzy vypiš na stdout:
- Runtime (minuty)
- Odhadovaný token cost
- Counts: X patterns, Y gaps, Z conflicts, W latent heuristics, V candidates
- Top 3 hypotézy s confidence level
- Cesty k výstupním souborům (assessment, drafts)
```

## Krok 6 — Dispatch intel-analyst agenta

Pokud existuje agent profil, přidej ho jako kontext role:
```bash
cat .aiworkflow/agents/intel-analyst/AGENTS.md 2>/dev/null || echo "AGENTS.md not found, proceeding without role profile"
```

Spusť intel-analyst agenta přes Task tool s briefem z Kroku 5.

Instrukce pro Task dispatch:
- Agent: intel-analyst
- Model: `claude-opus-4-7` (viz brief — KRITICKÝ INVARIANT)
- Extended thinking: enabled, budget_tokens: 10000
- Vstupní brief: obsah sestavený v Kroku 5

**POZNÁMKA k model invariantu**: Model specifikace v textu briefu informuje agenta, ale Task tool může použít session model. Pro garantované spuštění na Opus ověř před voláním `/intel-pass` že Claude Code session běží na `claude-opus-4-7`.

## Krok 7 — Výstup po dokončení

Po dokončení agenta zobraz na stdout summary:

```
✅ Intel-pass dokončen

Runtime:        <X minut>
Token cost:     ~<N> tokenů (odhad)

Výsledky:
  Patterns:          <počet>
  Gaps:              <počet>
  Conflicts:         <počet>
  Latent heuristics: <počet>
  Candidates:        <počet>

Top 3 hypotézy:
  1. [<CONFIDENCE>] <název hypotézy>
  2. [<CONFIDENCE>] <název hypotézy>
  3. [<CONFIDENCE>] <název hypotézy>

Výstupní soubory:
  Assessment: ~/.lore/intel-pass/assessments/assessment_<YYYY-MM-DD>.md
  Kandidáti:  ~/.lore/intel-pass/drafts/candidate_*.md

Jak dál:
  - Přečti assessment report pro přehled vzorů a mezer
  - Zkontroluj kandidátní záznamy v ~/.lore/intel-pass/drafts/
  - Pro přijetí kandidáta: /lore new <type> --from-draft ~/.lore/intel-pass/drafts/<slug>.md
```

---

## Chybové stavy (přehled)

| Stav | Akce |
|------|------|
| `~/.lore/` neexistuje | Stop s chybou + instrukce bootstrap |
| Záznamy < 10 | Stop s varováním + instrukce přidat záznamy |
| Neznámá hodnota --scope | Stop s chybou + výpis platných hodnot |
| Uživatel nepotvrdí cost | Stop s "Operace zrušena." |
| Agent nedostupný / model error | Stop s chybou + doporučení zkontrolovat Claude Code verzi |
| Aktivní iterace neexistuje | Varovat ("iterace nenalezena"), pokračovat s iter="standalone" |
