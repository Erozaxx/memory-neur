# Session Log: iter-003 implementace
**Datum**: 2026-04-29  
**Cíl**: Smoke test lore-repo architektury — naplnit ~/Develop/CLAUDE/tsp_cto lore/ záznamy z TSP_Data_CTO  
**Účel tohoto logu**: Dokumentovat každý krok pro budoucí extrakci skills pro práci s pamětí

---

## Kontext před zahájením

- `memory-neur` repo: schémata lore/ hotová (iter-001/iter-002), validate-all.sh funkční
- `tsp_cto` repo: prázdný, upstream `git@github.com:Erozaxx/tsp_cto.git`, lokálně na `~/Develop/CLAUDE/tsp_cto`
- Zdrojová data: `~/02_Areas/TSP_Data_CTO/` (15 klientských složek, ~80 .md souborů)
- Mapping dokument: `.aiworkflow/agents/architect/artifacts/final/mapping_iter-003.md` (po review + opravách)

---

## T-004 — Schválení návrhu (human gate)

**Čas**: ~15:10 UTC  
**Rozhodnutí**: Schváleno uživatelem s podmínkou auditovaného trailu  
**Podmínky implementace**:
1. Tento session log musí být průběžně aktualizován
2. Každý krok zdokumentován (co, proč, jak)
3. Cíl: budoucí extrakce skills pro práci s pamětí

---

## T-005 — Setup ~/Develop/CLAUDE/tsp_cto

**Plán**:
1. Ověřit, že tsp_cto repo existuje a je čisté
2. Zkopírovat scripts/ ze memory-neur (validate-all.sh, validate-lesson.sh, atd.)
3. Vytvořit lore/ adresářovou strukturu se schématy a šablonami
4. Přidat .gitignore
5. Commit a push

**Provedeno**:
- `mkdir -p ~/Develop/CLAUDE/tsp_cto/lore/{lessons,decisions,projects,processes,personas}`
- `mkdir -p ~/Develop/CLAUDE/tsp_cto/scripts/`
- Zkopírovány všechny `scripts/*.sh` z memory-neur (validate-lesson, validate-project, validate-process, validate-decision, validate-persona, validate-all, audit-conflicts, _validate-common)
- Zkopírována schémata `_schema.yml` a šablony `_template.md` pro všech 5 lore/ typů
- Vytvořen `.gitignore` (.aiworkflow/, .DS_Store, *.swp)
- **Pozorování**: Přímé zkopírování scripts/ a schémat z memory-neur funguje — tsp_cto je "instance" stejné architektury

---

## T-006 — lore/projects/

**Plán**: Vytvořit záznamy pro 12 klientů/partnerů dle mapping dokumentu  
**Klíčové pravidlo**: Kontakty jsou sekce v těle záznamu, NE samostatné personas/

**Provedeno**:
Vytvořeny záznamy pro 11 klientů/partnerů (dle mapping_iter-003.md sekce 1):
- `h3a-drei.md` — UA projekt, service support pipeline, Hoffmann + Schimek
- `sobit.md` — PoC AI agenti nad DB, workshop, Sobotovič + Moravec
- `raiffeisen.md` — FinOps centralizace, FOCUS standard, Balšánek
- `bootiq-veacom.md` — damage control, 3 infravarianty, Hacker + Kalvoda + Havel
- `wia.md` — oboustranný partner + hosting, Šimpach
- `zeppelin.md` — FinOps on-prem, CFO argumentace, kontakty TBD
- `bni.md` — chapter + Global RFP 2026, koalice TSP+BootIQ+ReVitta+Alllog
- `grafana-labs.md` — pre-JBP partnerství, Obry + Rattay
- `redhat.md` — AI portfolio orientace, go-to-market pozice
- `cra.md` — change requesty + AI vzdělávání
- `optare.md` — re-engagement Spain, status paused
- `telefonica-de.md` — re-engagement Germany, status paused

**Vzorec záznamu** (pro budoucí skill):
```
frontmatter: date, type (client/internal), tags, schema_version, status, title, summary, author
tělo: popis zákazníka, ## Aktuální engagement, ## Pipeline/Status, ## Contacts (jméno — role, context), ## Zdrojové soubory
```

**Pozorování**:
- Oddělení contacts jako sekce v těle funguje přirozeně — informace jsou bohatší než by umožnoval frontmatter
- `status: paused` pro re-engagement projekty bez odpovědi — konzistentní s enum (active/paused/completed/abandoned)
- Partner projekty (Grafana Labs, Red Hat, WIA) mapovány jako `type: client` (schéma nemá `partner`)

---

## T-007 — lore/lessons/ (ze zdrojových .md)

**Plán**: Extrahovat atomické lessons ze 9 identifikovaných zdrojových souborů  
**Očekávaný počet**: 17+ záznamů

**Provedeno**:
- 15 lesson záznamů vytvořeno ze zdrojových .md souborů (SobIT, BootIQ/Veacom, Raiffeisen/Zeppelin, H3A/drei, Red Hat)
- Kategorizace: 4× gotcha, 5× heuristika, 3× principle, 2× preference, 1× anti-pattern
- Každý záznam: atomický (1 poučení), 3–7 vět prózy, `source_project` a `projects` cross-reference
- **Pozorování**: BD lessons mají jiný charakter než technické lessons — jsou o chování, komunikaci a prodeji

---

## T-008 — lore/lessons/ (generické z ~/.claude)

**Plán**: Extrahovat přenositelné lessons z TSP CTO memory (feedback soubory)  
**Poznámka**: memory-neur MEMORY.md cesta neexistuje, použita TSP CTO memory

**Provedeno**:
- Přečteny: `feedback_proposal_format.md`, `feedback_init_iteration_workflow.md`
- 2 záznamy extrahovány: `html-onepager-standard-format-confirmed.md`, `bd-project-no-software-agent-workflow.md`
- **Pozorování**: Claude memory (feedback soubory s Why/How to apply) se snadno mapuje na lore/lessons/ — struktura koresponduje

---

## T-009 — lore/processes/

**Plán**: Vytvořit 5 procesních záznamů (P-001 až P-005)

**Provedeno**:
- `finops-discovery-workflow.md` — 5-blokový workflow
- `client-proposal-html-onepager.md` — HTML onepager tvorba
- `poc-ai-agents-db-workflow.md` — 2-fázový PoC
- `bni-1on1-ritual.md` — BNI meeting ritual
- `re-engagement-email-workflow.md` — email šablona
- **Vzorec**: trigger → předpoklady → kroky → výstup → reference

---

## T-010 — Validace + commit + push

**Plán**:
1. Scripts zkopírovány v T-005
2. Spustit validate-all.sh na tsp_cto
3. Opravit chyby
4. `git add`, `git commit`, `git push`

**Provedeno**:
- `bash scripts/validate-all.sh` → **34/34 OK, 0 FAIL, 0 WARN** (bez nutnosti oprav)
- `git commit -m "feat(iter-003): initial lore/ structure with TSP CTO BD knowledge"`
- `git push -u origin main` → PUSH OK → `git@github.com:Erozaxx/tsp_cto.git`
- **Pozorování**: Schémata z memory-neur fungovala bez modifikace — lore/ architektura je přenositelná

---

## Fixup — Cross-reference edges (po review uživatele)

**Trigger**: Uživatel upozornil, že žádný project záznam nemá `related:` ani `lessons:` edges — chyběly cross-reference vazby.

**Příčina**: Při vytváření project záznamů (T-006) byly edges vynechány — nebyly součástí explicitního task scopy a orchestrátor je při psaní souborů neaplikoval.

**Opraveno**:
- `h3a-drei.md` → `lessons:` [4 záznamy], `related:` [processes/client-proposal-html-onepager]
- `sobit.md` → `lessons:` [3 záznamy], `related:` [processes/poc-ai-agents-db-workflow]
- `raiffeisen.md` → `lessons:` [2 záznamy], `related:` [processes/finops-discovery-workflow, projects/zeppelin]
- `zeppelin.md` → `lessons:` [1 záznam], `related:` [processes/finops-discovery-workflow, projects/raiffeisen]
- `bootiq-veacom.md` → `lessons:` [3 záznamy], `related:` [projects/wia]
- `redhat.md` → `lessons:` [4 záznamy]
- `bni.md` → `related:` [processes/bni-1on1-ritual, projects/bootiq-veacom, projects/wia]
- `wia.md` → `related:` [projects/bootiq-veacom, projects/bni]
- `grafana-labs.md` → `related:` [projects/cra]

**Validace**: `validate-all.sh` → 34/34 OK (edges jsou v `additionalProperties: false` schématu jako volitelná pole)

**Git**: commit `7fa2bb7` → push OK

**Pozorování**: Cross-reference edges nejsou kontrolovány validátorem (jen formát polí, ne existence odkazovaných souborů) — potenciální gap pro budoucí `audit-dangling-refs.sh` script.

---

## Observations pro budoucí skills

**1. Mapování zdrojového repozitáře na lore/ typy**
- Klientská složka s .md soubory → `lore/projects/` + lessons ze zápisků
- Meeting notes + follow-up emaily → `lore/lessons/` (heuristiky, gotchas, principy)
- Opakující se proces s kroky → `lore/processes/`
- Vědomé rozhodnutí s alternativami → `lore/decisions/`
- Claude memory feedback soubory → `lore/lessons/` (decision-minor nebo preference)

**2. Vzorec project záznamu**
Frontmatter: date, type, tags, schema_version, status, title, summary, author
Tělo: popis → Aktuální engagement → Pipeline/Status → Contacts → Zdrojové soubory

**3. Vzorec lesson záznamu**
Frontmatter: date, type, tags, schema_version, title, summary, confidence, source_project
Tělo: 3–7 vět — co se stalo, proč záleží, co dělat napříště

**4. Personas ≠ reálné kontakty**
Reálné osoby patří do sekce `## Contacts` v těle `lore/projects/`. Personas/ je STUB pro AI agent role.

**5. Přenositelnost lore/ architektury**
Celá architektura (schémata, šablony, validátory) zkopírována z memory-neur do tsp_cto bez modifikace.

**6. validate-all.sh jako quality gate**
Spustit PŘED commitem. 0 chyb při prvním spuštění = správně aplikovaný vzorec záznamu.

**7. Cross-reference edges jsou povinné, ne volitelné**
`lessons:` a `related:` v projects/ nejsou kosmetika — jsou to hrany grafu. Bez nich je znalostní báze fragmentovaná. Validátor je nezachytí.

**8. Intel-analyst jako Opus s extended thinking**
První run intel-analystu na tsp_cto lore/ (34 záznamy) → 10 patterns, 5 gaps, 3 conflicts, 6 latent heuristics, 5 kandidátních záznamů. Nejsilnější hypotézy: "low-commitment entry point" (HIGH, 4 záznamy) a "proactive transparency as trust engine" (HIGH, 3 záznamy ze stejného dne). Runtime: 529s, 87k tokenů.

**9. Intel-analyst epistemická disciplína funguje — a human review ji zachraňuje**
Kandidátní záznamy jsou správně označeny [HYPOTÉZA], mají confidence level, reasoning sekci a nejsou zapsány do lore/. Pipeline draft→review→lore/ je správný.

Konkrétní příklad selhání analysta zachyceného reviewem: kandidát "partnership-as-bidirectional-pipeline" (MEDIUM) byl zamítnut — intel-analyst přečetl WIA jako oboustranné partnerství, ale WIA je ve skutečnosti BD příležitost (potenciální zákazník). Skutečný vzorec je opačný: Red Hat + Zabbix jsou příklady fungujícího vendor partnerství, Grafana Labs je pokus o replikaci tohoto modelu. Project záznam `wia.md` neměl dostatečný kontext pro správnou inferenci.

**Implikace pro intel-analyst**: MEDIUM confidence hypotézy o partnerstvích/vztazích vyžadují silnější human validaci než technické gotchy. Vztahový kontext není v záznamu — je v hlavě autora.

---

## Nový agent: intel-analyst

**Trigger**: Diskuse o tom, kdo by dělal self-learning loop nad lore/ záznamy.

**Rozhodnutí**: Nový agent `intel-analyst` (Intelligence Analyst) — prochází záznamy jako detektiv případ, hledá implicitní vzory, mezery, protiřečení a latentní heuristiky. Výstupy jsou **hypotézy** (`[HYPOTÉZA]`), ne fakta — s confidence level (HIGH/MEDIUM/LOW) a zdrojovými záznamy.

**Proč ne "synthesizer"**: Synthesizer evokuje tvorbu z ničeho. Intelligence Analyst má přirozeně skeptický epistemický postoj — produkuje assessments, ne závěry.

**Proč ne existující agent**: Challenger je destruktivní (hledá chyby, ne vzory). Architect je orientovaný na design systémů. Reviewer hodnotí konkrétní výstup, ne celou znalostní bázi.

**Soubory vytvořeny**:
- `.aiworkflow/agents/intel-analyst/AGENTS.md`
- Adresářová struktura (context/inbox, outbox, artifacts/draft, final, state, logs, metrics)
- Přidán do tabulky agentů v `.aiworkflow/CLAUDE.md`

**Klíčové invarianty profilu**:
- 4 hledané kategorie: Patterns, Gaps, Conflicts, Latent Heuristics
- Confidence levels: HIGH / MEDIUM / LOW
- Kandidátní záznamy jdou do `artifacts/draft/`, NIKDY přímo do `lore/`
- Vždy přes reviewer nebo human před zápisem do lore/

---

## Observations pro budoucí skills

**7. Cross-reference edges jsou povinné, ne volitelné**
`lessons:` a `related:` v projects/ nejsou kosmetika — jsou to hrany grafu znalostní báze. Při vytváření project záznamu je nutné ihned doplnit edges na odvozené lessons a procesy. Bez nich je znalostní báze fragmentovaná. Chybějící edges validátor nezachytí — je to výhradně na disciplíně autora záznamu.

