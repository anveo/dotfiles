[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# gvm's _bash_pseudo_hash._encode() pipes through `$HEXDUMP_PATH -e ...`. gvm sets
# HEXDUMP_PATH but never exports it, so non-interactive/snapshotted shells (e.g.
# Claude Code's tool shell) inherit it empty -- the line collapses to running `-e`,
# spamming "_encode:25: command not found: -e" on every gvm cd-hook (i.e. every cd).
# Export a known-good value so those shells encode cleanly.
export HEXDUMP_PATH="${HEXDUMP_PATH:-$(command -v hexdump)}"
