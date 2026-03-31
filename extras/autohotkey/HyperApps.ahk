#Requires AutoHotkey v2.0
#SingleInstance Force

; Hyper = Win+Ctrl+Alt+Shift (equivalent to Cmd+Ctrl+Alt+Shift on Mac)
; To find process names: open Task Manager -> Details tab while the app is running

FocusOrRun(exeName, exePath) {
    if WinExist("ahk_exe " . exeName) {
        WinActivate("ahk_exe " . exeName)
    } else {
        Run(exePath)
    }
}

; Move focused window to next monitor (equivalent to hyper+k on Mac)
#^!+k:: {
    activeWin := WinExist("A")
    if !activeWin
        return
    monitors := []
    MonitorGetCount := MonitorGetCount()
    curMon := 0
    loop MonitorGetCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        monitors.Push({ l: left, t: top, r: right, b: bottom, idx: A_Index })
    }
    WinGetPos(&wx, &wy, &ww, &wh, "A")
    winCx := wx + ww // 2
    winCy := wy + wh // 2
    curIdx := 0
    for m in monitors {
        if (winCx >= m.l && winCx < m.r && winCy >= m.t && winCy < m.b) {
            curIdx := A_Index
            break
        }
    }
    nextIdx := Mod(curIdx, monitors.Length) + 1
    next := monitors[nextIdx]
    monW := next.r - next.l
    monH := next.b - next.t
    WinMove(next.l + (monW - ww) // 2, next.t + (monH - wh) // 2, ww, wh, "A")
}

; --- App switcher ---
; Adjust exe paths below if apps are installed in non-default locations.
; Ghostty is Mac-only; hyper+t is mapped to Windows Terminal here instead.

#^!+1:: FocusOrRun("chrome.exe",            "C:\Program Files\Google\Chrome\Application\chrome.exe")
#^!+2:: FocusOrRun("Todoist.exe",           "C:\Users\" . A_UserName . "\AppData\Local\Programs\Todoist\Todoist.exe")
#^!+3:: FocusOrRun("Code.exe",              "C:\Users\" . A_UserName . "\AppData\Local\Programs\Microsoft VS Code\Code.exe")

#^!+t:: FocusOrRun("wt.exe",               "wt.exe")  ; Windows Terminal (substitute for Ghostty)

#^!+o:: FocusOrRun("Todoist.exe",           "C:\Users\" . A_UserName . "\AppData\Local\Programs\Todoist\Todoist.exe")

#^!+n:: FocusOrRun("Notion.exe",            "C:\Users\" . A_UserName . "\AppData\Local\Programs\Notion\Notion.exe")
#^!+x:: FocusOrRun("NotionCalendar.exe",    "C:\Users\" . A_UserName . "\AppData\Local\Programs\Notion Calendar\NotionCalendar.exe")

#^!+s:: FocusOrRun("slack.exe",             "C:\Users\" . A_UserName . "\AppData\Local\slack\slack.exe")
#^!+d:: FocusOrRun("Discord.exe",           "C:\Users\" . A_UserName . "\AppData\Local\Discord\app-*\Discord.exe")

#^!+l:: FocusOrRun("Linear.exe",            "C:\Users\" . A_UserName . "\AppData\Local\Programs\Linear\Linear.exe")
#^!+f:: FocusOrRun("Figma.exe",             "C:\Users\" . A_UserName . "\AppData\Local\Figma\Figma.exe")
#^!+m:: FocusOrRun("Miro.exe",              "C:\Users\" . A_UserName . "\AppData\Local\Programs\Miro\Miro.exe")
#^!+p:: FocusOrRun("1Password.exe",         "C:\Program Files\1Password\app\8\1Password.exe")
#^!+j:: FocusOrRun("datagrip64.exe",        "C:\Program Files\JetBrains\DataGrip *\bin\datagrip64.exe")
#^!+z:: FocusOrRun("Zoom.exe",              "C:\Users\" . A_UserName . "\AppData\Roaming\Zoom\bin\Zoom.exe")
#^!+c:: FocusOrRun("Claude.exe",            "C:\Users\" . A_UserName . "\AppData\Local\AnthropicClaude\claude.exe")
#^!+g:: FocusOrRun("ChatGPT.exe",           "C:\Users\" . A_UserName . "\AppData\Local\Programs\ChatGPT\ChatGPT.exe")
#^!+b:: FocusOrRun("blender.exe",           "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe")
#^!+a:: FocusOrRun("Ableton Live 12 Suite.exe", "C:\ProgramData\Ableton\Live 12\Program\Ableton Live 12 Suite.exe")
