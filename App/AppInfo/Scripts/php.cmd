@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

if exist "%APP_DIR%\PHP\php.exe" (
    start "PHP Interactive - DevConsole" "%APP_DIR%\PHP\php.exe" -a
    exit
)

if exist "%COMMON_DIR%\PHP\php.exe" (
    start "PHP Interactive - DevConsole" "%COMMON_DIR%\PHP\php.exe" -a
    exit
)

where php.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "PHP Interactive - DevConsole" php.exe -a
    exit
)

echo ERROR: PHP is not installed on this system or in portable mode.
pause
exit