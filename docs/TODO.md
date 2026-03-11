# TODO: Ghostty + tmux Capabilities to Explore

## Extended Keys (CSI-u) — enabled

CSI-u encoding lets tmux pass disambiguated modifier keys to apps like Neovim.
Now that it's enabled, explore:

- [ ] Bind `Ctrl+Shift+<key>` combos in Neovim that were previously impossible
- [ ] Distinguish `Tab` vs `Ctrl+i`, `Enter` vs `Ctrl+m`, `Escape` vs `Ctrl+[` in keymaps
- [ ] Test whether any existing tmux or Neovim bindings behave differently (they shouldn't, but verify)

## OSC 52 Clipboard — enabled

tmux can now write to the system clipboard via Ghostty's OSC 52 support,
without depending on `pbcopy`.

- [ ] Test yanking in tmux copy-mode — clipboard should update without pbcopy
- [ ] Consider removing explicit `pbcopy` pipe bindings if OSC 52 is reliable (or keep as belt-and-suspenders)
- [ ] If using Ghostty on Linux in the future, OSC 52 means no platform-specific clipboard tool needed

## tmux Control Mode (future)

Ghostty is implementing tmux control mode (`tmux -CC`), similar to iTerm2.
When ready, this would let Ghostty render tmux windows/panes as native
Ghostty tabs and splits.

- [ ] Watch for Ghostty releases that ship control mode support (tracked in ghostty-org/ghostty#1935)
- [ ] Evaluate whether native tab integration is worth switching from traditional tmux status bar

## OSC 8 Hyperlinks

Ghostty supports clickable hyperlinks via OSC 8. tmux may not fully pass
these through in all versions.

- [ ] Test whether clickable URLs work inside tmux panes (e.g. from `ls --hyperlink` or compiler output)
- [ ] If not, check tmux version — newer versions have better passthrough support (`set -g allow-passthrough on`)

## Title String Customization

Currently using `#S: #W - #{pane_current_command}` as the Ghostty tab title.

- [ ] Tweak the format after living with it — maybe add `#{pane_current_path}` basename
- [ ] Explore `automatic-rename-format` for the tmux status bar window names too

## Undercurl and Colored Underlines

Ghostty natively supports curly underlines (undercurl) and colored underlines,
which are used by Neovim LSP diagnostics to show errors/warnings. However,
tmux needs explicit terminal-overrides to pass these through — without them
undercurl falls back to a plain underline.

**Config to add to `.tmux.conf`:**
```
set -as terminal-overrides ',xterm-ghostty:Smulx=\E[4::%p1%dm'
set -as terminal-overrides ',xterm-ghostty:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
```

- [ ] Add the terminal-overrides above
- [ ] Verify undercurl renders in Neovim (`:hi DiagnosticUnderlineError` should show `undercurl`)
- [ ] Alternatively, try `set -as terminal-features 'xterm-ghostty:usstyle'` which may handle this more cleanly on tmux 3.2+

## tmux Passthrough and Kitty Image Protocol

Ghostty supports the Kitty graphics protocol, including unicode placeholders
(U+10EEEE) which is what makes images work *inside tmux*. Ghostty does NOT
support sixel — the Kitty protocol is the intended replacement.

**Config to add to `.tmux.conf`:**
```
set -g allow-passthrough on
```

- [ ] Enable `allow-passthrough` in tmux
- [ ] Try yazi (file manager) with image previews inside tmux
- [ ] Try `chafa -f kitty <image>` inside tmux
- [ ] Be aware: passthrough can be unreliable in nested tmux sessions

## Desktop Notifications (OSC 9 / OSC 777)

Ghostty supports desktop notifications via escape sequences. Outside tmux
they work directly. Inside tmux they require `allow-passthrough on`.

**Usage:**
```bash
printf '\e]9;Build finished\a'                      # OSC 9
printf '\e]777;notify;Title;Build finished\a'       # OSC 777
```

- [ ] Try sending notifications from build scripts or long-running commands
- [ ] Inside tmux, the DCS-wrapped form is needed: `\ePtmux;\e\e]777;notify;Title;Body\a\e\\`

## Command Finish Notifications (Ghostty 1.3.0+)

Ghostty can show a native macOS notification when a long-running command
finishes. Uses OSC 133 prompt markers from shell integration to detect
when a command completes.

**Config to add to Ghostty:**
```
notify-on-command-finish = unfocused
notify-on-command-finish-action = notify
notify-on-command-finish-after = 10
```

- [ ] Try enabling this in Ghostty config
- [ ] Test whether it works inside tmux — OSC 133 may not reach Ghostty through tmux without passthrough
- [ ] If it doesn't work through tmux, manual `OSC 9` notifications (above) are the fallback

## Shell Integration Features

Ghostty's shell integration has several sub-features beyond the `no-title`
we've already set. The full set:

| Feature | Description | Default |
|---------|-------------|---------|
| `cursor` | Changes cursor to a bar at the prompt (overrides `cursor-style`) | Enabled |
| `sudo` | Wraps sudo to preserve Ghostty terminfo in elevated sessions | **Disabled** |
| `ssh-env` | Wraps ssh to set `TERM=xterm-256color` on remote hosts | **Disabled** |
| `ssh-terminfo` | Wraps ssh to auto-install Ghostty's terminfo on remote hosts | **Disabled** |
| `title` | Updates terminal title with shell/command info | Enabled (we disabled) |
| `new-tab-cwd` | New terminals inherit the working directory of the focused terminal | Enabled |

Use `no-` prefix to disable. Multiple features are comma-separated:
`shell-integration-features = no-title,sudo,ssh-terminfo`

**Always-on behaviors (not toggleable):**
- Prompt-aware close (no confirmation when cursor is at a prompt)
- Prompt line redrawing (complex prompts resize correctly)
- Cmd+Triple-click selects a command's full output
- `jump_to_prompt` keybinding scrolls forward/back through prompts
- Option+Click moves cursor to click location at the prompt

- [ ] Consider enabling `sudo` to preserve terminfo in `sudo -i` sessions
- [ ] Consider enabling `ssh-terminfo` to auto-install `xterm-ghostty` on remote hosts
- [ ] Decide on `cursor` — it overrides block to bar at the prompt. Disable with `no-cursor` if block is preferred everywhere
- [ ] Try Cmd+Triple-click to select command output
- [ ] Try the `jump_to_prompt` keybinding to navigate between prompts in scrollback

## Quick Terminal (Quake/Dropdown Mode)

Ghostty has a system-wide dropdown terminal toggled by a global hotkey.

**Config to add to Ghostty:**
```
keybind = global:cmd+backquote=toggle_quick_terminal
```

The `global:` prefix means it works even when Ghostty is not focused.
Requires Accessibility permissions in System Settings > Privacy.

- [ ] Try enabling quick terminal with a global hotkey
- [ ] Consider running a dedicated tmux session inside the quick terminal
- [ ] Note: does not work on top of fullscreen applications on macOS

## URL Clicking Inside tmux

Ghostty detects URLs on hover when holding Cmd. Inside tmux with `mouse on`,
use **Cmd+Shift+Click** to open links. The Shift bypasses tmux's mouse
capture so Ghostty handles the click.

This works because `mouse-shift-capture = false` in Ghostty config means
Shift-clicks are intercepted by Ghostty rather than forwarded to tmux.

- [ ] Try Cmd+Shift+Click on a URL inside a tmux pane to verify it works

## ConEmu Progress Bars (OSC 9;4, Ghostty 1.2.0+)

Ghostty renders native GUI progress bars in the terminal tab/titlebar
using ConEmu's `OSC 9;4` sequences. Useful for build tools, file transfers,
or any long-running operation.

**Usage:**
```bash
# Set progress to 50%
printf '\e]9;4;1;50\a'
# Clear progress
printf '\e]9;4;0\a'
```

- [ ] Try wrapping a build script or download with progress bar escape sequences
- [ ] See if any existing tools (curl, etc.) emit these automatically

## Rich Clipboard (Ghostty 1.3.0+)

The `copy_to_clipboard` action supports a `vt` format that preserves terminal
formatting (colors, bold, etc.) in the clipboard. Pasting into rich-text
apps keeps the formatting.

**Config:**
```
keybind = cmd+c=copy_to_clipboard:vt
```

- [ ] Try the VT clipboard format for copying colored terminal output into docs/Slack

## Performable Keybindings and Modal Key Tables (1.3.0+)

`performable:` prefix makes keybindings only fire when the action can be
performed. For example, `copy_to_clipboard` only fires if there is a
selection — otherwise the keypress passes through to tmux/Neovim.

```
keybind = performable:cmd+c=copy_to_clipboard
```

Modal key tables let you create tmux-style modal keybinding workflows
within Ghostty itself, using `push_key_table`, `pop_key_table`, and
`catch_all` (matches unbound keys).

- [ ] Try `performable:cmd+c=copy_to_clipboard` to avoid Cmd+C conflicting with tmux/Neovim

## Scrollback Notes

Ghostty maintains its own scrollback on the primary screen, while tmux runs
on the alternate screen (no scrollback). These are separate.

- Mouse wheel inside tmux correctly scrolls tmux's history
- Ghostty's native scrollbar (1.3.0+) and Cmd+F search can surface leaked tmux content
- **Best practice:** Rely on tmux's copy-mode for scrollback (`prefix + Space`). Ghostty's scrollbar and search are most useful outside tmux.

## True Color Verification

True color is already configured (`terminal-overrides ",xterm-ghostty:RGB"`).
Some tools check the `COLORTERM` env var rather than terminfo.

- [ ] Run `tmux info | grep -i rgb` inside tmux to verify
- [ ] If tools like `bat` or `delta` aren't showing color, ensure `COLORTERM=truecolor` is set
- [ ] Can add `set -ga update-environment "COLORTERM"` to `.tmux.conf` if needed
