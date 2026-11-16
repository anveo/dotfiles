.PHONY: install ai awdl awdl-uninstall check doctor

install:
	@echo "Installing..."
	./bin/install.sh

ai:
	@echo "Installing AI configs..."
	./bin/install-ai.sh

# macOS only, needs sudo: a root LaunchDaemon that keeps AWDL down so Wi-Fi
# stops stuttering under Synergy. Not part of `install` for that reason.
awdl:
	./bin/install-awdl-guard.sh install

awdl-uninstall:
	./bin/install-awdl-guard.sh uninstall

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
	@echo "Claude hooks..."
	python3 extras/claude/hooks/runway-write-guard-test
	python3 extras/claude/hooks/runway-callsign-test
	@echo "doctor: Claude hook commands..."
	bash test/doctor_claude_hooks_test.sh
	@echo "awdl guard..."
	bash test/awdl_guard_test.sh
	@echo "install-ai: Claude settings..."
	bash test/install_ai_settings_test.sh
	@echo "zsh config..."
	zsh test/zsh_config_test.sh
