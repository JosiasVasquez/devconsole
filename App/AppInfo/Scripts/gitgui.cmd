@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

if exist "%APP_DIR%\Git\cmd\git-gui.exe" (
    start "Git GUI - DevConsole" "%APP_DIR%\Git\cmd\git-gui.exe"
    exit
)

if exist "%COMMON_DIR%\Git\cmd\git-gui.exe" (
    start "Git GUI - DevConsole" "%COMMON_DIR%\Git\cmd\git-gui.exe"
    exit
)

where git-gui.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Git GUI - DevConsole" git-gui.exe
    exit
)

echo ERROR: Git is not installed on this system or in portable mode.
pause
exit