# Modules Registry
MODULES := zsh zoxide eza atuin starship lazygit mise go jdk maven mvnd thrift node pnpm python rust neovim fluidvim macos

.PHONY: all menu $(MODULES)

INSTALL := source install.sh;

# Default target: Interactive Mode
menu:
	@echo "Select modules to install (comma-separated numbers, or 'all'):"
	@echo "$(MODULES)" | tr ' ' '\n' | cat -n
	@echo "Selection: " && read input; \
	if [ "$$input" = "all" ]; then \
		$(MAKE) all; \
	elif [ -z "$$input" ]; then \
		echo "No selection made."; \
	else \
		targets=""; \
		IFS=',' read -ra ADDR <<< "$$input"; \
		for i in "$${ADDR[@]}"; do \
			target=$$(echo "$(MODULES)" | tr ' ' '\n' | sed -n "$${i}p"); \
			if [ -n "$$target" ]; then targets="$$targets $$target"; fi; \
		done; \
		$(MAKE) $$targets; \
	fi

# Run everything (sources once)
all:
	@sh -c "source install.sh; \
		for m in $(MODULES); do run_module \$$m; done"
	@echo "Installation complete."

# Individual module targets
zsh:
	@$(INSTALL) run_module zsh
zoxide:
	@$(INSTALL) run_module zoxide
eza:
	@$(INSTALL) run_module eza
atuin:
	@$(INSTALL) run_module atuin
starship:
	@$(INSTALL) run_module starship
lazygit:
	@$(INSTALL) run_module lazygit
asdf:
	@$(INSTALL) run_module asdf
mise:
	@$(INSTALL) run_module mise
go:
	@$(INSTALL) run_module go
jdk:
	@$(INSTALL) run_module jdk
maven:
	@$(INSTALL) run_module maven
mvnd:
	@$(INSTALL) run_module mvnd
thrift:
	@$(INSTALL) run_module thrift
node:
	@$(INSTALL) run_module node
pnpm:
	@$(INSTALL) run_module pnpm
python:
	@$(INSTALL) run_module python
rust:
	@$(INSTALL) run_module rust
neovim:
	@$(INSTALL) run_module neovim
fluidvim:
	@$(INSTALL) run_module fluidvim
macos:
	@$(INSTALL) run_module macos
