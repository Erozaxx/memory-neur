---
name: lore
description: Dispatcher skill pro práci s ~/.lore/ repozitářem. Subcommands: new, link, extract, validate, audit, map, git.
argument-hint: "<subcommand> [args...] — subcommands: new <type> | link <record> | extract <source> | validate [--filter <type>] | audit | map [--open] | git <op>"
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
- `map` → sekce MAP
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
  /lore map [--open]            Vygeneruje/aktualizuje grafovou mapu paměti
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

Argumenty: první token za `new` je `<type>`. Volitelný přepínač: `--from-draft <path>` načte existující draft místo inference z kontextu.

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

### Krok N-3 — Inferuj a navrhni kompletní draft (LLM)

Načti šablonu:
```bash
cat ~/.lore/<type>/_template.md
```

Pokud byl zadán `--from-draft <path>`:
```bash
cat <path>
```
Použij obsah draftu jako základ. Doplň nebo oprav pole která chybí nebo mají `TODO`.

Jinak: na základě schématu (N-2) a aktuálního konverzačního kontextu inferuj hodnoty všech polí — povinných i volitelných. Nevyptávej se uživatele na jednotlivá pole.

Pravidla inference:
- `date`: dnešní datum (YYYY-MM-DD)
- `title`, `summary`, `tags`, `type`: odvoď z kontextu session (co se řešilo, jaký byl výsledek)
- `slug`: `YYYY-MM-DD-<stručný-popis>` (kebab-case, max 50 znaků), odvozeno z title
- Ostatní pole: doplň z kontextu nebo z výchozích hodnot schématu
- Pokud povinné pole nelze inferovat, doplň `TODO` — nezastavuj se

Doplň frontmatter i tělo šablony. Zachovej strukturu šablony.

Zobraz kompletní draft a zeptej se jednou: **„Chceš něco upravit? (pokud ne, rovnou pokračuju zápisem)"**

Pokud uživatel chce úpravy → aplikuj je. Pak pokračuj. Pokud ne → pokračuj okamžitě.

### Krok N-4 — (přeskočen — sloučen s N-3)

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
- Identifikuj konkrétní pole které selhalo (znáš schéma z N-2)
- Oprav ho automaticky — nepotřebuješ se ptát uživatele na základní schema chyby
- Přepiš soubor přes Edit tool
- Spusť validaci znovu (loop dokud PASS, max 3 pokusy; po 3. selhání reportuj uživateli a zastav)

Pokračuj pouze pokud validace prošla (PASS).

### Krok N-7 — Link logika (LLM+bash)

Proveď kroky ze sekce LINK pro nově vytvořený soubor `~/.lore/<type>/<slug>.md`.

Pokud link logika selže nebo nenajde žádné edges, pokračuj s varováním — nezastavuj celý proces.

Mapa paměti se pro `/lore new` NEregeneruje samostatným krokem (zrušeno RC2/iter-006,
bývalý Krok N-7.5) — pre-commit hook v N-8 (`lore-map-precommit.sh`) ji regeneruje a
nastageuje automaticky před commitem, takže samostatný krok počítal stejný
byte-identický výstup zbytečně 2×.

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
Limit: čti maximálně 100 souborů — pokud `find` vrátí více, vezmi posledních 100 (seřazeno dle data v názvu souboru sestupně). Na velkém lore repozitáři je to dostatečné pro relevantní vazby.

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

### Krok L-9 — Regenerace mapy (bash, non-blocking)

```bash
bash ~/.lore/scripts/lore-map-gen.sh
```

Pokud selže: vypiš varování a POKRAČUJ. NIKDY neblokuj dokončení link operace.

`link` mění hrany, tj. přímo graf — proto se mapa regeneruje i zde. Na rozdíl od `/lore new` ale `link` sám necommituje, takže do výstupu doplň poznámku: „mapa přegenerována — commitni přes `/lore git commit`".

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
- `--write-drafts`: pokud přítomen, zapíše drafty do `~/.lore/drafts/` (viz krok E-4)

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
```bash
mkdir -p ~/.lore/drafts
```
Zapiš každý draft jako `~/.lore/drafts/<slug>.md`. Drafts jsou označeny `[DRAFT]` v title a obsahují celý navrhovaný frontmatter + tělo.
Pro přijetí draftu do lore: `/lore new <type> --from-draft ~/.lore/drafts/<slug>.md`

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

### Krok A-1 — Ověř skript (bash)

```bash
ls ~/.lore/scripts/audit-dangling-refs.sh
```

Pokud skript neexistuje, zastav se s chybou:
```
CHYBA: ~/.lore/scripts/audit-dangling-refs.sh nenalezen.
Ujisti se, že ~/.lore/ je inicializováno (make install-skills).
```

### Krok A-2 — Spusť audit (bash)

```bash
bash ~/.lore/scripts/audit-dangling-refs.sh
```

### Krok A-3 — Výstup

Předej výstup skriptu uživateli **beze změny**. Exit kód 0 = čisto (žádné dangling refs), exit kód 1 = nalezeny dangling refs.

---

## Sekce MAP — `/lore map [--open]`

Volitelný přepínač: `--open`.

**Tato sekce je čistě bash — LLM NEPROVÁDÍ analýzu.**

### Krok M-1 — Ověř generátor (bash)

```bash
ls ~/.lore/scripts/lore-map-gen.sh
```

Pokud skript neexistuje, zastav se s chybou:
```
CHYBA: ~/.lore/scripts/lore-map-gen.sh nenalezen.
Ujisti se, že ~/.lore/ je inicializováno (make install-skills).
```

### Krok M-2 — Spusť regeneraci (bash)

```bash
bash ~/.lore/scripts/lore-map-gen.sh
```

### Krok M-3 — Výstup

Vypiš `node_count`, `edge_count` a `dangling_count` z `meta` výsledného `graph.json`.

Cesta (Linux): `~/.lore/map/index.html`

Pokud byl zadán `--open`:

```bash
if grep -qi microsoft /proc/version; then
  # WSL — vypiš OBĚ formy cesty
  #   Windows:  explorer.exe "$(wslpath -w ~/.lore/map/index.html)"
  #             (nebo doslovná UNC cesta: \\wsl.localhost\<distro>\home\<user>\.lore\map\index.html)
  #   Linux:    file://$HOME/.lore/map/index.html   (funguje jen v Linux prohlížeči)
  explorer.exe "$(wslpath -w ~/.lore/map/index.html)"
else
  # ne-WSL — jedna forma stačí
  echo "file://$HOME/.lore/map/index.html"
fi
```

Na WSL (detekováno přes `grep -qi microsoft /proc/version`) vypiš uživateli obě formy cesty (Windows i Linux) — nespoléhej na `wslview` (na cílovém stroji není nainstalován); doporučený příkaz je `explorer.exe "$(wslpath -w ~/.lore/map/index.html)"`. Mimo WSL stačí vypsat `file://$HOME/.lore/map/index.html`.

---

## Sekce GIT — `/lore git <op>`

Argumenty: `<op>` je operace. Pro `commit` je povinná commit message jako druhý argument.

**Všechny operace se delegují na binárku `lore` (`lore git <op>`) — NIKDY se nevolá `git -C ~/.lore/` přímo.**
Důvod: `~/.lore/.git/hooks/pre-commit` vynucuje, že `commit` smí projít jen když je nastaveno `LORE_CTX=1` — to nastavuje výhradně wrapper `lore git ...` (`~/.local/lib/lore/lore-git-wrapper.sh`). Přímé volání `git commit` bez tohoto kontextu je enforcement hookem zablokováno (exit 1). Wrapper navíc dává srozumitelnější chybové hlášky (offline remote, chybějící SSH klíč, chybějící repo…) než raw git.

### Krok G-0 — Ověř dostupnost binárky `lore` (bash)

```bash
command -v lore >/dev/null 2>&1 && echo OK || echo MISSING
```

Pokud `MISSING`, zastav se s chybou:
```
CHYBA: binárka `lore` není v PATH.

Git operace nad ~/.lore/ vyžadují `lore git <op>` (wrapper nastavuje kontext pro
pre-commit enforcement — přímé volání `git commit` bez tohoto kontextu je hookem zablokováno).

Zkontroluj instalaci:
  which lore
  echo $PATH
Očekávané umístění: ~/.local/bin/lore (přidej ~/.local/bin do PATH pokud chybí)
```

### Krok G-1 — Ověř, že ~/.lore/ je git repo (bash)

```bash
lore git status
```

Pokud selže, zastav se s chybou:
```
CHYBA: ~/.lore/ není git repozitář nebo neexistuje.

Inicializace:
  lore init
  # nebo ručně:
  cd ~/.lore && git init
  git remote add origin git@github.com:<user>/lore-personal.git  # volitelné
```

### Krok G-2 — Proveď operaci (bash)

**commit** (vyžaduje message):
```bash
lore git status --short
```
Zobraz výstup uživateli (co bude staged). Poté:
```bash
lore git add -A && lore git commit -m "<message>"
```
Pokud message není poskytnuta, zastav se: `CHYBA: commit vyžaduje zprávu. Použití: /lore git commit "zpráva commitu"`

Mapa paměti (`map/`) se **regeneruje a nastageuje automaticky** v `~/.lore/.git/hooks/pre-commit` (chain shim → `pre-commit-user` → `scripts/lore-map-precommit.sh`) — není potřeba volat `/lore map` ručně před commitem. Pokud regen selže, hook vypíše varování, ale commit i tak proběhne (non-blocking — stejný kontrakt jako L-9).

**push**:
```bash
lore git push
```
Pokud selže kvůli dirty working tree nebo merge konfliktu, vypiš konkrétní chybu bez automatické akce.

**pull**:
```bash
lore git status --porcelain
```
Pokud dirty working tree (výstup neprázdný), varuj uživatele a neprováděj pull automaticky. Pokud clean:
```bash
lore git pull
```
Při merge konfliktu: vypiš popis konfliktu, požaduj manuální řešení.

**status**:
```bash
lore git status
```

**log**:
```bash
lore git log --oneline -20
```

Neznámá operace → vypiš:
```
CHYBA: Neznámá git operace '<op>'.
Dostupné operace: commit "<message>" | push | pull | status | log
```

### Výstup

Vypiš stdout `lore git` příkazu. Přidej strukturovaný status řádek:
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
- **Git delegace na binárku**: /lore git nikdy nevolá `git -C ~/.lore/` přímo — vždy přes `lore git <op>`. Enforcement hook v `~/.lore/.git/hooks/pre-commit` blokuje přímý `commit` bez `LORE_CTX=1` (nastavuje ho jen wrapper binárky).
- **Mapa se regeneruje v pre-commit hooku**: `map/` se přegeneruje a nastageuje automaticky před každým commitem do `~/.lore/` (binárka, skill i ruční commit). `/lore link` (L-9) volá generátor navíc jen kvůli okamžité zpětné vazbě (link sám necommituje, takže hook v tu chvíli neběží) — hook je jeho poslední záchranná síť. `/lore new` se od RC2/iter-006 spoléhá výhradně na hook v N-8 (samostatný krok N-7.5 byl zrušen — hook regen při commitu dělal stejnou práci znovu, byte-identicky).
