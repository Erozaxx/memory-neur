.PHONY: install-skills uninstall-skills help

install-skills:
	@echo "Installing lore skills..."
	mkdir -p ~/.claude/commands/
	mkdir -p ~/.lore/lessons ~/.lore/decisions ~/.lore/projects ~/.lore/processes ~/.lore/personas ~/.lore/scripts
	cp skills/lore/lore.md ~/.claude/commands/lore.md
	cp skills/intel-pass/intel-pass.md ~/.claude/commands/intel-pass.md
	cp scripts/*.sh ~/.lore/scripts/
	chmod +x ~/.lore/scripts/*.sh
	@for type in lessons decisions projects processes personas; do \
		if [ -f lore/$$type/_schema.yml ]; then cp lore/$$type/_schema.yml ~/.lore/$$type/_schema.yml; fi; \
		if [ -f lore/$$type/_template.md ]; then cp lore/$$type/_template.md ~/.lore/$$type/_template.md; fi; \
	done
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
