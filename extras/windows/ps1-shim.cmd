@echo off
rem Generic launcher: runs the .ps1 with this file's name, from this file's dir.
rem install.ps1 copies it as C:\bin\<name>.cmd for every bin\<name>.ps1, so
rem C:\bin\foo.cmd runs C:\bin\foo.ps1 (also a plain copy).
setlocal
set "PS=powershell"
where pwsh >nul 2>&1 && set "PS=pwsh"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dpn0.ps1" %*
exit /b %ERRORLEVEL%
