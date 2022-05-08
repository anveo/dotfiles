#NoEnv
#SingleInstance Force ; prevents multiple instances of script from running
#Persistent
;MsgBox, The script is running ;you can uncomment this to verify the script is running, also you can look in the tray for the green autohotkey icon.

; set these values to the name of your key mapping configured in MSFS using this as a reference: https://www.autohotkey.com/docs/KeyList.htm
; a key must be mapped on your keyboard for trim nose up and trim nose down.
TrimKeyNoseDown = PgDn
TrimKeyNoseUp = PgUp

; set the number of key repeats. I've found this to be fairly realistic and usable. tweak as desired.
; KeyDelay = 0 works best for me, but if it seems like key presses are getting missed you could bump this up to 1 or 2.
KeyDelay = 0
Repeats = 100

cnt = 0

3Joy22::	

KeyWait,3Joy22
KeyWait,3Joy22,D T0.095
cnt++

If(ErrorLevel) {
	Send {%TrimKeyNoseDown% down}
	sleep %KeyDelay%
	Send {%TrimKeyNoseDown% up}
	cnt = 0
}
else {
	if(cnt > 3) {
		Loop %Repeats% {
			Send {%TrimKeyNoseDown% down}
			sleep %KeyDelay%
			Send {%TrimKeyNoseDown% up}
			cnt = 0
		}
	}

}
return

3Joy23::	
	KeyWait,3Joy23
	KeyWait,3Joy23,D T0.095
	cnt++ 

If(ErrorLevel) {
	Send {%TrimKeyNoseUp% down}
	sleep %KeyDelay%
	Send {%TrimKeyNoseUp% up}
	cnt = 0
}
else {
	if(cnt > 3) {

		Loop %Repeats% {
			Send {%TrimKeyNoseUp% down}
			sleep %KeyDelay%
			Send {%TrimKeyNoseUp% up}
			cnt = 0
		}
	}
}
return
