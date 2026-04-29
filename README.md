# memory-neur

Sdílená znalostní báze pro AI agenty a jejich lidské spolupracovníky.
Projekt zachycuje to, co funguje, co nefunguje, jaká rozhodnutí byla přijata a jaké procesy se opakují — v čitelné, verziovatelné a prohledávatelné formě.

---

## Co to je

`memory-neur` je strukturovaná paměť vývojového systému.
Místo poznámek rozházených v různých souborech nebo v hlavách jednotlivých agentů se poznatky ukládají jako atomické záznamy s frontmatterem — jednotně, validovatelně, s časovou stopou.

Záznamy jsou v adresáři `lore/`. Scripty ve `scripts/` zajišťují validaci.

---

## Proč to existuje

AI agenti nemají perzistentní paměť mezi sezeními. Opakovaně naráží na stejné problémy, přijímají stejná rozhodnutí od nuly a ztrácejí kontext, proč systém vypadá tak, jak vypadá. `memory-neur` tento problém řeší: poznatek zapsaný jednou je dostupný všem agentům i lidem ve všech budoucích sezeních.

---

## Jak začít

```bash
# Klonuj repozitář
git clone <repo-url>
cd memory-neur

# Přidej nový záznam (příklad: lekce)
cp lore/lessons/_template.md lore/lessons/YYYY-MM-DD-muj-poznatek.md
# Vyplň frontmatter a tělo záznamu

# Validuj záznam před commitem
bash scripts/validate-lesson.sh lore/lessons/YYYY-MM-DD-muj-poznatek.md

# Commitni
git add lore/lessons/YYYY-MM-DD-muj-poznatek.md
git commit -m "lore: přidána lekce o X"
```

Detailní popis struktury a schémat najdeš v [lore/README.md](lore/README.md).

---

## Jak přidat záznam

1. Zvol správný typ záznamu (viz přehled níže).
2. Zkopíruj šablonu (`_template.md`) z příslušného adresáře.
3. Pojmenuj soubor: `YYYY-MM-DD-<slug>.md` (lessons, decisions) nebo `<slug>.md` (processes, personas, projects).
4. Vyplň povinné frontmatter pole: `date`, `type`, `tags`, `schema_version`.
5. Napiš tělo záznamu: 3–7 řádků, konkrétně a bez zbytečného žargonu.
6. Spusť validaci: `bash scripts/validate-lesson.sh <soubor>` (nebo `bash scripts/validate-all.sh` pro celé lore).
7. Commitni.

---

## Přehled typů záznamů

| Typ | Adresář | K čemu slouží | Příklad |
|-----|---------|---------------|---------|
| **lessons** | `lore/lessons/` | Technické pasti, anti-patterny, heuristiky, principy, drobná rozhodnutí | `gotcha`: GitHub API vrací base64 s newlinami |
| **decisions** | `lore/decisions/` | Vědomá architektonická nebo produktová rozhodnutí s alternativami a statusem (ADR) | Volba slug místo UUID jako ID záznamu |
| **processes** | `lore/processes/` | Opakující se workflow, checklisty, rituály, automatizace | Pre-release checklist před deploymentem |
| **projects** | `lore/projects/` | Kontext projektů — co se řeší, co bylo rozhodnuto, stav | `memory-neur` — znalostní báze agentů |
| **personas** | `lore/personas/` | Profily agentů a rolí relevantních pro projekt | `claude-code` — role a kontext AI agenta |

### Typy lekcí (`type` ve frontmatteru)

- `gotcha` — technická past nebo nečekané chování systému
- `anti-pattern` — postup, který vypadá rozumně, ale škodí
- `preference` — subjektivní volba týmu (není absolutní pravda)
- `decision-minor` — vědomé rozhodnutí bez alternativ; pro ADR s alternativami použij `lore/decisions/`
- `heuristika` — pravidlo palce, platí často, ne vždy
- `principle` — trvalý axiom

---

## Struktura repozitáře

```
lore/
  lessons/      ← technické poznatky a principy
  decisions/    ← ADR záznamy s alternativami a statusem
  processes/    ← workflow, checklisty, rituály
  projects/     ← projektový kontext
  personas/     ← profily agentů a rolí
scripts/
  validate-lesson.sh    ← validace jednotlivého záznamu
  validate-all.sh       ← validace celého lore
  audit-conflicts.sh    ← kontrola konfliktních záznamů
```

Technická dokumentace schémat a validačních pravidel: [lore/README.md](lore/README.md).
