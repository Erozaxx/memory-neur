.PHONY: install-skills uninstall-skills help

install-skills:
	@echo "Installing lore skills..."
	mkdir -p ~/.claude/commands/
	mkdir -p ~/.lore/lessons ~/.lore/decisions ~/.lore/projects ~/.lore/processes ~/.lore/personas ~/.lore/scripts
	cp skills/lore/lore.md ~/.claude/commands/lore.md
	cp skills/intel-pass/intel-pass.md ~/.claude/commands/intel-pass.md
	@for f in scripts/*.sh; do \
		base=$$(basename "$$f"); \
		[ "$$base" = "validate-all.sh" ] && continue; \
		cp "$$f" ~/.lore/scripts/"$$base"; \
	done
	@if [ -f ~/.lore/scripts/validate-all.sh ]; then \
		echo "WARNING: ~/.lore/scripts/validate-all.sh already exists - NOT overwritten (protecting your local version). Update it manually if the repo version has changed."; \
	else \
		cp scripts/validate-all.sh ~/.lore/scripts/validate-all.sh; \
	fi
	chmod +x ~/.lore/scripts/*.sh
	mkdir -p ~/.lore/map
	cp scripts/lore-map-template.html ~/.lore/scripts/lore-map-template.html
	@for type in lessons decisions projects processes personas; do \
		if [ -f lore/$$type/_schema.yml ]; then cp lore/$$type/_schema.yml ~/.lore/$$type/_schema.yml; fi; \
		if [ -f lore/$$type/_template.md ]; then cp lore/$$type/_template.md ~/.lore/$$type/_template.md; fi; \
	done
	@if [ ! -d ~/.lore/.git ]; then \
		echo "WARNING: ~/.lore/.git not found - skipping pre-commit hook install (run 'cd ~/.lore && git init' then re-run make install-skills)"; \
	else \
		cp scripts/lore-map-precommit.sh ~/.lore/.git/hooks/pre-commit-user; \
		chmod +x ~/.lore/.git/hooks/pre-commit-user; \
		HOOK=~/.lore/.git/hooks/pre-commit; \
		MARKER="# lore-pre-commit-shim"; \
		WRITE=0; \
		if [ -f "$$HOOK" ]; then \
			if grep -qF "$$MARKER" "$$HOOK" 2>/dev/null; then \
				if grep -q "pre-commit-user" "$$HOOK" 2>/dev/null; then \
					echo "pre-commit hook already chains pre-commit-user - skipping (idempotent)."; \
				else \
					echo "Upgrading existing lore pre-commit shim to chain pre-commit-user..."; \
					WRITE=1; \
				fi; \
			else \
				echo "WARNING: ~/.lore/.git/hooks/pre-commit exists and is NOT a lore shim (marker '$$MARKER' not found)."; \
				echo "WARNING: NOT overwriting your existing hook - chain pre-commit-user into it manually if you want map regen before commit."; \
			fi; \
		else \
			WRITE=1; \
		fi; \
		if [ "$$WRITE" = "1" ]; then \
			printf '%s\n' \
				'#!/usr/bin/env bash' \
				"$$MARKER" \
				'# Chain shim installed by memory-neur Makefile (target install-skills).' \
				'# 1) binarcin enforcement (pre-commit-impl.sh) - NESAHAT, spravuje lore binarka.' \
				'# 2) nas regen mapy pred commitem (pre-commit-user) - scripts/lore-map-precommit.sh.' \
				'' \
				'IMPL="$$(dirname "$$0")/../../scripts/hooks/pre-commit-impl.sh"' \
				'if [ -f "$$IMPL" ]; then' \
				'  bash "$$IMPL" "$$@" || exit $$?' \
				'else' \
				'  echo "[lore-enforcement] WARN: pre-commit-impl.sh nenalezen, enforcement preskocen." >&2' \
				'fi' \
				'' \
				'USER_HOOK="$$(dirname "$$0")/pre-commit-user"' \
				'if [ -f "$$USER_HOOK" ]; then' \
				'  bash "$$USER_HOOK" "$$@"' \
				'fi' \
				> "$$HOOK"; \
			chmod +x "$$HOOK"; \
			echo "Installed lore pre-commit chain shim (enforcement + map regen)."; \
		fi; \
	fi
	@echo "Skills installed. Run: cd ~/.lore && git init"
	@echo "Verify: ls ~/.claude/commands/"

uninstall-skills:
	@echo "Uninstalling lore skills..."
	rm -f ~/.claude/commands/lore.md
	rm -f ~/.claude/commands/intel-pass.md
	@echo "Skills removed. ~/.lore/ data preserved."

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  make install-skills   - Install lore skills to ~/.claude/commands/ and init ~/.lore/"
	@echo "  make uninstall-skills - Remove lore skills from ~/.claude/commands/"
