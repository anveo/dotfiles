; frontman.ahk — Hyper+<key> brings an app to the foreground.
; Hyper+Shift+<key> also moves it to the display you are working on, maximized.
;
; Hyper is Right Alt, used as a pure layer key: it does nothing on its own and
; never reaches Windows as Alt, so Hyper chords can't collide with Alt+<key>
; shortcuts in the focused app.
;
; Requires AutoHotkey v2 (https://www.autohotkey.com).

#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode "RegEx"   ; title, ahk_class and ahk_exe are all matched as PCRE regexes

; Ahk2Exe metadata. UpdateManifest 1 marks the exe requireAdministrator, so a
; compiled build gets its UAC prompt from Windows at launch and never needs
; the self-relaunch below.
;@Ahk2Exe-SetName frontman
;@Ahk2Exe-SetDescription Hyper+key brings an app to the front
;@Ahk2Exe-SetVersion 1.0.0
;@Ahk2Exe-UpdateManifest 1
;@Ahk2Exe-SetMainIcon icons\frontman.ico

; Stream Deck runs elevated. A non-elevated keyboard hook receives nothing while
; an elevated window has focus (UIPI), so Hyper chords would go dead as soon as
; Stream Deck came to the front. Re-launch as admin. The /restart check stops a
; relaunch loop if elevation fails; declining the UAC prompt just carries on
; unelevated. To skip the prompt at login, start this from a Task Scheduler
; task with "Run with highest privileges" (see README).
if !A_IsAdmin && !RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)") {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
        ExitApp
    }
}

; ---------------------------------------------------------------------------
; App table. Key = the key pressed with Hyper. Fields:
;   name   label shown in the tray tooltip / debug
;   exe    regex against the process name. ahk_exe may be compared against the
;          full path depending on how the window was found, so anchor on the
;          basename with (^|\\) rather than ^.
;   title  (optional) regex against the window title
;   class  (optional) regex against the window class
;   tray   (optional) true if the app hides its window rather than minimizing
;          when "closed" to the tray. Enables a second pass over hidden windows;
;          give such entries a title/class so the pass can't grab an internal
;          helper window. Pattern ideas: run WindowSpy.ahk from the AutoHotkey
;          install directory and hover the target window.
;   nomove (optional) true to make Hyper+Shift+<key> behave like Hyper+<key>:
;          never moved, never maximized (e.g. an exclusive-fullscreen sim).
;
; Regex flags go at the front of the pattern, e.g. "i)" for case-insensitive.
; ---------------------------------------------------------------------------
apps := Map(
    "1", {name: "Stream Deck", exe: "i)(^|\\)StreamDeck\.exe$",        title: "^Stream Deck$",  class: "^Qt\d+QWindowIcon$", tray: true},
    "2", {name: "TrackIR",     exe: "i)(^|\\)TrackIR5\.exe$",          title: "^TrackIR \d",                                  tray: true},
    "3", {name: "MSFS",        exe: "i)(^|\\)FlightSimulator(2024)?\.exe$"},
    "4", {name: "DCS World",   exe: "i)(^|\\)DCS\.exe$"},
)

; ---------------------------------------------------------------------------
; Hyper layer
; ---------------------------------------------------------------------------
global hyperDown := false

; * = fire regardless of other modifiers. The bare hotkey swallows RAlt so
; Windows never sees it as Alt (no menu-bar activation on tap, no Alt+F4).
*RAlt:: {
    global hyperDown := true
}
*RAlt up:: {
    global hyperDown := false
}

; Tracking state in a variable rather than GetKeyState(...,"P") means the
; chords also fire when sent by software (e.g. a Stream Deck "hotkey" action).
HotIf (*) => hyperDown

for key, app in apps
    Hotkey "*" key, FocusApp.Bind(app)

Hotkey "*0", (*) => Reload()

HotIf

; ---------------------------------------------------------------------------
; Focus logic
; ---------------------------------------------------------------------------
; Hyper+<key>        focus the app where it is.
; Hyper+Shift+<key>  focus it, bring it to the display you're working on, maximize.
FocusApp(app, *) {
    ; Logical (not physical) Shift state so software-sent chords work too.
    ; Read the current display before we activate anything, since that's what
    ; "the display I'm on" means.
    move := GetKeyState("Shift") && !(app.HasProp("nomove") && app.nomove)
    target := move ? CurrentMonitor() : 0
    Log(app.name ": shift=" GetKeyState("Shift") " ctrl=" GetKeyState("Ctrl") " alt=" GetKeyState("Alt") " win=" GetKeyState("LWin") " move=" move " target=" target " active=" WinGetProcessName("A") "/" WinGetClass("A") " on " WindowMonitor(WinExist("A")))

    hwnd := FindWindow(app)
    if !hwnd {
        Log("  not running")
        return  ; not running: no-op by design
    }
    WinActivate hwnd
    Log("  activated " hwnd " on " WindowMonitor(hwnd) " minmax=" WinGetMinMax(hwnd))
    if move {
        MoveToMonitor(hwnd, target)
        ; Fill the display. A borderless-fullscreen window (a game) already
        ; does; maximizing it would shrink it to the work area, so leave it.
        if !IsFullscreen(hwnd)
            WinMaximize hwnd
        Log("  after move: on " WindowMonitor(hwnd) " minmax=" WinGetMinMax(hwnd) " active=" WinGetProcessName("A"))
    }
}

Log(msg) {
    static DEBUG := false  ; flip on and RAlt+0 to trace chords in frontman.log
    if DEBUG
        FileAppend FormatTime(, "HH:mm:ss") " " msg "`n", A_ScriptDir "\frontman.log", "UTF-8"
}

FindWindow(app) {
    crit := Criteria(app)

    ; Pass 1: a normal (visible, possibly minimized) window. WinActivate
    ; restores a minimized window on its own.
    DetectHiddenWindows false
    if hwnd := WinExist(crit)
        return hwnd

    ; Pass 2: app hides its window when sent to the tray. Un-hide it.
    if app.HasProp("tray") && app.tray {
        DetectHiddenWindows true
        if hwnd := WinExist(crit) {
            WinShow hwnd
            return hwnd
        }
    }
    return 0
}

; The display the active window is on; if there's no real window in front
; (desktop), the one under the mouse.
CurrentMonitor() {
    MONITOR_DEFAULTTONEAREST := 2
    if (hwnd := WinExist("A")) && !(WinGetClass(hwnd) ~= "^(Progman|WorkerW)$")
        return WindowMonitor(hwnd)
    CoordMode "Mouse", "Screen"
    MouseGetPos &x, &y
    ; POINT is passed by value; on x64 that's the two ints packed into one register.
    return DllCall("MonitorFromPoint", "int64", (y << 32) | (x & 0xFFFFFFFF), "uint", MONITOR_DEFAULTTONEAREST, "ptr")
}

WindowMonitor(hwnd) {
    MONITOR_DEFAULTTONEAREST := 2
    return DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
}

; Windows has no "fullscreen" flag; a borderless-fullscreen window is just a
; frameless window that exactly covers its display. Check for that.
IsFullscreen(hwnd) {
    if WinGetMinMax(hwnd) != 0
        return false
    WS_CAPTION_OR_THICKFRAME := 0x00C40000
    if WinGetStyle(hwnd) & WS_CAPTION_OR_THICKFRAME
        return false
    WinGetPos &x, &y, &w, &h, hwnd
    ; MONITORINFO: cbSize, rcMonitor (l,t,r,b), rcWork, dwFlags
    mi := Buffer(40, 0), NumPut("uint", 40, mi)
    DllCall("GetMonitorInfo", "ptr", WindowMonitor(hwnd), "ptr", mi)
    l := NumGet(mi, 4, "int"), t := NumGet(mi, 8, "int"), r := NumGet(mi, 12, "int"), b := NumGet(mi, 16, "int")
    return x <= l && y <= t && x + w >= r && y + h >= b
}

; Same as pressing Win+Shift+Right until the window lands on the target
; display. Windows keeps the window's relative size/position and maximized
; state and handles the DPI change, so there's no geometry to compute here.
MoveToMonitor(hwnd, target) {
    Loop MonitorGetCount() - 1 {
        if WindowMonitor(hwnd) = target
            return
        ; {Blind}: don't release/re-press held modifiers around the send. Hyper
        ; is physically down but suppressed; letting Send "restore" it would
        ; leak a real Alt press to Windows.
        Send "{Blind}+#{Right}"
        Sleep 100
    }
}

Criteria(app) {
    crit := app.HasProp("title") ? app.title : ""
    crit .= " ahk_exe " app.exe
    if app.HasProp("class")
        crit .= " ahk_class " app.class
    return crit
}

; ---------------------------------------------------------------------------
; Tray
; ---------------------------------------------------------------------------
; A compiled build carries the icon as its main resource (SetMainIcon above),
; so only the script form needs to load it from disk.
if !A_IsCompiled && FileExist(A_ScriptDir "\icons\frontman.ico")
    TraySetIcon A_ScriptDir "\icons\frontman.ico"

tip := "frontman — Hyper (RAlt) + key focuses; + Shift also moves here, maximized"
for key, app in apps
    tip .= "`n  " key "  " app.name
tip .= "`n  0  reload"
A_IconTip := tip
