# frontman

Hyper+`<key>` brings an app to the foreground. A Windows/AutoHotkey take on the
`focusApp` bindings in a Hammerspoon config.

**Hyper = Right Alt.** It's a pure layer key: it does nothing on its own and is
never passed to Windows as Alt, so chords can't collide with the focused app's
own Alt shortcuts.

| Chord    | App                        |
|----------|----------------------------|
| Hyper+1  | Stream Deck                |
| Hyper+2  | TrackIR                    |
| Hyper+3  | Microsoft Flight Simulator |
| Hyper+4  | DCS World                  |
| Hyper+0  | reload the script          |

Add **Shift** to any chord (Hyper+Shift+1 …) to also move the app to the display
you are working on — the one holding the active window, or under the mouse if
nothing is focused — and maximize it there. The move is literally Win+Shift+Right
until the window lands on that display. A window that is already
borderless-fullscreen (a game) is moved but not maximized, since maximizing would
shrink it to the work area.

If the app isn't running, nothing happens. If it's minimized or hidden in the
tray, it's restored. If it's already in front, it stays there.

## Run

Requires [AutoHotkey v2](https://www.autohotkey.com). Double-click
`frontman.ahk`, or from this directory:

```bash
"<AutoHotkey dir>\v2\AutoHotkey64.exe" frontman.ahk
```

`<AutoHotkey dir>` is wherever the installer put it: `%LOCALAPPDATA%\Programs\AutoHotkey`
for a per-user install, `C:\Program Files\AutoHotkey` for all-users. Same
placeholder throughout this file.

It asks for admin (UAC) on launch. That's deliberate: Stream Deck runs elevated,
and Windows won't deliver keystrokes to a non-elevated hook while an elevated
window is focused — the chords would silently stop working whenever Stream Deck
was in front.

### Start at login without the UAC prompt

Task Scheduler → Create Task:

- General: **Run with highest privileges**
- Triggers: **At log on**
- Actions: Start a program
  - Program: `<AutoHotkey dir>\v2\AutoHotkey64.exe`
  - Arguments: full path to `frontman.ahk`
- Conditions: untick "Start the task only if the computer is on AC power"

Or from an admin PowerShell in this directory (adjust `$ahk` for an all-users
install):

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$a = New-ScheduledTaskAction -Execute $ahk -Argument "`"$PWD\frontman.ahk`"" -WorkingDirectory $PWD
$t = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
Register-ScheduledTask -TaskName frontman -Action $a -Trigger $t -Settings $s -RunLevel Highest
```

## Adding apps

Edit the `apps` map at the top of `frontman.ahk`. Each entry is keyed by the
letter/digit pressed with Hyper:

```ahk
"c", {name: "Claude", exe: "i)(^|\\)claude\.exe$"},
```

- `exe` — regex on the process name. Anchor with `(^|\\)…$` rather than `^`,
  since AHK may match against the full path.
- `title` / `class` — optional regexes to pin down one window when the process
  has several (Explorer, Electron/Qt apps, anything with a hidden helper window).
- `tray: true` — for apps that *hide* their window when "closed" to the tray
  instead of minimizing it (Stream Deck, TrackIR). Pair it with a `title` or
  `class` so the hidden-window pass can't grab an internal helper window.
- `nomove: true` — Hyper+Shift+<key> just focuses: never moved, never maximized.
  For apps that dislike being shoved across displays (an exclusive-fullscreen
  sim, say).

To find an app's exe/class/title, run `WindowSpy.ahk` from `<AutoHotkey dir>`
and hover over the window — the Windows stand-in for Karabiner-EventViewer's
frontmost-app panel.

## Stream Deck hotkeys

The chords fire on software-sent keystrokes too, so a Stream Deck "Hotkey"
action set to Right Alt + `1` works. (Keystrokes sent by *other AutoHotkey
scripts* are ignored unless that script sets `SendLevel 1` — an AHK convention,
not something Stream Deck is affected by.)

## Icon

`icons/frontman.svg` is the source. `icons/build-ico.ps1` renders it with headless
Chrome (or Edge) and packs a 16/24/32/48/256 `frontman.ico`; run it after editing
the SVG. The script loads the `.ico` for its tray icon, and Ahk2Exe embeds it as
the exe's icon via the `SetMainIcon` directive.

## Building a standalone exe

Ahk2Exe isn't in the base AutoHotkey install; fetch it once:

```bash
"<AutoHotkey dir>\v2\AutoHotkey64.exe" "<AutoHotkey dir>\UX\install-ahk2exe.ahk"
```

(Or open the AutoHotkey Dash from the Start menu and pick **Compile**.) Then,
from this directory:

```bash
"<AutoHotkey dir>\Compiler\Ahk2Exe.exe" /in frontman.ahk /out frontman.exe /base "<AutoHotkey dir>\v2\AutoHotkey64.exe"
```

`frontman.exe` runs without AutoHotkey installed. The `;@Ahk2Exe-*` directives at
the top of the script set its version info and mark it `requireAdministrator`,
so Windows shows the UAC prompt at launch (same reason as above). For a
prompt-free start at login, point the Task Scheduler task at `frontman.exe`
with no arguments.

Hyper+0 still reloads a compiled build, but reloads the *exe* — edit the `.ahk`
and recompile to pick up changes. Windows Defender occasionally flags freshly
compiled AutoHotkey exes; if it does, add an exclusion for the file.
