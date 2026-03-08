$DataDir = "$PSScriptRoot\..\..\Data"

$Carpetas = @(
    "$DataDir\home",
    "$DataDir\home\.ssh",
    "$DataDir\home\.gnupg",
    "$DataDir\uv-cache",
    "$DataDir\npm-cache"
)

foreach ($ruta in $Carpetas) {
    if (-not (Test-Path $ruta)) {
        New-Item -ItemType Directory -Force -Path $ruta | Out-Null
    }
}