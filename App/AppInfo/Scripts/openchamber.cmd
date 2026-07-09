@echo off
setlocal EnableExtensions

set "APP_DIR=%~dp0..\.."
set "COMMON_DIR=%APP_DIR%\..\..\CommonFiles"

call "%~dp0path.cmd" "%APP_DIR%"
if errorlevel 1 (
    echo ERROR: fallo la inicializacion del entorno portable.
    pause
    exit /b 1
) 

set "OPENCHAMBER_DATA_DIR=%APP_DIR%\..\Data\OpenChamber"
set "OPENCODE_DATA_DIR=%APP_DIR%\..\Data\Opencode"
set "PORTABLE_CONFIG_DIR=%APP_DIR%\..\Data\home\.config\opencode"
set "PORTABLE_CONFIG_FILE=%PORTABLE_CONFIG_DIR%\opencode.json"

if not exist "%OPENCHAMBER_DATA_DIR%" mkdir "%OPENCHAMBER_DATA_DIR%"
if not exist "%OPENCODE_DATA_DIR%" mkdir "%OPENCODE_DATA_DIR%"
if not exist "%PORTABLE_CONFIG_DIR%" mkdir "%PORTABLE_CONFIG_DIR%"

if not exist "%PORTABLE_CONFIG_FILE%" (
    >"%PORTABLE_CONFIG_FILE%" echo {"autoupdate": false}
)

set "OPENCODE_CONFIG=%PORTABLE_CONFIG_FILE%"

if exist "%APP_DIR%\OpenChamber\OpenChamber.exe" (
    start "OpenChamber - Dev Console" "%APP_DIR%\OpenChamber\OpenChamber.exe" %*
    exit /b 0
)

if exist "%COMMON_DIR%\OpenChamber\OpenChamber.exe" (
    start "OpenChamber - Dev Console" "%COMMON_DIR%\OpenChamber\OpenChamber.exe" %*
    exit /b 0
)

where OpenChamber.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "OpenChamber - Dev Console" OpenChamber.exe %*
    exit /b 0
)

echo ERROR: OpenChamber no esta instalado.
pause
exit /b 1
