# lore/

Znalostní báze projektu. Každý záznam je Markdown soubor s YAML frontmatterem.

## Typy záznamů

| Typ | Adresář | Pojmenování | Popis |
|-----|---------|-------------|-------|
| lesson | `lore/lessons/` | `YYYY-MM-DD-<slug>.md` | Atomické poučení, axiom, zkušenost |
| decision | `lore/decisions/` | `YYYY-MM-DD-<slug>.md` | ADR-like rozhodnutí s alternativami a statusem |
| project | `lore/projects/` | `<slug>.md` | Referencovatelný kontext projektu |
| process | `lore/processes/` | `<slug>.md` | Opakující se workflow, checklist, rituál |
| persona | `lore/personas/` | `<slug>.md` | Profil AI agenta nebo lidské role |

## Rozhodovací strom — kam co patří

```
Co chci zapsat?
├── Naučili jsme se něco / udělali zkušenost / axiom / pravidlo?
│   └── lore/lessons/
│       type: gotcha | anti-pattern | preference | decision-minor | heuristika | principle
│
├── Vědomé rozhodnutí s alternativami, statusem a dopadem?
│   └── lore/decisions/
│       type: architecture | product | process | tooling | policy
│
├── Popis projektu jako reference (ne operativní stav)?
│   └── lore/projects/
│
├── Opakující se postup, checklist nebo workflow?
│   └── lore/processes/
│
└── Profil agenta nebo lidské role?
    └── lore/personas/
```

### Hraniční případ: lessons vs. decisions

| Kritérium | → lessons/ | → decisions/ |
|-----------|-----------|--------------|
| Má `status` (proposed/active/superseded)? | Ne | Ano |
| Byly zvažovány alternativy? | Ne | Ano |
| Má `rationale` a `consequences`? | Volitelně | Doporučeno |

Pravidlo: pokud záznam NEMÁ status a NEMÁ zvažované alternativy → `lessons/` s `type: decision-minor`.
Pokud MÁ explicitní status a alternativy byly zvažovány → `decisions/`.

## Povinná pole (všechny typy)

| Pole | Formát | Popis |
|------|--------|-------|
| `date` | `YYYY-MM-DD` | Datum zápisu nebo zahájení |
| `type` | viz enum každého typu | Klasifikace záznamu |
| `tags` | array, min. 1, kebab-case | Volné štítky pro vyhledávání |
| `schema_version` | `"MAJOR.MINOR"` | Verze schématu (nyní `"1.0"`) |

`status` je povinné pro `decisions/`, `projects/` a `processes/`.

## Konvence odkazování (cross-reference)

Kanonický formát — použij všude:
```
lore/<type>/<slug>
```

Příklady:
```
lore/lessons/2026-04-29-slug-misto-uuid
lore/decisions/2026-04-29-volba-5-typu
lore/projects/memory-neur
lore/processes/deploy-checklist
lore/personas/architect
```

**Same-type zkrácený formát** (akceptovatelné, ale ne doporučené):
```
# uvnitř lore/lessons/ souboru:
related:
  - 2026-04-29-jina-lekce
```

**Provenance vs. relevance** (`source_project` vs. `projects[]`):
- `source_project: nazev-projektu` — kde záznam **vznikl** (singleton, provenance)
- `projects: [lore/projects/x, lore/projects/y]` — kde je záznam **relevantní** (seznam, kontextualizace)
- Jsou komplementární — záznam může mít oboje

## Pojmenování souborů

### Slug pravidla
- Povoleno: `a-z`, `0-9`, `-`
- Zakázáno: `_`, mezery, unicode, velká písmena
- Délka: 3–60 znaků (doporučeno 20–50)
- Regex: `^[a-z][a-z0-9-]{2,59}$`
- **Immutable po prvním commitu** — slug je kanonický identifikátor uzlu

### Kolize slugu ve stejný den
Přidej suffix: `-2`, `-3` atd.
```
2026-04-29-volba-architektury.md
2026-04-29-volba-architektury-2.md
```

## Validace

```bash
# Validuj konkrétní soubor (lesson):
bash scripts/validate-lesson.sh lore/lessons/2026-04-29-priklad.md

# Validuj všechny typy najednou:
bash scripts/validate-all.sh

# Zkontroluj otevřené konflikty:
bash scripts/audit-conflicts.sh
```

Exit kódy: `0` = OK (warnings jsou OK), `1` = errors, `2` = usage error.

## Evolvability — pravidla pro změny schématu

| Povoleno (MINOR bump) | Zakázáno |
|----------------------|---------|
| Přidat nové volitelné pole | Přejmenovat existující pole |
| Přidat novou hodnotu do `type` enum | Odebrat hodnotu z `type` enum |
| Přidat nový typ záznamu | Změnit formát povinného pole |

**MINOR bump** (1.0 → 1.1): Přidej do `_schema.yml`, aktualizuj `_template.md`. Merge do main = schválení.

**MAJOR bump** (1.x → 2.0): PR s migration scriptem + review + zápis do `lore/CHANGELOG.md`.

Staré soubory bez `schema_version` → validátor vydá WARNING (ne error), defaultuje na `"1.0"`.

## _index.yml (MVP+)

V MVP fázi volitelný. Stane se povinným při >50 záznamech na typ.
Generuje se přes `scripts/build-index.sh` (budoucí implementace).

Formát:
```yaml
schema_version: 1
type: lessons
updated: YYYY-MM-DD
entries:
  - id: lore/lessons/2026-04-29-slug
    file: 2026-04-29-slug.md
    date: 2026-04-29
    type: gotcha
    tags: [example-tag]
```

## Přidání nového typu záznamu

Podmínky:
1. Typ nejde vyjádřit existujícím typem + enum extension
2. Minimálně 3 reálné záznamy, které by v něm žily
3. Jasně odlišný životní cyklus nebo update-pattern

Postup:
1. Vytvořit `lore/<novy-typ>/` s `_schema.yml`, `_template.md`
2. Přidat do tohoto README rozhodovacího stromu
3. Přidat do `scripts/validate-all.sh`
4. PR review
