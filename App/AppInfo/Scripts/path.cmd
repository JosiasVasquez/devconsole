@echo off
:: Recibir la ruta base
set "APP_DIR=%~1"
set "DATA_DIR=%APP_DIR%\..\Data"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%DATA_DIR%\home" mkdir "%DATA_DIR%\home"
if not exist "%DATA_DIR%\home\AppData" mkdir "%DATA_DIR%\home\AppData"
if not exist "%DATA_DIR%\home\AppData\Roaming" mkdir "%DATA_DIR%\home\AppData\Roaming"
if not exist "%DATA_DIR%\home\AppData\Local" mkdir "%DATA_DIR%\home\AppData\Local"
if not exist "%DATA_DIR%\npm" mkdir "%DATA_DIR%\npm"
if not exist "%DATA_DIR%\npm-cache" mkdir "%DATA_DIR%\npm-cache"
if not exist "%DATA_DIR%\uv-cache" mkdir "%DATA_DIR%\uv-cache"

:: 1. Inyectar todas las herramientas portables al PATH del sistema
set "PATH=%DATA_DIR%\npm;%APP_DIR%\uv;%APP_DIR%\NodeJS;%APP_DIR%\Git\cmd;%APP_DIR%\Git\bin;%APP_DIR%\Git\usr\bin;%APP_DIR%\PHP;%APP_DIR%\..\..\CommonFiles\uv;%APP_DIR%\..\..\CommonFiles\NodeJS;%APP_DIR%\..\..\CommonFiles\Git\cmd;%APP_DIR%\..\..\CommonFiles\Git\bin;%APP_DIR%\..\..\CommonFiles\Git\usr\bin;%APP_DIR%\..\..\CommonFiles\PHP;%PATH%"

:: 2. Variables exclusivas de los compiladores/gestores de paquetes
set "UV_CACHE_DIR=%DATA_DIR%\uv-cache"
set "npm_config_prefix=%DATA_DIR%\npm"
set "npm_config_cache=%DATA_DIR%\npm-cache"

:: 3. Aislamiento del perfil de usuario para portabilidad
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"
set "APPDATA=%DATA_DIR%\home\AppData\Roaming"
set "LOCALAPPDATA=%DATA_DIR%\home\AppData\Local"
set "OPENCODE_DISABLE_AUTOUPDATE=true"
