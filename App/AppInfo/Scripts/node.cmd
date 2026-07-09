@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

call "%~dp0path.cmd" "%APP_DIR%"

if exist "%APP_DIR%\NodeJS\node.exe" (
    start "Node Interactive - DevConsole" "%APP_DIR%\NodeJS\node.exe"
    exit
)

if exist "%COMMON_DIR%\NodeJS\node.exe" (
    start "Node Interactive - DevConsole" "%COMMON_DIR%\NodeJS\node.exe"
    exit
)

where node.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Node Interactive - DevConsole" node.exe
    exit
)

echo ERROR: Node.js is not installed on this system or in portable mode.
pause
exit