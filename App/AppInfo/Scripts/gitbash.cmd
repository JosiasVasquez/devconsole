@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

call "%~dp0path.cmd" "%APP_DIR%"

if exist "%APP_DIR%\Git\git-bash.exe" (
    start "Git Bash - DevConsole" "%APP_DIR%\Git\git-bash.exe"
    exit
)

if exist "%COMMON_DIR%\Git\git-bash.exe" (
    start "Git Bash - DevConsole" "%COMMON_DIR%\Git\git-bash.exe"
    exit
)

where git-bash.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Git Bash - DevConsole" git-bash.exe
    exit
)

echo ERROR: Git is not installed on this system or in portable mode.
pause
exit