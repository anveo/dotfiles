#!/usr/bin/env zsh
#
# Smoke tests for the zsh plugin setup (.zshrc, zsh/*) and bash's fzf setup
# in shell/fzf.sh. Deliberately basic: they catch the regressions that are
# easy to reintroduce and slow to notice, not every behaviour.
#
#   zsh test/zsh_config_test.sh
#
# `make check` runs it. The bundle cases are isolated (a temp ANTIDOTE_HOME,
# a local plugin, and a file:// clone that fails without touching the
# network). The startup cases start a real interactive zsh on this repo's
# .zshrc, so they need antidote in ~/.antidote and are skipped without it.
# They read this checkout's zsh/plugins.txt, so a plugin it adds is cloned
# into antidote's real home -- the same clone the next shell would make.

ROOT=${0:A:h:h}
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT
PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL $1"; }

# Pass when the command succeeds.
check() { # name -- cmd...
  local name=$1
  shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}

# Pass when text contains needle.
has() { # name text needle
  case "$2" in
    *"$3"*) ok "$1" ;;
    *) bad "$1 (no '$3' in: $(printf '%s' "$2" | head -c 160))" ;;
  esac
}

lacks() { ! grep -q "$@"; }

echo "== interactive zsh startup =="
# zsh -f skips the user's own rc files so the repo's .zshrc is the one tested.
# stderr is dropped: without a terminal, zle and fzf print harmless warnings.
#
# DOTFILES=$ROOT makes .zshrc load this checkout's files rather than
# ~/dotfiles, so a run from a worktree tests the worktree. The plugin bundle is
# built in a temp XDG_CACHE_HOME: the live one in ~/.cache would otherwise be
# rewritten with this checkout's paths. ZDOTDIR points at the temp dir too, so
# zsh/compinit.zsh writes its .zcompdump there instead of over ~/.zcompdump;
# with zsh -f it changes nothing else. Every run therefore does a full
# compinit, permission audit included. ANTIDOTE_HOME stays at its real
# location, because off macOS antidote keeps its clones under XDG_CACHE_HOME
# and would re-clone every plugin into the temp dir.
#
# Without ~/.antidote, .zshrc would clone it there and an empty ANTIDOTE_HOME
# would send every plugin clone to the temp dir, so skip instead. Test the
# directory .zshrc tests: `antidote home` alone can still succeed through an
# fpath inherited from the calling shell.
antidote_home=
if [[ -d $HOME/.antidote ]]; then
  antidote_home=$(zsh -fc 'fpath=($HOME/.antidote/functions $fpath); autoload -Uz antidote; antidote home' 2>/dev/null)
fi
if [[ -z $antidote_home ]]; then
  ok "interactive zsh startup (skipped: antidote not installed in ~/.antidote)"
else
probe='
zmodload zsh/parameter
print -r -- "keymap: $(bindkey -lL main)"
print -r -- "tab: $(bindkey "^I")"
print -r -- "up: $(bindkey "^[[A")"
print -r -- "ctrl-space: $(bindkey "^ ")"
print -r -- "extract: ${functions_source[extract]}"
print -r -- "compdef: ${+functions[compdef]} comps: ${#_comps}"
print -r -- "wta: ${functions_source[wta]}"
print -r -- "path0: ${path[(r)*/scripts]}"
'
out=$(cd "$TMPROOT" && DOTFILES=$ROOT XDG_CACHE_HOME=$TMPROOT/xdg-cache ZDOTDIR=$TMPROOT ANTIDOTE_HOME=$antidote_home \
  zsh -f -i -c "source $ROOT/.zshrc; $probe" 2>/dev/null)
has "bash/* come from this checkout"        "$out" "wta: $ROOT/bash/functions"
has "scripts/ on PATH is this checkout's"   "$out" "path0: $ROOT/scripts"
check "the plugin bundle is built in the temp cache" [ -r $TMPROOT/xdg-cache/zsh/plugins.zsh ]
check "the completion dump is written in the temp dir" [ -s $TMPROOT/.zcompdump ]
has "emacs is the main keymap"              "$out" "keymap: bindkey -A emacs main"
has "Tab goes through fzf's completion"     "$out" "tab: \"^I\" fzf-completion"
has "Up arrow searches history by substring" "$out" "up: \"^[[A\" history-substring-search-up"
has "Ctrl-Space accepts the suggestion"     "$out" "ctrl-space: \"^@\" autosuggest-accept"
has "extract comes from Oh My Zsh"          "$out" "ohmyzsh/plugins/extract"
has "compinit has run"                      "$out" "compdef: 1"
case "$out" in
  *"comps: 0"*) bad "completions are registered (none found)" ;;
  *"comps: "*)  ok  "completions are registered" ;;
  *)            bad "completions are registered (no probe output)" ;;
esac
fi

echo "== bash fzf key bindings =="
if command -v fzf >/dev/null 2>&1; then
  out=$(bash --norc -i -c "source $ROOT/shell/fzf.sh; declare -F __fzf_history__" 2>/dev/null)
  has "bash defines fzf's Ctrl-R widget" "$out" "__fzf_history__"
else
  ok "bash defines fzf's Ctrl-R widget (skipped: fzf not installed)"
fi

echo "== zsh_build_bundle =="
fpath=($HOME/.antidote/functions $fpath)
autoload -Uz antidote
export ANTIDOTE_HOME=$TMPROOT/antidote-home
source $ROOT/zsh/build-bundle.zsh

mkdir -p $TMPROOT/plugins/demo
print 'demo_loaded=1' >| $TMPROOT/plugins/demo/demo.plugin.zsh
list=$TMPROOT/plugins.txt
bundle=$TMPROOT/cache/zsh/plugins.zsh
print -r -- $TMPROOT/plugins/demo >| $list

zsh_build_bundle $list $bundle 2>/dev/null
check "builds the bundle when there is none" grep -q demo.plugin.zsh $bundle

print '# marker' >> $bundle
zsh_build_bundle $list $bundle 2>/dev/null
check "leaves a bundle newer than the list alone" grep -q marker $bundle

touch -t 202001010000 $bundle
zsh_build_bundle $list $bundle 2>/dev/null
check "rebuilds when the list is newer" lacks marker $bundle

# A clone that fails, as on a first start while offline. The marker shows the
# previous bundle survived as-is; a partial rebuild would also mention demo.
print '# previous-good' >> $bundle
print -r -- "file:///nonexistent/placeholder-plugin.git" >> $list
touch -t 202001010000 $bundle
zsh_build_bundle $list $bundle 2>/dev/null
rc=$?
check "reports a failed build"                 [ $rc -ne 0 ]
check "keeps the previous bundle on failure"   grep -q previous-good $bundle
check "leaves no temp file behind"             [ ! -e $bundle.tmp ]
check "retries on the next shell"              [ ! $bundle -nt $list ]

rm -f $bundle
zsh_build_bundle $list $bundle 2>/dev/null
check "writes no partial bundle on a first-start failure" [ ! -e $bundle ]

echo "passed $PASS, failed $FAIL"
(( FAIL == 0 ))
