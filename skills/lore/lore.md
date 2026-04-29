---
name: lore
description: Dispatcher skill pro práci s ~/.lore/ repozitářem. Subcommands: new, link, extract, validate, audit, git.
argument-hint: "<subcommand> [args...] — subcommands: new <type> | link <record> | extract <source> | validate [--filter <type>] | audit | git <op>"
---

# /lore dispatcher

Tyto instrukce jsou pro tebe (Claude). Uživatel zavolal `/lore $ARGUMENTS`.

## Krok 0 — Prerekvizita: ověř existenci ~/.lore/

Jako PRVNÍ krok před čímkoli jiným spusť:

```bash
ls ~/.lore/
```

Pokud příkaz selže (adresář neexistuje), ZASTAV SE a vypiš tuto chybu:

```
CHYBA: ~/.lore/ neexistuje.

Proveď inicializaci:
  1. make install-skills       # vytvoří adresářovou strukturu ~/.lore/
  2. cd ~/.lore && git init    # inicializuje git repozitář (jednorázově)
  3. Volitelně: git remote add origin git@github.com:<user>/lore-personal.git

Poté spusť /lore znovu.
```

Nepokračuj dokud ~/.lore/ neexistuje.

---

## Krok 1 — Parsování $ARGUMENTS

Celý řetězec argumentů je: `$ARGUMENTS`

Parsuj: první token (oddělený mezerou) je **subcommand**. Zbytek jsou argumenty pro daný subcommand.

Proveď routing:

- `new` → sekce NEW
- `link` → sekce LINK
- `extract` → sekce EXTRACT
- `validate` → sekce VALIDATE
- `audit` → sekce AUDIT
- `git` → sekce GIT
- `intel-pass` → SPECIÁLNÍ CHYBA (viz níže)
- cokoliv jiného → NEZNÁMÝ SUBCOMMAND

### Neznámý subcommand

Pokud subcommand není v seznamu výše, vypiš:

```
CHYBA: Neznámý subcommand '<subcommand>'.

Dostupné subcommands:
  /lore new <type>              Vytvoří nový lore záznam (lesson|decision|project|process|persona)
  /lore link <record>           Navrhne a aplikuje cross-reference edges pro záznam
  /lore extract <source>        Extrahuje kandidátní záznamy ze zdrojového souboru (DRAFT only)
  /lore validate [--filter <type>]  Validuje všechny záznamy v ~/.lore/
  /lore audit                   Detekuje dangling cross-reference refs
  /lore git <op>                Git operace nad ~/.lore/ (commit|push|pull|status|log)
```

### Speciální chyba pro intel-pass

Pokud uživatel napsal `/lore intel-pass`, vypiš:

```
CHYBA: 'intel-pass' není subcommand /lore.

/intel-pass je samostatný top-level skill — spusť ho takto:
  /intel-pass [--scope lessons|projects|all] [--focus "oblast zaměření"]

Důvod oddělení: /intel-pass vždy spouští claude-opus-4-7 s extended thinking.
Pokud by byl subcommandem /lore, model specifikace by mohla být tiše obejita.
```

---

## Sekce NEW — `/lore new <type>`

Argumenty: první token za `new` je `<type>`.

### Krok N-1 — Ověř typ

Platné typy: `lesson`, `decision`, `project`, `process`, `persona`

Pokud typ není v seznamu, vypiš:
```
CHYBA: Neznámý typ '<type>'.
Dostupné typy: lesson | decision | project | process | persona
```
A zastav se.

### Krok N-2 — Načti schéma

Spusť:
```bash
cat ~/.lore/<type>/_schema.yml
```

Pokud soubor neexistuje, vypiš varování a pokračuj s obecnými poli (date, type, tags, schema_version, title, summary).

### Krok N-3 — Vyžádej frontmatter od uživatele (LLM)

Na základě schématu ze kroku N-2 identifikuj povinná pole (sekce `required:`). Zeptej se uživatele na hodnoty. Pro každé povinné pole, které uživatel neposkytl, se ptej dokud ho nedostaneš.

Volitelná pole navrhni s rozumnými výchozími hodnotami a zeptej se uživatele zda je chce změnit.

Vygeneruj `slug` ve formátu `YYYY-MM-DD-<stručný-popis>` (kebab-case, max 50 znaků). Navrhni slug uživateli, počkej na potvrzení nebo úpravu.

### Krok N-4 — Načti šablonu a doplň pole (LLM)

Spusť:
```bash
cat ~/.lore/<type>/_template.md
```

Doplň frontmatter a tělo šablony hodnotami od uživatele. Zachovej strukturu šablony.

Výsledný obsah zobraz uživateli k potvrzení před zápisem.

### Krok N-5 — Zapiš soubor (bash)

Po potvrzení uživatele:

```bash
# Ověř, že soubor ještě neexistuje
ls ~/.lore/<type>/<slug>.md 2>/dev/null && echo "EXISTS" || echo "OK"
```

Pokud soubor existuje, zastav se a ptej se uživatele zda přepsat.

Pak zapiš soubor přes Write tool do `~/.lore/<type>/<slug>.md`.

### Krok N-6 — Validace (bash)

```bash
bash ~/.lore/scripts/validate-<type>.sh ~/.lore/<type>/<slug>.md
```

Pokud skript neexistuje, zkus:
```bash
bash ~/.lore/scripts/validate-all.sh
```

Pokud validace vrátí FAIL:
- Zobraz chybu uživateli
- Identifikuj konkrétní pole které selhalo
- Nabídni opravu
- Po opravě spusť validaci znovu (loop dokud PASS nebo uživatel nezruší)

Pokračuj pouze pokud validace prošla (PASS).

### Krok N-7 — Link logika (LLM+bash)

Proveď kroky ze sekce LINK pro nově vytvořený soubor `~/.lore/<type>/<slug>.md`.

Pokud link logika selže nebo nenajde žádné edges, pokračuj s varováním — nezastavuj celý proces.

### Krok N-8 — Git commit (bash)

Proveď kroky ze sekce GIT s operací `commit`:
- commit message: `lore: add <type>/<slug>`

Pokud git není dostupný nebo `~/.lore/` není git repo, vypiš varování a zastav se (soubor byl vytvořen, commit přeskočen).

**Výstup po dokončení:**
```
✓ Vytvořen: ~/.lore/<type>/<slug>.md
✓ Validace: PASS
✓ Edges: <počet> edges aplikováno (nebo "žádné edges nenalezeny")
✓ Commit: <commit hash>
```

---

## Sekce LINK — `/lore link <record>`

Argumenty: `<record>` je cesta k souboru v `~/.lore/`. Může být absolutní nebo relativní od `~/.lore/`.

### Krok L-1 — Normalizuj cestu a ověř existenci záznamu

Pokud cesta nezačíná `/`, prepend `~/.lore/`. Spusť:
```bash
ls <absolutní-cesta>
```

Pokud soubor neexistuje, zastav se s chybou.

### Krok L-2 — Načti frontmatter záznamu (LLM)

Přečti soubor záznamu. Extrahuj frontmatter pole: `tags`, `slug` (z názvu souboru), `source_project`, `context`, existující `related`, existující `lessons`.

### Krok L-3 — Zjisti kandidátní soubory (bash)

```bash
find ~/.lore -name "*.md" ! -name "_template.md" ! -name "_schema.yml" 2>/dev/null
```

Přečti frontmatter kandidátních souborů. Vynech soubor samotný (nesmí odkazovat sám na sebe).

### Krok L-4 — Navrhni edges (LLM)

Na základě sémantické blízkosti navrhni edges:
- Porovnej `tags` — shoda tagů = silný signál
- Porovnej `source_project` — stejný projekt = relevantní
- Porovnej `context` — sémantická blízkost témat
- Porovnej slugy — podobné názvy mohou naznačovat vztah

Pro každý navržený edge uveď:
- target: `<type>/<slug>` (kanonický formát)
- pole: `related` nebo `lessons` (dle typu vazby)
- reasoning: 1–2 věty proč je edge relevantní

### Krok L-5 — Ověř existenci targetů (bash)

Pro každý navržený edge:
```bash
ls ~/.lore/<type>/<slug>.md
```

Pokud soubor neexistuje → edge PŘESKOČ (nenavrhuješ hallucinated slugy). Zapiš do výstupu které edges byly přeskočeny.

### Krok L-6 — Sestav YAML patch (LLM)

Pro ověřené edges sestav patch — aktualizuj `related:` a/nebo `lessons:` pole v frontmatteru záznamu. Zachovej existující hodnoty, přidej nové (bez duplikátů).

### Krok L-7 — Aplikuj patch (bash)

Uprav soubor pomocí Edit tool — přidej/aktualizuj `related:` a `lessons:` sekce ve frontmatteru.

### Krok L-8 — Validace po aplikaci (bash)

```bash
bash ~/.lore/scripts/validate-<type>.sh <soubor>
```

Pokud validace selže:
- Zobraz chybu
- Rollback: vrať frontmatter do stavu před patchem
- Reportuj uživateli co selhalo

### Výstup:

```
Navržené edges:
  + related: lessons/<slug-a>  (reasoning)
  + related: decisions/<slug-b>  (reasoning)
  - lessons/<nonexistent>  PŘESKOČEN (soubor neexistuje)

✓ Patch aplikován
✓ Validace: PASS
```

Pokud žádné edges: `lore link: žádné relevantní edges nenalezeny pro <record>`

---

## Sekce EXTRACT — `/lore extract <source>`

Argumenty: `<source>` je cesta k souboru. Volitelné přepínače: `--target-types <typy>`, `--write-drafts`.

### Krok E-1 — Ověř existenci source souboru (bash)

```bash
ls <source>
```

Pokud soubor neexistuje, zastav se s chybou: `CHYBA: Soubor '<source>' nenalezen.`

### Krok E-2 — Parsuj přepínače

- `--target-types <typy>`: filtr typů oddělených čárkou (např. `lesson,process`). Default: `lesson,decision,project,process,persona`
- `--write-drafts`: pokud přítomen, zapíše drafty do `artifacts/draft/` (viz krok E-4)

### Krok E-3 — Analýza source souboru (LLM)

Přečti source soubor. Identifikuj kandidátní záznamy dle pravidla "1 paragraph → 1 atomický record":
- Každý kandidát musí být self-contained (pochopitelný bez kontextu)
- Navrhni typ: lesson / decision / process / project / persona
- Navrhni frontmatter: slug, title, tags, summary, type, date
- Uveď reasoning pro každý kandidát

Respektuj filtr `--target-types` — ignoruj paragrafy jejichž typ není v filtru.

**INVARIANT**: Výstup je vždy DRAFT. Bash NIKDY nepíše přímo do `~/.lore/`.

### Krok E-4 — Výstup

Vypiš na stdout pro každý kandidát:

```
### Kandidát <N>: <navrhovaný-slug>
typ: <type>
frontmatter:
  date: <YYYY-MM-DD>
  type: <subtype>
  tags: [<tag1>, <tag2>]
  title: "<title>"
  summary: "<summary>"
  schema_version: "1.1"
zdůvodnění: <proč je toto atomický záznam>
tělo (návrh):
<navrhovaný obsah záznamu>
---
```

Na konec vypiš:
```
### Paragrafy bez mapování:
- <popis paragrafu> (důvod: <proč nebyl mapován>)
```

Pokud je přítomen `--write-drafts`:
- Zkus: `ls artifacts/draft/ 2>/dev/null || echo "NEXIST"`
- Pokud adresář existuje, zapiš každý draft jako `artifacts/draft/<slug>.md`
- Pokud neexistuje, vypiš varování: `WARN: artifacts/draft/ neexistuje, drafty nebyly zapsány`

**PŘIPOMENUTÍ**: Výstup tohoto subcommandu jsou DRAFTY. Pro commit do `~/.lore/` použij `/lore new` pro každý kandidát zvlášť.

---

## Sekce VALIDATE — `/lore validate`

Argumenty: volitelný `--filter <type>`.

### Krok V-1 — Ověř dostupnost validate skriptů (bash)

```bash
ls ~/.lore/scripts/validate-all.sh
```

Pokud neexistuje, zastav se s chybou:
```
CHYBA: ~/.lore/scripts/validate-all.sh nenalezen nebo není spustitelný.
Ujisti se, že ~/.lore/ je inicializováno a validate skripty existují.
```

### Krok V-2 — Spusť validaci (bash)

Bez `--filter`:
```bash
bash ~/.lore/scripts/validate-all.sh
```

S `--filter <type>`:
```bash
bash ~/.lore/scripts/validate-<type>.sh
```

### Krok V-3 — Výstup

Zobraz výstup skriptu. Doplň souhrn ve formátu:
```
Výsledky validace:
  PASS:  <N> souborů
  WARN:  <N> souborů  
  FAIL:  <N> souborů

<pokud FAIL: identifikuj root cause>
  Nejčastější příčiny selhání:
  - Chybějící povinné pole (date, type, tags, schema_version)
  - Neznámá hodnota enum (type, confidence, conflict_status)
  - Neplatný formát (datum, slug)
```

Exit code interpretace: 0 = clean, 1 = FAIL, 2 = WARN only.

---

## Sekce AUDIT — `/lore audit`

Žádné argumenty.

**Tato sekce je čistě bash — LLM NEPROVÁDÍ analýzu.**

### Krok A-1 — Sbírej záznamy (bash)

```bash
find ~/.lore -name "*.md" ! -name "_template.md" ! -name "_schema.yml" 2>/dev/null
```

### Krok A-2 — Extrahuj cross-reference hodnoty (bash)

Pro každý soubor extrahuj hodnoty z frontmatter polí `lessons:`, `related:`, `source_project:`:

```bash
grep -h "^  - " ~/.lore/**/*.md 2>/dev/null | sort -u
```

Nebo sekvenčně přes find + grep kombinaci pro každý soubor.

### Krok A-3 — Ověř existenci cílů (bash)

Pro každou cross-reference hodnotu ve formátu `<type>/<slug>`:
```bash
ls ~/.lore/<type>/<slug>.md 2>/dev/null && echo "OK" || echo "MISSING: <type>/<slug>"
```

### Krok A-4 — Výstup

Pokud žádné dangling refs:
```
lore: 0 dangling refs
Všechny cross-reference záznamy jsou validní.
```

Pokud existují dangling refs:
```
lore audit: nalezeny dangling refs

Zdroj                                    → Chybějící cíl
~/.lore/lessons/2024-01-01-example.md    → lessons/nonexistent-slug
~/.lore/decisions/2024-02-01-arch.md     → projects/missing-project

Celkem: <N> dangling refs v <M> souborech
Oprav je pomocí /lore link nebo ručně.
```

---

## Sekce GIT — `/lore git <op>`

Argumenty: `<op>` je operace. Pro `commit` je povinná commit message jako druhý argument.

### Krok G-1 — Ověř, že ~/.lore/ je git repo (bash)

```bash
git -C ~/.lore/ status
```

Pokud selže, zastav se s chybou:
```
CHYBA: ~/.lore/ není git repozitář nebo neexistuje.

Inicializace:
  cd ~/.lore && git init
  git remote add origin git@github.com:<user>/lore-personal.git  # volitelné
  git add -A && git commit -m "init: initial lore repository"
```

### Krok G-2 — Proveď operaci (bash)

**commit** (vyžaduje message):
```bash
cd ~/.lore && git add -A && git commit -m "<message>"
```
Pokud message není poskytnuta, zastav se: `CHYBA: commit vyžaduje zprávu. Použití: /lore git commit "zpráva commitu"`

**push**:
```bash
git -C ~/.lore/ push
```
Pokud selže kvůli dirty working tree nebo merge konfliktu, vypiš konkrétní chybu bez automatické akce.

**pull**:
```bash
git -C ~/.lore/ status --porcelain
```
Pokud dirty working tree (výstup neprázdný), varuj uživatele a neprováděj pull automaticky. Pokud clean:
```bash
git -C ~/.lore/ pull
```
Při merge konfliktu: vypiš popis konfliktu, požaduj manuální řešení.

**status**:
```bash
git -C ~/.lore/ status
```

**log**:
```bash
git -C ~/.lore/ log --oneline -20
```

Neznámá operace → vypiš:
```
CHYBA: Neznámá git operace '<op>'.
Dostupné operace: commit "<message>" | push | pull | status | log
```

### Výstup

Vypiš stdout git příkazu. Přidej strukturovaný status řádek:
```
lore git <op>: OK  (nebo: FAILED — <důvod>)
```

---

## Poznámky pro implementaci

- **LLM vs bash boundary je pevná**: LLM analyzuje a navrhuje; bash mechanicky provádí (zápis, git, validace, existence checks).
- **Vždy ověř existenci souboru bash nástrojem** (`ls`), nikdy LLM inference.
- **Validace před commitem**: krok N-6 musí proběhnout před N-8 — toto pořadí je invariant.
- **Extract je vždy DRAFT**: bash nikdy nezapisuje do `~/.lore/` v rámci extract subcommandu.
- **Git operace výhradně nad `~/.lore/`**: /lore git nikdy neprovádí operace nad aktuálním projektem.
