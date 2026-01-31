@echo off
REM setup-cursor.cmd - Global wrapper for the setup-cursor PowerShell script
REM Place this file in a directory that's in your PATH (e.g., C:\Windows\System32 or create a ~/bin folder)

REM Find the setup-cursor directory (assumes this wrapper is in the same directory as run.ps1)
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_PATH=%SCRIPT_DIR%run.ps1"

REM Remove trailing backslash if present
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Check if run.ps1 exists
if not exist "%SCRIPT_PATH%" (
    echo ERROR: setup-cursor script not found at: %SCRIPT_PATH%
    echo Please ensure setup-cursor.cmd is in the same directory as run.ps1
    pause
    exit /b 1
)

REM Pass all arguments to the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" %*

REM Exit with the same exit code as the PowerShell script
exit /b %ERRORLEVEL%