; UltraDocker v2.0.0 (2021-09-27)
; By Barak Shoshany (baraksh@gmail.com) (http://baraksh.com)
; GitHub repository: https://github.com/bshoshany/UltraDocker

#SingleInstance Force
#NoEnv
SendMode Input

; When the trigger (caps lock or mouse button 4) is pressed, dock the window to the left half, right half, or center depending on the horizontal position of the mouse, and to the top half, bottom half, or full height depending on the vertical position of the mouse.
; Optionally, adding the Ctrl key to the trigger will enable 16:9 mode. The window will then be resized while maintaining a 16:9 aspect ratio, e.g. for screen sharing.
; Enabling 16:9 mode while the mouse is within 10% of the center of the screen will resize the window to full height, to achieve the maximum window size possible, while maintaining a 16:9 aspect ratio.
;CapsLock::
;^CapsLock::
;XButton1::
^XButton1::
    ; Get the unique ID (HWND) of the active window.
    window := WinExist("A")
    ; Restore the window if it is maximized, since resizing a maximized window may lead to unexpected results.
    WinGet, is_min_max, MinMax, ahk_id %window%
    If (is_min_max != 0)
    {
        WinRestore, ahk_id %window%
    }
    ; Get the total work area, i.e. the size of the screen minus the taskbar.
    SysGet, area, MonitorWorkArea
    screen_width := areaRight - areaLeft
    screen_height := areaBottom - areaTop
    ; Find the current x and y coordinates of the mouse on the screen.
    CoordMode, Mouse, Screen
    MouseGetPos, x, y
    ; Find the size of the window's border by comparing the x coordinate of the mouse with respect to the entire window to its coordinate with respect to just the window's client area, which excludes the borders.
    CoordMode, Mouse, Window
    MouseGetPos, x1, , A
    CoordMode, Mouse, Client
    MouseGetPos, x2, , A
    border_x := x1 - x2
    ; Dock the window to the left half, right half, or center based on the horizontal position of the mouse.
    If (x < screen_width / 3)
    {
        ; Left third of the screen: dock to the left at 50% screen width.
        width := (screen_width / 2) + (2 * border_x)
        left := -border_x
    }
    Else If (x > screen_width * 2 / 3)
    {
        ; Right third of the screen: dock to the right at 50% screen width.
        width := (screen_width / 2) + (2 * border_x)
        left := screen_width - width + border_x
    }
    Else
    {
        ; Middle third of the screen: dock to the center at 60% screen width.
        width := (screen_width * 0.6) + (2 * border_x)
        left := (screen_width - width) / 2
    }
    If (GetKeyState("Ctrl"))
    {
        ; If the Ctrl key is down, enable 16:9 mode.
        If (x > screen_width * 0.4 and x < screen_width * 0.6 and y > screen_height * 0.4 and y < screen_height * 0.6)
        {
            ; Special case: if the mouse is within 10% of the center of the screen, resize the window to full height and adjust the ratio to 16:9.
            height := screen_height + border_x
            width := height * 16 / 9
            top = 0
            left := (screen_width - width) / 2
        }
        Else
        {
            ; Dock the window to the top, bottom, or center based on the vertical position of the mouse while maintaining a 16:9 ratio.
            height := width * 9 / 16
            If (y < screen_height / 3)
            {
                ; Top third of the screen: dock to the top.
                top := 0
            }
            Else If (y > screen_height * 2 /3)
            {
                ; Bottom third of the screen: dock to the bottom.
                top := screen_height - height + border_x
            }
            Else
            {
                ; Elsewhere: dock to the center.
                top := (screen_height - height) / 2
            }
        }
    }
    Else
    {
        ; If the Ctrl key is not down, dock the window to the top half, bottom half, or full height based on the vertical position of the mouse.
        If (y < screen_height * 0.15)
        {
            ; Top 15% of the screen: dock to the top at 50% screen height.
            height := (screen_height / 2) + border_x
            top := 0
        }
        Else If (y > screen_height * 0.85)
        {
            ; Bottom 15% of the screen: dock to the bottom at 50% screen height.
            height := (screen_height / 2) + border_x
            top := screen_height - height + border_x
        }
        Else
        {
            ; Elsewhere: dock at full height.
            height := screen_height + border_x
            top := 0
        }
    }
    ; Move the window to the desired position with the desired size.
    WinMove, ahk_id %window%, , %left%, %top%, %width%, %height%
    Return
