@echo off
rem Double-click to copy extras\windows\bin\* into C:\bin.
rem Args pass through, e.g.: install-windows -BinDir D:\bin -Force
setlocal
set "PS=powershell"
where pwsh >nul 2>&1 && set "PS=pwsh"
set "PAUSEARG="
echo %cmdcmdline% | findstr /i /c:"/c" >nul && set "PAUSEARG=-Pause"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0extras\windows\install.ps1" %PAUSEARG% %*
exit /b %ERRORLEVEL%
