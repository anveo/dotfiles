#SingleInstance Force

; #NoEnv is not needed in V2
; #Warn is default in V2
SendMode("Input")  ; Function call syntax
SetWorkingDir(A_ScriptDir)  ; Function call syntax

;=======================================================================================================================
; CAPS-UNLOCKED
;=======================================================================================================================
; This is a complete solution to map the CapsLock key to Control and Escape without losing the ability to toggle CapsLock
;
;  * Use CapsLock as Escape if it's the only key that is pressed and released within 300ms (configurable)
;  * Use CapsLock as LControl when used in conjunction with some other key or if it's held longer than 300ms
;  * Toggle CapsLock by pressing LControl+CapsLock

InstallKeybdHook()
SetCapsLockState("AlwaysOff")  ; Function call syntax with quoted parameter
StartTime := 0

*Capslock:: {
   global StartTime  ; Declare StartTime as global

   ;if (GetKeyState("LControl", "P")) {
   ;  KeyWait("CapsLock")
   ;  Send("{CapsLock Down}")
   ;  return
   ;}

   Send("{LControl Down}")
   State := (GetKeyState("Alt", "P") || GetKeyState("Shift", "P") || GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
   if (!State && (StartTime = 0)) {
      StartTime := A_TickCount
   }

   KeyWait("CapsLock")
   Send("{LControl Up}")

   condEscape := IniRead(A_ScriptDir . "\Settings.ini", "CapsUnlocked", "TapEscape", 1)
   if (State || !condEscape) {
      return
   }

   elapsedTime := A_TickCount - StartTime
   timeout := IniRead(A_ScriptDir . "\Settings.ini", "CapsUnlocked", "Timeout", 300)
   if ((A_PriorKey = "CapsLock") && (A_TickCount - StartTime < timeout)) {
      Send("{Esc}")
   }

   StartTime := 0
}
