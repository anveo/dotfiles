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
# .zshrc, so they need the plugins installed, which any earlier shell does.

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
probe='
zmodload zsh/parameter
print -r -- "keymap: $(bindkey -lL main)"
print -r -- "tab: $(bindkey "^I")"
print -r -- "up: $(bindkey "^[[A")"
print -r -- "ctrl-space: $(bindkey "^ ")"
print -r -- "extract: ${functions_source[extract]}"
print -r -- "compdef: ${+functions[compdef]} comps: ${#_comps}"
'
out=$(cd "$TMPROOT" && zsh -f -i -c "source $ROOT/.zshrc; $probe" 2>/dev/null)
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
