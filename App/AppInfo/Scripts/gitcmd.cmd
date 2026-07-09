@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

call "%~dp0path.cmd" "%APP_DIR%"

if exist "%APP_DIR%\Git\git-cmd.exe" (
    start "Git CMD - DevConsole" "%APP_DIR%\Git\git-cmd.exe"
    exit
)

if exist "%COMMON_DIR%\Git\git-cmd.exe" (
    start "Git CMD - DevConsole" "%COMMON_DIR%\Git\git-cmd.exe"
    exit
)

where git-cmd.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Git CMD - DevConsole" git-cmd.exe
    exit
)

echo ERROR: Git is not installed on this system or in portable mode.
pause
exit