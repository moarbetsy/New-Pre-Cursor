@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\precursor.ps1" %*
exit /b %ERRORLEVEL%
