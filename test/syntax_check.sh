#!/usr/bin/env bash
#
# Parse-check every tracked shell file with the shell(s) that will run it.
#
#   bash test/syntax_check.sh
#
# `make check` runs it first: a parse error makes every behavioural test fail
# in a way that says nothing about what broke. The shell is picked by where a
# file is sourced from, then by extension, then by shebang:
#
#   bash/{aliases,functions,env,paths}, shell/*.sh   both (.zshrc and .bashrc source them)
#   bash/*, .bashrc                                  bash
#   .zshrc, *.zsh                                    zsh
#   anything else                                    its #! line, if a shell;
#                                                    else bash, if *.sh with no #!

cd "$(dirname "$0")/.." || exit 1
FAIL=0
COUNT=0

parse() { # shell file
  COUNT=$((COUNT+1))
  if ! "$1" -n "$2"; then
    FAIL=$((FAIL+1))
    echo "  FAIL $1 -n $2"
  fi
}

# -z: without it, git quotes paths with unusual characters and they would not
# open.
while IFS= read -r -d '' f; do
  case "$f" in
    bash/aliases|bash/functions|bash/env|bash/paths|shell/*.sh)
      parse bash "$f"; parse zsh "$f" ;;
    bash/*|.bashrc)
      parse bash "$f" ;;
    .zshrc|*.zsh)
      parse zsh "$f" ;;
    *)
      # `read`, not $(head), so binaries (fonts, .blend) pass silently.
      first=
      IFS= read -r first <"$f" 2>/dev/null
      case "$first" in
        '#!'*bash*) parse bash "$f" ;;
        '#!'*zsh*)  parse zsh "$f" ;;
        '#!'*/sh|'#!'*/sh' '*|'#!'*' sh'|'#!'*' sh '*) parse sh "$f" ;;
        # A non-shell #! wins over the name (scripts/256colors.sh is Perl).
        '#!'*) ;;
        *) case "$f" in *.sh) parse bash "$f" ;; esac ;;
      esac ;;
  esac
done < <(git ls-files -z)

echo "parsed $COUNT, failed $FAIL"
[ "$FAIL" -eq 0 ]
