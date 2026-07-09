@echo off
setlocal EnableExtensions

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

call "%~dp0path.cmd" "%APP_DIR%"

set "OPENCODE_DATA_DIR=%APP_DIR%\..\Data\Opencode"
set "PORTABLE_CONFIG_DIR=%APP_DIR%\..\Data\home\.config\opencode"
set "PORTABLE_CONFIG_FILE=%PORTABLE_CONFIG_DIR%\opencode.json"
set "OPENCODE_DISABLE_MOUSE=true"

if not exist "%OPENCODE_DATA_DIR%" mkdir "%OPENCODE_DATA_DIR%"
if not exist "%PORTABLE_CONFIG_DIR%" mkdir "%PORTABLE_CONFIG_DIR%"

if not exist "%PORTABLE_CONFIG_FILE%" (
    >"%PORTABLE_CONFIG_FILE%" echo {"autoupdate": false}
)

set "OPENCODE_CONFIG=%PORTABLE_CONFIG_FILE%"

set "OPENCODE_EXE="

if exist "%APP_DIR%\OpenChamber\resources\opencode-cli\opencode.exe" (
    set "OPENCODE_EXE=%APP_DIR%\OpenChamber\resources\opencode-cli\opencode.exe"
)

if not defined OPENCODE_EXE if exist "%COMMON_DIR%\OpenChamber\resources\opencode-cli\opencode.exe" (
    set "OPENCODE_EXE=%COMMON_DIR%\OpenChamber\resources\opencode-cli\opencode.exe"
)

if defined OPENCODE_EXE (
    "%OPENCODE_EXE%" %*
    exit /b %ERRORLEVEL%
)

where opencode.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    opencode.exe %*
    exit /b %ERRORLEVEL%
)

echo ERROR: Opencode CLI no esta instalado.
pause
exit /b 1
