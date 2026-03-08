@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

if exist "%APP_DIR%\Antigravity\antigravity.exe" (
    start "Antigravity - DevConsole" "%APP_DIR%\Antigravity\antigravity.exe"
    exit
)

if exist "%COMMON_DIR%\Antigravity\antigravity.exe" (
    start "Antigravity - DevConsole" "%COMMON_DIR%\Antigravity\antigravity.exe"
    exit
)

where antigravity.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Antigravity - DevConsole" antigravity.exe
    exit
)

echo ERROR: Antigravity is not installed on this system or in portable mode.
pause
exit