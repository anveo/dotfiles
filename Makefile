.PHONY: install ai check doctor

install:
	@echo "Installing..."
	./bin/install.sh

ai:
	@echo "Installing AI configs..."
	./bin/install-ai.sh

# `check` asks whether the repo is correct; `doctor` asks whether this machine's
# install is healthy (dangling links, tool-rejected configs, missing binaries).
doctor:
	@./bin/doctor

# Shell files sourced by both zsh and bash have to parse in both. Syntax-check
# first -- a parse error makes every behavioural case fail in a way that says
# nothing about what broke.
check:
	@echo "Syntax..."
	bash test/syntax_check.sh
	@echo "Behaviour (bash)..."
	bash test/worktree_functions_test.sh
	@echo "Behaviour (zsh)..."
	zsh test/worktree_functions_test.sh
	@echo "zsh config..."
	zsh test/zsh_config_test.sh
