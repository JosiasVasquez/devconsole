# ==========================================
# DEV CONSOLE PORTABLE - MANAGER SCRIPT
# ==========================================
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- 1. PATH SETUP ---
$BaseDir = Join-Path $PSScriptRoot '..\..'
$AppDir = Join-Path $BaseDir 'App'
$CommonFilesDir = Join-Path $BaseDir '..\CommonFiles'

& (Join-Path $PSScriptRoot 'Initialize.ps1')

if (-not (Test-Path $CommonFilesDir)) { New-Item -ItemType Directory -Path $CommonFilesDir -Force | Out-Null }

# --- 2. HELPER FUNCTIONS ---
function Write-Title {
    param([string]$Title)
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}

function Get-CleanVersion {
    param([string]$RawVersion)
    if ($RawVersion -match '(\d+\.\d+(?:\.\d+)?)') { 
        try { return [version]$matches[1] } catch {} 
    }
    return $null
}

function Crear-Lanzador {
    param([string]$NuevoNombre)
    $exeOriginal = Join-Path $BaseDir 'cmd.exe'
    $exeNuevo = Join-Path $BaseDir $NuevoNombre
    if (Test-Path $exeOriginal) {
        Copy-Item -Path $exeOriginal -Destination $exeNuevo -Force
        Write-Host "Launcher created/updated: $NuevoNombre" -ForegroundColor DarkGray
    } else {
        Write-Host "Error: Base cmd.exe not found in root to create $NuevoNombre" -ForegroundColor Red
    }
}

# --- 3. VERSION CHECKERS ---
function Get-LatestVersions {
    Write-Host "Fetching latest versions from internet..." -ForegroundColor Yellow
    $global:Latest = @{}
    
    try {
        $n = Invoke-RestMethod 'https://nodejs.org/dist/index.json'
        $global:Latest.Node = ($n | Where-Object { $_.lts -ne $false })[0].version
        
        $global:Latest.UV = (Invoke-RestMethod 'https://api.github.com/repos/astral-sh/uv/releases/latest').tag_name
        
        $apiGit = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest'
        $global:Latest.Git = $apiGit.name -replace 'Git for Windows ',''
        $global:Latest.GitUrl = ($apiGit.assets | Where-Object { $_.name -match 'PortableGit-.*-64-bit\.7z\.exe' }).browser_download_url

        $req = Invoke-WebRequest -Uri 'https://windows.php.net/download/' -UseBasicParsing
        if ($req.Content -match 'href="(/downloads/releases/php-(8\.\d+\.\d+)-Win32-vs\d+-x64\.zip)"') {
            $global:Latest.PHPUrl = "https://windows.php.net" + $matches[1]
            $global:Latest.PHP = $matches[2]
        }

        $wg = winget show Google.Antigravity --accept-source-agreements 2>$null
        if ($wg -match 'Version:\s+([\d\.]+)') {
            $global:Latest.Antigravity = $matches[1]
        }
    } catch {
        Write-Host "Warning: Could not fetch some online versions. Check your internet connection." -ForegroundColor Red
    }
}

function Get-LocalVersion {
    param([string]$Tool, [string]$Path, [string]$Type)
    $ver = $null
    try {
        if ($Type -eq 'System') {
            if ($Tool -eq 'Node') { $ver = (node -v 2>$null) }
            if ($Tool -eq 'UV') { $ver = (uv --version 2>$null) }
            if ($Tool -eq 'Git') { $ver = (git --version 2>$null) }
            if ($Tool -eq 'PHP') { $ver = (php -v 2>$null) }
            if ($Tool -eq 'Antigravity') { 
                $out = winget list --id Google.Antigravity --accept-source-agreements 2>$null
                if ($out -match '([\d\.]+)') { $ver = $matches[1] }
            }
        } else {
            if ($Tool -eq 'Node' -and (Test-Path "$Path\node.exe")) { $ver = (& "$Path\node.exe" -v) }
            if ($Tool -eq 'UV' -and (Test-Path "$Path\uv.exe")) { $ver = (& "$Path\uv.exe" --version) }
            if ($Tool -eq 'Git' -and (Test-Path "$Path\cmd\git.exe")) { $ver = (& "$Path\cmd\git.exe" --version) }
            if ($Tool -eq 'PHP' -and (Test-Path "$Path\php.exe")) { $ver = (& "$Path\php.exe" -v) }
            if ($Tool -eq 'Antigravity' -and (Test-Path $Path)) {
                $exe = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -notmatch "unins|setup" } | Select-Object -First 1
                if ($exe) { $ver = $exe.VersionInfo.ProductVersion }
            }
        }
    } catch {}
    return Get-CleanVersion $ver
}

# --- 4. INSTALLERS ---
function Install-Tool {
    param([string]$Tool, [string]$Scope)
    
    if ($Scope -eq 'System') {
        Write-Host "Configuring launcher for current System installation of $Tool..." -ForegroundColor Cyan
    } else {
        Write-Host "Installing/Updating $Tool ($Scope Portable)..." -ForegroundColor Cyan
    }

    $target = if ($Scope -eq 'App') { "$AppDir" } else { "$CommonFilesDir" }

    switch ($Tool) {
        'Git' {
            if ($Scope -ne 'System') {
                $dir = "$target\Git"
                $exe = "$PSScriptRoot\git.exe"
                Invoke-WebRequest -Uri $global:Latest.GitUrl -OutFile $exe
                Start-Process -FilePath $exe -ArgumentList "-y -o`"$dir`"" -Wait -NoNewWindow
                if (Test-Path $exe) { Remove-Item $exe }
            }
            # Crea los ejecutables maestros sin importar la ruta elegida
            Crear-Lanzador -NuevoNombre 'GitBash.exe'
            Crear-Lanzador -NuevoNombre 'GitCMD.exe'
            Crear-Lanzador -NuevoNombre 'GitGUI.exe'
        }
        'Node' {
            if ($Scope -ne 'System') {
                $dir = "$target\NodeJS"
                $ver = $global:Latest.Node
                $url = "https://nodejs.org/dist/$ver/node-$ver-win-x64.zip"
                $zip = "$PSScriptRoot\node.zip"
                Invoke-WebRequest -Uri $url -OutFile $zip
                if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
                Expand-Archive -Path $zip -DestinationPath $target -Force
                Remove-Item $zip
                Rename-Item -Path "$target\node-$ver-win-x64" -NewName 'NodeJS'
            }
            Crear-Lanzador -NuevoNombre 'NodeJS.exe'
        }
        'UV' {
            if ($Scope -ne 'System') {
                $dir = "$target\uv"
                $url = 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip'
                $zip = "$PSScriptRoot\uv.zip"
                Invoke-WebRequest -Uri $url -OutFile $zip
                if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
                Expand-Archive -Path $zip -DestinationPath $dir -Force
                Remove-Item $zip
            }
            Crear-Lanzador -NuevoNombre 'PythonInteractive.exe'
        }
        'PHP' {
            if ($Scope -ne 'System') {
                $dir = "$target\PHP"
                $url = $global:Latest.PHPUrl
                $zip = "$PSScriptRoot\php.zip"
                Invoke-WebRequest -Uri $url -OutFile $zip
                if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Expand-Archive -Path $zip -DestinationPath $dir -Force
                Remove-Item $zip
            }
            Crear-Lanzador -NuevoNombre 'PHPInteractive.exe'
        }
        'Antigravity' {
            if ($Scope -ne 'System') {
                $dir = "$target\Antigravity"
                $dataBackup = "$target\Antigravity_Data_Backup"
                
                if (Test-Path "$dir\data") {
                    Write-Host "Backing up portable data settings..." -ForegroundColor DarkGray
                    Move-Item -Path "$dir\data" -Destination $dataBackup -Force
                }
                
                if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
                
                $arg = '/VERYSILENT /NOICONS /DIR="' + $dir + '" /MERGETASKS=!runcode,!addtopath,!desktopicon,!addcontextmenufiles,!addcontextmenufolders,!associatewithfiles'
                $opc = 'install', '--id', 'Google.Antigravity', '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--force', '--override', ("`"$arg`"")
                
                Start-Process winget -ArgumentList $opc -Wait -NoNewWindow
                
                if (Test-Path $dataBackup) {
                    Write-Host "Restoring portable data settings..." -ForegroundColor DarkGray
                    Move-Item -Path $dataBackup -Destination "$dir\data" -Force
                } else {
                    New-Item -ItemType Directory -Path "$dir\data" -Force | Out-Null
                }
            }
            # Crea un solo ejecutable maestro, el .cmd hará el ruteo
            Crear-Lanzador -NuevoNombre 'Antigravity.exe'
        }
    }
    Write-Host "$Tool setup/update completed successfully." -ForegroundColor Green
}

# --- 5. MAIN LOGIC (MENUS) ---

function Menu-Install {
    while ($true) {
        Write-Title "INSTALL TOOLS"
        Write-Host "1. Git"
        Write-Host "2. Node (LTS)"
        Write-Host "3. uv (Python)"
        Write-Host "4. PHP"
        Write-Host "5. Antigravity"
        Write-Host "6. All of the above"
        Write-Host "Q. Back to Main Menu"
        
        $toolOpt = Read-Host "`nSelect tool(s) to install (e.g., 123) or Q"
        if ($toolOpt -match '(?i)^q$') { return }
        
        Write-Title "INSTALLATION SCOPE"
        Write-Host "1. App Portable (DevConsole\App)"
        Write-Host "2. Common Portable (CommonFiles)"
        Write-Host "3. Use Current Installation (Create launchers only)"
        Write-Host "Q. Cancel"
        
        $scopeOpt = Read-Host "`nSelect scope (1-3) or Q"
        if ($scopeOpt -match '(?i)^q$') { continue }
        
        $scope = if ($scopeOpt -eq '1') { 'App' } elseif ($scopeOpt -eq '2') { 'Common' } elseif ($scopeOpt -eq '3') { 'System' } else { $null }
        if (-not $scope) { Write-Host "Invalid scope." -ForegroundColor Red; Start-Sleep 1; continue }
        
        Get-LatestVersions
        
        if ($toolOpt -match '1' -or $toolOpt -match '6') { Install-Tool -Tool 'Git' -Scope $scope }
        if ($toolOpt -match '2' -or $toolOpt -match '6') { Install-Tool -Tool 'Node' -Scope $scope }
        if ($toolOpt -match '3' -or $toolOpt -match '6') { Install-Tool -Tool 'UV' -Scope $scope }
        if ($toolOpt -match '4' -or $toolOpt -match '6') { Install-Tool -Tool 'PHP' -Scope $scope }
        if ($toolOpt -match '5' -or $toolOpt -match '6') { Install-Tool -Tool 'Antigravity' -Scope $scope }
        
        Write-Host "`nPress Enter to return to the Install Menu..."
        pause > $null
    }
}

function Menu-Update {
    while ($true) {
        Write-Title "UPDATE TOOLS"
        Get-LatestVersions
        
        $tools = @('Git', 'Node', 'UV', 'PHP', 'Antigravity')
        $folderMap = @{ 'Git'='Git'; 'Node'='NodeJS'; 'UV'='uv'; 'PHP'='PHP'; 'Antigravity'='Antigravity' }
        $scopes = @{ 'App' = $AppDir; 'Common' = $CommonFilesDir }
        
        $pendingUpdates = @()
        
        foreach ($tool in $tools) {
            foreach ($scope in $scopes.GetEnumerator()) {
                $folderName = $folderMap[$tool]
                $Path = "$($scope.Value)\$folderName"
                
                $localVer = Get-LocalVersion -Tool $tool -Path $Path -Type $scope.Name
                
                if ($localVer) {
                    $remoteVer = Get-CleanVersion $global:Latest.$tool
                    Write-Host "Found $tool ($($scope.Name)) - Local: $localVer | Latest: $remoteVer"
                    
                    if ($remoteVer -gt $localVer) {
                        $pendingUpdates += [PSCustomObject]@{ Tool=$tool; Scope=$scope.Name }
                    }
                }
            }
        }
        
        if ($pendingUpdates.Count -gt 0) {
            Write-Host "`nUpdates are available!" -ForegroundColor Yellow
            $ans = Read-Host "Do you want to update all available tools now? (Y/N/Q)"
            
            if ($ans -match '(?i)^y$') {
                foreach ($upd in $pendingUpdates) {
                    Install-Tool -Tool $upd.Tool -Scope $upd.Scope
                }
                Write-Host "`nAll updates finished successfully." -ForegroundColor Green
            } elseif ($ans -match '(?i)^q$') {
                return
            }
        } else {
            Write-Host "`nNo updates required for installed portable tools." -ForegroundColor Green
        }
        
        Write-Host "`nQ. Back to Main Menu"
        $opt = Read-Host "Press Q to go back"
        if ($opt -match '(?i)^q$') { return }
    }
}

function Menu-Uninstall {
    while ($true) {
        Write-Title "UNINSTALL TOOLS"
        Write-Host "Searching for installed portable tools..."
        
        $found = @()
        $folders = @('Git', 'NodeJS', 'uv', 'PHP', 'Antigravity')
        
        foreach ($f in $folders) {
            if (Test-Path "$AppDir\$f") { $found += [PSCustomObject]@{ Tool=$f; Scope='App'; Path="$AppDir\$f" } }
            if (Test-Path "$CommonFilesDir\$f") { $found += [PSCustomObject]@{ Tool=$f; Scope='Common'; Path="$CommonFilesDir\$f" } }
        }
        
        if ($found.Count -eq 0) {
            Write-Host "No portable tools found to uninstall." -ForegroundColor Yellow
            Write-Host "`nNote: Launchers linking to your System installation are not deleted automatically."
            Write-Host "`nPress Enter to return..."
            pause > $null
            return
        }
        
        for ($i=0; $i -lt $found.Count; $i++) {
            Write-Host "$($i+1). $($found[$i].Tool) ($($found[$i].Scope) Portable)"
        }
        Write-Host "Q. Back to Main Menu"
        
        $opt = Read-Host "`nSelect a number to uninstall or Q"
        if ($opt -match '(?i)^q$') { return }
        
        if ($opt -match '\d') {
            $idx = [int]$opt - 1
            if ($idx -ge 0 -and $idx -lt $found.Count) {
                $item = $found[$idx]
                Write-Host "Uninstalling $($item.Tool) from $($item.Scope)..." -ForegroundColor Yellow
                Remove-Item -Recurse -Force $item.Path
                Write-Host "Uninstalled successfully." -ForegroundColor Green
                Start-Sleep 2
            }
        }
    }
}

# --- START ---
while ($true) {
    Write-Title "DEV CONSOLE MANAGER"
    Write-Host "1. Install / Setup Tools"
    Write-Host "2. Update Portable Tools"
    Write-Host "3. Uninstall Portable Tools"
    Write-Host "Q. Quit"
    $mainOpt = Read-Host "`nChoose an option"

    switch -regex ($mainOpt) {
        '^1$' { Menu-Install }
        '^2$' { Menu-Update }
        '^3$' { Menu-Uninstall }
        '(?i)^q$' { exit }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
}