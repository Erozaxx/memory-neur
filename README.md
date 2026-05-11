# memory-neur

Strukturovaná paměť pro AI agenty a jejich lidské spolupracovníky — verziovatelná, prohledávatelná, sdílená napříč projekty.

---

## Co to je

`memory-neur` je systém pro ukládání poznatků v atomických záznamech s frontmatterem. Místo poznámek rozházených po souborech nebo v hlavách jednotlivých agentů se vše ukládá jednotně, validovatelně a s časovou stopou.

AI agenti nemají perzistentní paměť mezi sezeními. Opakovaně naráží na stejné problémy, přijímají stejná rozhodnutí od nuly a ztrácejí kontext, proč systém vypadá tak, jak vypadá. Poznatek zapsaný jednou je dostupný všem agentům i lidem ve všech budoucích sezeních.

Záznamy žijí v `~/.lore/` globálně na tvém systému — sdílené napříč projekty. Adresář `lore/` v tomto repozitáři obsahuje ukázkové záznamy — projekt sám sebe používá jako příklad.

---

## Předpoklady

Než začneš, ověř, že máš k dispozici:

- **Claude Code** — nainstalovaný a funkční (`claude --version`)
- **GNU Make** — na macOS: `xcode-select --install`, na Linuxu: `sudo apt install make`
- **git**
- **macOS nebo Linux** (nebo WSL na Windows) — Windows CMD/PowerShell není podporován

---

## Quickstart

### 1. Nainstaluj skills

**V terminálu:**
```bash
make install-skills
cd ~/.lore && git init     # jednorázová git inicializace
```

`make install-skills` zkopíruje soubory `skills/lore/lore.md` a `skills/intel-pass/intel-pass.md`
do `~/.claude/commands/` (kde Claude Code hledá slash commandy) a vytvoří adresářovou strukturu
`~/.lore/` (včetně `decisions/`, `lessons/`, `projects/`, ...).
Po instalaci budeš moci psát `/lore` nebo `/intel-pass` přímo v Claude Code.

### 2. Ověř instalaci

**V terminálu:**
```bash
ls ~/.lore/                      # zobrazí: decisions/ lessons/ processes/ ...
ls ~/.claude/commands/lore.md    # skill je nainstalovaný
```

### 3. Zapiš první lekci

**V Claude Code (slash command):**
```
/lore new lesson
```

Claude se zeptá na kontext, inferuje frontmatter a zapíše `~/.lore/lessons/YYYY-MM-DD-<slug>.md`.

Skill může volat kdokoliv — člověk v přímé konverzaci, hlavní agent, spawnovaný subagent, nebo libovolný jiný LLM (ChatGPT, Codex, …). Záznamy tak vznikají průběžně bez manuálního zásahu.

**Příklad dialogu:**

> Ty (nebo agent): `/lore new lesson`
>
> Claude: "O čem je lekce? Popiš problém nebo poznatek — klidně jen jednou větou."
>
> Ty (nebo agent): "GitHub API vrací base64 obsah souboru s newlinami uprostřed řetězce."
>
> Claude:
> ```
> Navrhuji záznam:
>   typ:    gotcha
>   název:  "GitHub API vrací base64 s newlinami"
>   tagy:   [github-api, encoding, base64]
>
> Chceš upravit, nebo rovnou zapsat?
> ```

### 4. Validuj a commitni

**V Claude Code (slash command):**
```
/lore validate
/lore git commit "lore: přidána lekce o X"
```

### 5. Spusť inteligentní analýzu (volitelné)

Po nasbírání alespoň 10 záznamů:

**V Claude Code (slash command):**
```
/intel-pass --scope lessons
```

Výstup jsou hypotézy pro nové záznamy — ty vždy rozhoduješ, co zapsat.

---

## Claude Code Skills — instalace a použití

`memory-neur` obsahuje sadu Claude Code skills pro práci s `~/.lore/` — centrálním lore repozitářem sdíleným napříč projekty.

| Skill | Popis |
|---|---|
| `/lore <subcommand>` | Práce s lore záznamy: `new`, `link`, `extract`, `validate`, `audit`, `git` |
| `/intel-pass` | Inteligentní analýza nad `~/.lore/` (Opus + extended thinking) |

### Instalace

```bash
# Instalace do ~/.claude/commands/ + inicializace ~/.lore/ struktury
make install-skills

# Odebrání
make uninstall-skills
```

Podrobná dokumentace: [skills/README.md](skills/README.md).

---

## Lore záznamy v tomto repozitáři (ukázkové příklady)

Adresář `lore/` v tomto repozitáři obsahuje ukázkové záznamy — projekt sám sebe používá jako příklad. **Tvé záznamy nejdou sem.** Tvé záznamy jdou do `~/.lore/` na tvém systému.

| Co najdeš v `lore/` | Účel |
|---|---|
| `lore/lessons/` | Příklady technických lekcí ze vývoje memory-neur |
| `lore/decisions/` | Architektonická rozhodnutí projektu (ADR záznamy) |
| `lore/projects/memory-neur.md` | Projektový kontext |
| `lore/personas/` | Profily agentů |

Schémata a validační pravidla: [lore/README.md](lore/README.md).

---

## Typy záznamů

| Typ | Adresář | K čemu slouží | Příklad |
|-----|---------|---------------|---------|
| **lessons** | `lessons/` | Technické pasti, anti-patterny, heuristiky, principy, drobná rozhodnutí | `gotcha`: GitHub API vrací base64 s newlinami |
| **decisions** | `decisions/` | Vědomá architektonická nebo produktová rozhodnutí s alternativami a statusem (ADR) | Volba slug místo UUID jako ID záznamu |
| **processes** | `processes/` | Opakující se workflow, checklisty, rituály, automatizace | Pre-release checklist před deploymentem |
| **projects** | `projects/` | Kontext projektů — co se řeší, co bylo rozhodnuto, stav | `memory-neur` — znalostní báze agentů |
| **personas** | `personas/` | Profily agentů a rolí relevantních pro projekt | `claude-code` — role a kontext AI agenta |

### Typy lekcí (`type` ve frontmatteru)

- `gotcha` — technická past nebo nečekané chování systému
- `anti-pattern` — postup, který vypadá rozumně, ale škodí
- `preference` — subjektivní volba týmu (není absolutní pravda)
- `decision-minor` — vědomé rozhodnutí bez alternativ; pro ADR s alternativami použij `decisions/`
- `heuristika` — pravidlo palce, platí často, ne vždy
- `principle` — trvalý axiom

---

## Přehled struktury repozitáře

```
lore/
  lessons/      ← ukázkové technické poznatky a principy
  decisions/    ← ukázkové ADR záznamy s alternativami a statusem
  processes/    ← ukázkové workflow, checklisty, rituály
  projects/     ← ukázkový projektový kontext
  personas/     ← ukázkové profily agentů a rolí
scripts/
  validate-lesson.sh    ← validace jednotlivého záznamu
  validate-all.sh       ← validace celého lore
  audit-conflicts.sh    ← kontrola konfliktních záznamů
skills/
  lore/         ← /lore skill (zdrojový kód)
  intel-pass/   ← /intel-pass skill (zdrojový kód)
```

---

## Jak přidat záznam (manuálně, bez skills)

Preferovaný způsob je přes `/lore new <type>` v Claude Code. Manuální postup pro případ, kdy skills nejsou nainstalované:

1. Zvol správný typ záznamu (viz přehled výše).
2. Zkopíruj šablonu (`_template.md`) z příslušného adresáře ve `~/.lore/`.
3. Pojmenuj soubor: `YYYY-MM-DD-<slug>.md` (lessons, decisions) nebo `<slug>.md` (processes, personas, projects).
4. Vyplň povinné frontmatter pole: `date`, `type`, `tags`, `schema_version`.
5. Napiš tělo záznamu: 3–7 řádků, konkrétně a bez zbytečného žargonu.
6. Spusť validaci:

**V terminálu:**
```bash
bash scripts/validate-lesson.sh ~/.lore/lessons/YYYY-MM-DD-muj-poznatek.md
# nebo celé lore:
bash scripts/validate-all.sh
```

7. Commitni změny v `~/.lore/`.
