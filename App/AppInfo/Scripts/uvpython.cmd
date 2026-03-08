@echo off
setlocal

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

if exist "%APP_DIR%\uv\uv.exe" (
    start "Python Interactive (uv) - DevConsole" "%APP_DIR%\uv\uv.exe" run python
    exit
)

if exist "%COMMON_DIR%\uv\uv.exe" (
    start "Python Interactive (uv) - DevConsole" "%COMMON_DIR%\uv\uv.exe" run python
    exit
)

where uv.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "Python Interactive (uv) - DevConsole" uv.exe run python
    exit
)

:: 4. Error
echo ERROR: uv (Python) is not installed on this system or in portable mode.
pause
exit