# Build antidote's static plugin bundle when the plugin list is newer than it.
#
#   zsh_build_bundle <plugin list> <bundle file>
#
# Builds into a temp file and keeps the result only if antidote succeeded. A
# failed clone (offline, GitHub down, a proxy) otherwise leaves a partial
# bundle that is newer than the list and so is never rebuilt. On failure the
# previous bundle, if any, is left in place and the build is retried on the
# next shell. Returns non-zero when a build was needed and failed.
#
# Only builds; .zshrc sources the result at top level. Sourcing it from inside
# this function would make every plugin's `local`/`typeset` function-scoped.
zsh_build_bundle() {
  local list=$1 bundle=$2
  [[ $bundle -nt $list ]] && return 0

  mkdir -p ${bundle:h}
  if antidote bundle <$list >|$bundle.tmp; then
    mv -f $bundle.tmp $bundle
  else
    rm -f $bundle.tmp
    print -u2 "zsh: building the plugin bundle failed; retrying on the next shell"
    return 1
  fi
}
