# Dotfiles Audit — 2026-07-29

Scope: everything except dot-directories, `docs/`, `nvimfiles/`, `scripts/`, `vimfiles/`. Produced by four parallel audits (shell configs; install/packaging; per-tool rc files; tooling research with web verification) plus direct measurement on this machine. Findings marked **[verified]** were confirmed empirically — run live, probed with `zsh -f`, checked against `git config --get`, `brew info`, `tmux list-keys`, or the GitHub API — not just read from source. No changes have been made.

The one-paragraph version: the repo is well-tended on its surface — modern tools (eza, fd, rg, fzf, fnm, uv, direnv, delta, difftastic), real cross-platform intent, good comments — but there's a 10–15-year-old sediment layer underneath. Two security items need fixing today. About twenty things are silently broken and have been for years (your global gitignore has literally never worked). A fresh-machine bootstrap would fail at several steps. Shell startup is 2.1–3.5s and can plausibly get under 300ms. And four of your foundations (zplug, and three of its plugins) are abandoned upstream with healthy, low-migration-cost successors.

---

## 1. Security — fix these first

**S1. Relative directories on `PATH`, including `./bin` in first position.** `.zshrc:184` (`export PATH="./bin:$PATH"`) and `bash/paths:57` (`./node_modules/.bin`). **[verified]** — a clean login shell's `PATH` starts with `./bin`. Any repo you `cd` into can shadow `git`, `ls`, `make`, anything, just by shipping a `bin/git`; a compromised npm dependency's postinstall writing `node_modules/.bin/ls` does the same. This is the single highest-risk line in the repo. Fix: delete both; use direnv (already installed) with `PATH_add bin` per-project.

**S2. `~/.localrc` is mode 644 and exports `GITHUB_TOKEN`.** **[verified]** — `-rw-r--r--`, one `GITHUB_TOKEN` export, sourced by both shells into every process's environment. Fix: `chmod 600` now; longer-term resolve lazily (`gh auth token`, or `op read`) instead of exporting.

**S3. `SSLKEYLOGFILE` exported unconditionally** (`bash/env:45`). Everything that honors it (Chrome, curl, OpenSSL/NSS tooling) appends TLS pre-master secrets to `~/tmp/tlskey` in every session. Combined with S2, someone with that file + a pcap can decrypt sessions carrying your tokens. Fix: comment out; set inline on the rare Wireshark day.

**S4. `updatevm` pipes a remote installer to bash and installs to a relative path** (`bash/functions:318`). `curl -fsSL https://fnm.vercel.app/install | bash --install-dir "./.fnm"` — unpinned remote code, and the relative dir means it drops an `.fnm/` into whatever directory you ran it from while never updating the real brew-installed fnm. Fix: `brew upgrade fnm` covers it; delete the curl.

**S5. `ch()` copies your entire Chrome history to world-readable `/tmp/h` and leaves it** (`shell/fzf_functions.sh:24-25`). Fix: `mktemp` + `trap` cleanup.

**S6. `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` globally** (`bash/env:47-51`) — disables an ObjC runtime safety check for every process; the Puma/High Sierra issue it worked around was fixed years ago. Delete.

**S7. Ghostty clipboard is wide open** (`extras/ghostty/config:54-56`). `clipboard-read = allow` lets any program — including over ssh on boxes you don't control — read your clipboard via OSC 52, and `clipboard-paste-protection = false` removes the guard against the "pasted command contains hidden extra commands" attack. With 1Password contents transiting that clipboard: `clipboard-read = ask`, `clipboard-paste-protection = true`.

Worth knowing, not necessarily fixing: `alias sudo='sudo '` + `alias ls=eza` means `sudo ls` runs a Homebrew binary (staff-writable prefix) as root.

---

## 2. Silently broken right now

Things that don't error — they just don't do what the config says. Grouped by blast radius.

### Git

- **Your global gitignore has never applied.** `.gitconfig:62` `excludesfile = $HOME/.gitignore` — git doesn't expand `$HOME` in config values (only leading `~/`). **[verified]** two independent ways (`git config --path` returns the literal string; `git check-ignore` misses `Thumbs.db`). The whole `.gitignore.global → ~/.gitignore` symlink machinery is inert. One-character fix: `~/.gitignore`.
- **Same class:** `~/.gitattributes` is symlinked by install.sh but git never reads that path — `core.attributesfile` is unset **[verified]**. The symlink does nothing.
- **`diff.external = difft` hijacks every diff** (`.gitconfig:114`): `git diff` output is no longer a valid patch (breaks `| git apply`, `--stat` accuracy) and it fires for `git log -p`, so your `l`/`ll`/`dl`/`news`/`pik` aliases all emit non-patch output. Meanwhile git-delta is installed and completely unused. Recommended shape: difftastic stays as difftool (`git dft`), delta becomes the pager (see §6).
- **Two no-op sections believed to be doing something:** `[force] withLease = true` is not a git option — you do *not* have force-with-lease protection **[verified against `git help --config`]**. `[branch] mergeoptions` (nameless form) is also invalid; the real one at `[branch "master"]` targets a branch name your own `init.defaultBranch = main` means new repos never have.
- `[pager] diff = false` + `color = true` — the latter isn't a real key, the former is exactly wrong once delta is wired.

### Shell (zsh)

- **Source order is backwards** (`.zshrc:139-142`): `aliases`/`functions` load *before* `env`/`paths`, so anything interpolating an env var at definition time bakes in empty. **[verified]** in a clean login shell (`alias emu` → `/tools/emulator`). Works today only because nested shells inherit from the parent.
- **`bindkey -e` at line 159 wipes every binding made before it** — the commented Ctrl-Space autosuggest-accept binding at line 99 has never worked. **[verified]**. (Doubly dead on this machine: inside tmux, Ctrl-Space is your prefix and never reaches zsh anyway.)
- **The compinit "rebuild once a day" cache is a no-op** — `[[ -n file(#qN.mh+24) ]]` doesn't glob inside `[[ ]]` **[verified]** — and compinit actually runs **3× per startup** (zplug runs its own twice). See §4.
- **`HOMEBREW_PREFIX` is empty for the first 140 lines** — no `.zprofile` exists, so `type brew` fails at `.zshrc:17` and the site-functions FPATH block never executes **[verified]**. Everything downstream works by accident because `bash/paths:35` runs `brew shellenv` late.
- **`bash/paths:64` stray `$`** — `[ -d "$/opt/homebrew/opt/postgresql@17/bin" ]` is always false, so keg-only postgres 17 is never put on PATH by this file (masked on this machine by `~/.localrc`). Found independently by two audits.
- **1Password helpers test a variable that never exists**: `opon` gates on `$OP_SESSION` but op exports `OP_SESSION_<account>` — so it re-signs-in (resetting your 30-min window) every time, and `opoff` unsets nothing. Your own `bash/prompt:146` and `op.zsh` grep for the correct `^OP_SESSION_`. Relatedly, the spaceship `op`/`aws_vault` sections show "(expired)" whenever the expiration var is *unset* (empty string comparison) and leak three globals.
- **`extract()` — your 20-line version is dead code**: the OMZ `extract` plugin loads after it and wins **[verified via `which extract`]**. Conversely the `supercrabtree/k` plugin is fully shadowed by `alias k=kubectl`. One of each pair should go.
- **`GRADLE_OPTS` self-appends** every nested shell **[verified at SHLVL=4: three copies]**.
- **`killnamed` kills nothing** (`cut -d' '` on right-aligned PIDs yields empty **[verified]**); `server()`/`urlencode` are Python-2-only (SyntaxError on your 3.x); the four docker helper functions use `read -p`/`history -s` — bash-isms that hard-error in zsh, the only shell that sources them **[verified]** — and also permanently clobber `FZF_DEFAULT_OPTS` when run.
- **`[ -x $(type X &>/dev/null) ]` is always true** (empty substitution → one-arg string test), so `alias ack=ack-grep` exists pointing at a binary that isn't installed, and on nvim-less machines `vi` would alias to empty string.
- **`shell/fzf.sh:35` guard is inverted** (`-z ZSH_VERSION` sources the *zsh* integration only in bash); `subshell.zsh` grows its suffix one space per prompt render (missing `local`).
- **`.bashrc` drift**, if you still care about bash: `DOTFILES` never set (`ghpr` resolves to `/scripts/ghpr`), only 7 of 16 `shell/*.sh` files sourced, completions load before `HOMEBREW_PREFIX` exists, `HISTCONTROL` set three times with three values.

### psql / irb

- Four `.psqlrc` queries can't run or lie on your PG 17: `:waits` uses a column dropped in 9.6, `:show_slow_queries` a column renamed in PG 13, `:index_size`/`:total_index_size` **under-report by 8×** (`relpages*1024`; pages are 8KB), `:uselesscol` returns nothing since PG 17 made `attstattarget` nullable. Also `COMP_KEYWORD_CASE` is set to `upper` (with explanatory comment) then silently reset to `lower` 29 lines later.
- `.irbrc` on your Ruby 4.0.0: `fl`/`rl`/`rt` raise (`class variable access from toplevel`) **[verified]**; `USE_READLINE = true` disables the modern Reline editor + autocomplete you'd otherwise get free; **8 "install this gem" nag lines print on every rails console** (none of the 9 gems are installed **[verified]**); history config is set twice with conflicting values (net effect: 100 lines kept in the second file); ANSI color constants leak into `Object` (collision risk in a Rails console).

### Terminal / tmux / misc

- **Ghostty `font-feature` lines have never worked** (`extras/ghostty/config:6-7`): Ghostty has no trailing-comment syntax, so the values include the comment text and are rejected. Found independently by two audits. (Unnoticed because JetBrains Mono ships ligatures on by default.) Same file: `window-theme = dark` pins the chrome dark, defeating your own light/dark auto-switch on line 31.
- **The light theme is the dark palette**: `extras/ghostty/themes/default-light` lines 16-33 are byte-identical to `default-dark` — pale yellow / `#eeeeee` "white" text on a `#fafafa` background. Either generate a real light palette or use built-ins (`theme = light:<name>,dark:<name>`).
- **tmux dead bindings** **[verified via `list-keys`]**: `bind C-l send-keys C-l` (clear screen) is overwritten at line 170, `bind C-c new-window` ("screen habit") overwritten at line 121 — both comments describe behavior you don't have, and there is currently *no* clear-screen binding at all. Plus: `history-limit 16348` is a transposition of 16384 (and blocks tmux-sensible's 50000); `status-interval` set to 5 then 60 (60 wins — your `%R` clock can be a minute stale); `status-justify` set twice; deprecated `status-bg` overrides your `status-style`; duplicate `copy-mode-vi y` binding; `unbind p`/`bind p` duplicated verbatim.
- **hammerspoon `focusApp` crashes** when the app isn't running (`app:unhide()` on nil) — you have ~20 hotkeys for apps like Blender/Ableton/Zoom that often aren't running.
- `extras/claude/statusline-command.sh:24` reads the git branch from the statusline's cwd, not from the `$DIR` it parsed — add `git -C "$DIR"`.
- Trivia tier: `.Xdefaults:12` has a 5-digit hex color; `.ackrc` is ack-1.x syntax that ack 3 refuses to parse (moot — ack isn't installed); `extras/kitty/kitty.conf` requests 8GB of scrollback (kitty isn't installed either).

---

## 3. A fresh machine can't bootstrap from this repo

Sequenced as a new-workstation run would hit them:

1. **`brew bundle` aborts**: `Brewfile:155` `tldr` was disabled by Homebrew 2025-10-24 (replacement: `tlrc`) **[verified via `brew info`]** — passes locally only because the old bottle is present. Then the `go`/`uv`/`krew`/`npm` blocks (lines 336-343) fail because none of `go`, `uv`, `krew`, `node` are declared as formulae — on this machine they came from gvm / curl installers. Also: `cask "chromedriver"` gets disabled 2026-09-01; the `trusted: true` header needs Homebrew ≥ 6 (worth a README note for Linux boxes).
2. **`make install` can silently truncate**: `extras/macos_defaults.sh` ends with `killall Dock`, which exits 1 if Dock isn't running; with `set -e` in install.sh that aborts *before* the VisiData/lazygit/tig/Claude symlinks (lines 103-126). Fix: `|| true`, or run it last.
3. **`ln -nfs` nests instead of replacing when the target is a real directory** — and two targets near-certainly exist on a fresh machine (`~/.claude/commands/` created by Claude Code, `~/.config/nvim/` from any prior install), producing `~/.config/nvim/nvimfiles` silently. Needs a back-up-then-link helper.
4. **No backups anywhere**: every `ln -fs` destroys an existing `~/.zshrc`/`~/.gitconfig` without a trace, and line 80 `rm -f`'s the user's Ghostty config. One `backup_then_link()` helper writing to `~/dotfiles-backup-<ts>/` fixes the whole class.
5. **`$HOME/dotfiles` is hardcoded ~45 times** in install.sh (plus `.zshrc`, `.bashrc`, `bash/paths`) — clone anywhere else and you get a complete set of dangling symlinks with zero errors. Derive `DOTFILES` from the script's own path.
6. **The Claude statusline is linked but never activated** — the `settings.json` that references it isn't tracked. Track an `extras/claude/settings.json` (machine-local stays in `settings.local.json`, already ignored).
7. Ghostty linking is macOS-gated but Ghostty runs on Linux with the same XDG path — hoist it out of the `Darwin` branch. Karabiner config is linked but there's no `cask "karabiner-elements"`. Kitty configs are linked for a terminal that isn't installed.
8. **README drift**: `README.linux.md` is unusable — `creationix/nvm` (dead org, wrong tool — you use fnm), `rake install` (no Rakefile exists; it's `make install`), `ln -nfs dotfiles/bashrc` (wrong filename). `README.md` still has an iTerm2 section; `docs/tmux-reference/cheatsheet.md` is the one file that missed the tpack migration (says "Managed by TPM", claims resurrect is disabled when `.tmux.conf` enables it).
9. Housekeeping: `userpref.blend` is both gitignored *and* tracked (rule is a no-op; `git rm --cached` to make it real); `.gitattributes` has no `* text=auto` / CRLF rules despite the repo carrying `.ps1`/`.bat` for WSL; `fonts/` (two Powerline OTFs) is orphaned — nothing references or installs them, superseded by the nerd-font casks; ~8 redundant Brewfile pairs (hub vs gh, gitx (v1.5, abandoned ~decade), htop vs bottom, tree vs eza, yarn+pnpm vs corepack, wireshark formula+cask, transmission ×2, postgresql@16+@17+libpq); `brew "mole"` — a young third-party "Mac cleaner" with broad filesystem reach — deserves a deliberate keep/drop decision rather than being inherited from a `brew bundle dump`.

---

## 4. Performance: 2.1s → under 300ms is realistic

Measured on this machine: **2.06–3.49s** interactive startup (bare `zsh -f`: ~0ms). Profiled breakdown and the fix for each:

| Cost | Cause | Fix |
|---|---|---|
| ~500ms | `shell/gvm.sh` — sourcing gvm, which also wraps `cd` (the mystery 330-420ms `cd` in the profile) | Lazy-load: `gvm() { unfunction gvm; source ~/.gvm/scripts/gvm; gvm "$@"; }` — or drop gvm entirely (Go toolchain now self-manages via `go.mod`) |
| ~600ms | zplug's serial cache loading | Migrate to antidote (§6) |
| ~520ms | `compinit` ×3 + `compaudit` ×4 (broken cache test, §2) | Run it once, correctly cached, `zcompile` the dump |
| ~150ms | pyenv: three separate evals incl. a per-prompt hook | Single `eval "$(pyenv init - --no-rehash zsh)"` |
| ~90ms | `zplug check` interactive-install probe every startup (can *block* a fresh shell waiting for a keypress) | Move to install.sh |
| ~50ms | rbenv rehash | `--no-rehash` |

Beyond startup: **7 precmd + 4 chpwd hooks** run on every prompt / every `cd` **[verified]** — two competing virtualenv autoswitchers, direnv, fnm, zsh-z, spaceship, plus gvm's cd wrapper. And `SPACESHIP_GIT_ASYNC="false"` makes every prompt block on `git status` (painful in big repos) while you load `zsh-async` — the dependency that exists to fix exactly this. Set it `true` and prune unread sections (`elixir`, `conda`, `battery`, one of `python`/`venv`; `kubectl` spawns a subprocess per prompt in k8s-adjacent dirs).

Five plugins cost time and deliver nothing **[each verified]**: `anyframe` (its bindkeys are commented out), `zsh-history-substring-search` (never bound), `zsh-async` (consumer disabled), `k` (shadowed by `alias k=kubectl`), `zsh-256color` (probes terminfo to "fix" TERM — actively counterproductive now that you've stopped forcing TERM).

---

## 5. Dead weight — the deletion list

Safe to remove once confirmed (rough count: ~700 lines + 2 binaries + a directory or two):

- **Files**: `shell/nvm.sh` (100% commented), `shell/autojump.sh` (tool absent + bash-gated), `shell/z.sh` + `scripts/z.sh` (zsh uses zsh-z), `shell/pyenv.sh`→collapse, `shell/uv.sh` (sources a file that doesn't exist), `.ackrc` + `.agignore` (tools absent; rules → `.rgignore` if wanted), `.screenrc` (tmux since forever), `.Xdefaults` (no X11 here; or park in a `linux/` dir), `extras/kitty/`, `extras/VibrantInk.itermcolors`, `fonts/`, `shell/adobe.sh` (second definition is syntactically broken anyway)
- **Blocks**: `.tmux.conf` legacy `@tpm_plugins` corpse (~35 lines, two plugin-manager blocks in one file is confusing); `.zshrc` ~35 lines of commented zplug declarations; `bash/prompt` (229 lines of legacy bash prompt that probes `ruby --version`+`node -v` per prompt); `fzf_functions.sh` ~40 lines of commented ghq drafts; six commented `.gitconfig` aliases; Ruby GC tuning from a 2012 gist (`bash/env:39-43`); poetry/Intel-Homebrew path stanzas
- **Aliases pointing at absent software** [verified]: `gg` (gitg), `dmk`/`undmk`/`mk` (minikube), `kk` (krew), colordiff pair, `br()` (broot), `fgl` (figlet + Intel Cellar path), `emu` (SDK `tools/` dir removed by Google in 2021)
- **Duplicates**: `ls` defined 3× in sequence (eza wins); `gone` alias vs `gbclean` function (same `[gone]` awk, will drift — the alias's own doc comment already points at the function); `hb` (hub) vs `gh`

Portability quickies for the Linux/WSL boxes: `LANG="en_US"` missing `.UTF-8` + forced `LC_ALL` (the classic perl/python locale-warning cascade on minimal images); ~25 macOS-only aliases defined unguarded; `shell/fnm.sh`/`shell/direnv.sh` hardcode `--shell zsh` while `.bashrc` sources them; `shell/pnpm.sh` handles only the macOS pnpm home (its PATH-dedupe idiom, meanwhile, is the pattern `bash/paths` should copy — `MANPATH` currently accumulates duplicates **[verified]**).

---

## 6. Modernization — researched and verified current as of 2026-07-29

Priority order, tuned to your actual stack (each upstream checked via releases/API this week):

1. **atuin** (v18.18.1, released yesterday) — the one tool that solves a problem you've explicitly worked around: you disabled `SHARE_HISTORY` on purpose, and you have multiple workstations. Encrypted history sync with per-host/per-directory/exit-code filtering; imports existing history; can keep your up-arrow behavior (`--disable-up-arrow`). Cost: one brew install + one init line per machine.
2. **zplug → antidote** (v2.2.1, released this week) — zplug is the one genuinely decaying foundation: v2.4.2 from 2023, slowest-in-class architecture, double-compinit, and your local clone still points at the pre-rename `b4b4r07/` org. Your plugin list maps ~1:1 onto antidote's `.zsh_plugins.txt`, and migration forcibly prunes the rot: `anyframe` (archived 2022), `k` (dead 2023 + shadowed), OMZ `copydir` (removed upstream — it's `copypath` now), `enhancd` (stale). Combined with §4 this is the sub-300ms path. Cost: an evening.
3. **zoxide** (v0.10.0, July 2026) — you're currently carrying **four** directory jumpers (enhancd, zsh-z, rupa/z, autojump — two of them dead). One binary replaces all four, works in bash on WSL too, imports your z database, and preserves muscle memory via `--cmd c` if you want enhancd's `c`. Then **sesh** (v2.28.0) becomes interesting: zoxide-driven tmux session manager that would subsume your hand-rolled `bind w` fzf popup.
4. **mise** — the consolidation play for rbenv+pyenv+gvm+tfenv+fnm and the `updatevm` function (S4). Ruby-core's own survey analysis shows mise/asdf mainstream among active Rubyists now; it reads `.ruby-version`/`Gemfile` natively. **Timing note: precompiled Ruby becomes mise's default in 2026.8.0 — next month.** Migrate gvm/tfenv now if eager, Ruby after that lands. Coexistence is safe.
5. **Config-only wins**: Ghostty 1.3 shipped scrollback search (cmd+F) and `ssh-env`/`ssh-terminfo` shell integration — the latter closes the remote-TERM gap opened by the TERM fix (your `docs/TODO.md:134` already wanted this). `git maintenance start` in the big Rails repos: free background commit-graph/prefetch.
6. **.gitconfig modernization pack** (no new tools): wire delta as pager + `interactive.diffFilter` (the piece that makes `git add -p` readable); `rerere.enabled`, `diff.algorithm = histogram`, `diff.colorMoved`, `merge.conflictstyle = zdiff3`, `rebase.updateRefs` (stacked branches), `push.autoSetupRemote`, `push.useForceIfIncludes` (the real version of your intended `withLease`), `branch.sort = -committerdate` (retires your `bs` alias), `commit.verbose`, `fetch.prune`, `core.fsmonitor` + `untrackedCache` (big Rails repos), `column.ui = auto`, ssh-key commit signing. Also: identity (`bracer@gmail.com`, `github.user = anveo`) is hardcoded in the tracked file every workstation shares — an `[includeIf "gitdir:~/work/"]` split is the standard fix.
7. **tmux niceties**: replace the `ps | grep`-per-keystroke vim detection with the modern `@pane-is-vim` user-option pattern (zero subprocesses; also fixes the missing copy-mode passthrough binds); add `@continuum-restore 'on'` (you save every 15 min and never restore — most of continuum's value is off) and `@resurrect-capture-pane-contents`; `allow-passthrough on`; `detach-on-destroy off`.

**Explicitly researched and rejected** (skip, despite the hype): **starship** — spaceship is actively maintained (v4.22.5, July 2026) and your three custom sections are native zsh; note your *installed* clone is 2 years stale, so update it, but don't migrate. **chezmoi** — healthy tool, but your localrc/uname-branch pattern already covers its selling points; migration is high-cost for a setup that rarely provisions new machines. **jj** — colocated mode makes it a safe side-repo experiment, but pre-1.0 CLI churn vs. your git muscle memory says not a daily driver. **television** — fzf is load-bearing in ~6 places here. **zinit** — faster than zplug but complexity + custody drama; antidote suffices. **powerlevel10k** — maintenance mode since 2024.

One decision item that surfaced during the audit: `extras/claude/RTK.md` documents an rtk hook that isn't configured anywhere in this repo or `~/.claude/settings.json` — and if it *were*, rewriting `git status` → `rtk git status` would break every stable-prefix allowlist entry your own CLAUDE.md is built around. The two documents contradict each other; either version the hook or drop the `@RTK.md` import.

---

## 7. Ideas beyond fixes

- **`make doctor`** — a self-check target that would have caught most of §2 mechanically: dangling-symlink scan, `brew bundle check`, `ghostty +validate-config` (needs the CLI on PATH — one symlink; it would have flagged the font-feature bug), `tmux -f .tmux.conf -L lint new -d` parse check, `zsh -n` / `bash -n` on every shell file, `command -v` over every alias target, `git config` key validation. ~50 lines of bash, permanent regression net.
- **CI on the repo** — the same checks + shellcheck in a GitHub Actions matrix (macos + ubuntu). Dotfiles are the software you use most and test least; §3 exists because nothing ever exercises the fresh-machine path.
- **A `bootstrap` make target** that sequences the README's six manual steps (brew → install → fnm default → zplug/antidote) so a new workstation is one command.
- **Track `extras/claude/settings.json`** so statusline + hooks + the permission allowlist replicate across workstations instead of being this-machine-only.
- **Provenance file for vendored code** — `extras/blender/` carries 2,595 lines of third-party addons with no source URLs/versions; a 10-line README makes them updatable.
- **`extras/linux-legacy/` or deletion** for the X11/screen/kitty/iTerm artifacts — right now the repo can't tell "supported platform" from "archaeology".

## What's genuinely good (calibration)

The audits consistently flagged the same strengths: `gbclean` is careful code (dry-run default, protected branches, `-d` not `-D`); the `pik`/`pikr` pickaxe aliases are excellent; `.psqlrc`'s interactive core (`ON_ERROR_ROLLBACK interactive`, `\x auto`, per-DB history) is current best practice; the cross-platform guards, where they exist, are done right (`shell/rbenv.sh`, `shell/pnpm.sh`, `ports()`); `extras/claude/CLAUDE.md` is better-specified than most engineering style guides; and the comment discipline in recently-touched files (TERM removal, tpack parser caveat, gvm HEXDUMP) is exactly the kind that prevents regressions. The problem isn't the gardening — it's that the garden has 15 years of undergrowth nobody ever cleared.

---

## Unresolved questions

1. S2: move `GITHUB_TOKEN` to `gh auth token` / `op read`, or just chmod?
2. bash: maintain parity or declare zsh-only and gut `.bashrc`/`bash/prompt`?
3. Delete-list (§5): straight delete, or park relics in `extras/linux-legacy/`?
4. rtk: version the hook, or drop `@RTK.md` import?
5. `lazy-lock.json`: commit-as-pin policy, or gitignore?
6. mise: gvm/tfenv now + Ruby after 2026.8.0, or all-at-once later?
7. antidote migration: want it as a prepared branch to review?
8. `brew "mole"`: intentional?
9. Push today's 5 commits?
