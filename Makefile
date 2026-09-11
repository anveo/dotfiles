.PHONY: install ai check

install:
	@echo "Installing..."
	./bin/install.sh

ai:
	@echo "Installing AI configs..."
	./bin/install-ai.sh

# Shell functions are sourced by zsh but written in bash syntax, so both shells
# have to agree. Syntax-check first -- a parse error makes every behavioural
# case fail in a way that says nothing about what broke.
check:
	@echo "Syntax..."
	bash -n bash/functions
	zsh -n bash/functions
	@echo "Behaviour (bash)..."
	bash test/worktree_functions_test.sh
	@echo "Behaviour (zsh)..."
	zsh test/worktree_functions_test.sh
