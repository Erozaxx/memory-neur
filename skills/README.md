# skills/

Source of truth pro Claude Code skills v tomto repozitáři.

## Co je `skills/`

Adresář `skills/` obsahuje Claude Code slash-command soubory (`.md`) připravené k instalaci.
Po instalaci jsou dostupné jako `/lore` a `/intel-pass` přímo v Claude Code.

```
skills/
├── lore/
│   └── lore.md          — slash command /lore (vytváří T-005 agent)
└── intel-pass/
    └── intel-pass.md    — slash command /intel-pass (vytváří T-006 agent)
```

## Prerekvizity

- [Claude Code](https://claude.ai/code) nainstalovaný a funkční
- `make` (GNU Make)
- `git`

## Jak instalovat

```bash
make install-skills
```

Příkaz:
- Zkopíruje `skills/lore/lore.md` a `skills/intel-pass/intel-pass.md` do `~/.claude/commands/`
- Vytvoří `~/.lore/` adresářovou strukturu (lessons, decisions, projects, processes, personas, scripts)
- Zkopíruje validační skripty z `scripts/` do `~/.lore/scripts/`
- Zkopíruje schémata a šablony z `lore/<type>/` do `~/.lore/<type>/`

## Jak upgradovat

Edituj příslušný `.md` soubor v `skills/` a znovu spusť:

```bash
make install-skills
```

Operace je idempotentní — přepíše existující verze.

## Jak odebrat

```bash
make uninstall-skills
```

Odebere skills z `~/.claude/commands/`. Data v `~/.lore/` jsou zachována.
