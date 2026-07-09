# ==========================================
# DEV CONSOLE PORTABLE - MANAGER SCRIPT
# ==========================================
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- 1. PATH SETUP ---
$BaseDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$AppDir = Join-Path $BaseDir 'App'
$CommonFilesDir = [System.IO.Path]::GetFullPath((Join-Path $BaseDir '..\CommonFiles'))

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

        # OpenChamber Desktop (UI principal)
        $ocRelease = Invoke-RestMethod 'https://api.github.com/repos/openchamber/openchamber/releases/latest'
        $global:Latest.OpenChamber = $ocRelease.tag_name -replace '^v', ''
        $global:Latest.OpenChamberUrl = (
            $ocRelease.assets |
            Where-Object { $_.name -match '^OpenChamber-.*-win-x64\.exe$' } |
            Select-Object -First 1 -ExpandProperty browser_download_url
        )
        Write-ManagerLog "Latest OpenChamber release: $($global:Latest.OpenChamber)"
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
            if ($Tool -eq 'OpenChamber') {
                $out = winget list --id OpenChamber.OpenChamber --accept-source-agreements 2>$null
                if ($out -match '([\d\.]+)') { $ver = $matches[1] }
            }
        } else {
            if ($Tool -eq 'Node' -and (Test-Path "$Path\node.exe")) { $ver = (& "$Path\node.exe" -v) }
            if ($Tool -eq 'UV' -and (Test-Path "$Path\uv.exe")) { $ver = (& "$Path\uv.exe" --version) }
            if ($Tool -eq 'Git' -and (Test-Path "$Path\cmd\git.exe")) { $ver = (& "$Path\cmd\git.exe" --version) }
            if ($Tool -eq 'PHP' -and (Test-Path "$Path\php.exe")) { $ver = (& "$Path\php.exe" -v) }
            if ($Tool -eq 'OpenChamber' -and (Test-Path "$Path\OpenChamber.exe")) {
                $ver = (Get-Item "$Path\OpenChamber.exe").VersionInfo.ProductVersion
            }
        }
    } catch {}
    return Get-CleanVersion $ver
}

# --- 4. EXTRACTOR HELPER FOR WINGET APPS ---
function Extract-WingetAppPortable {
    param([string]$AppId, [string]$TargetDir, [string]$TempName)

    $dataBackup = "$TargetDir\_Data_Backup"
    if (Test-Path "$TargetDir\data") {
        Write-Host "Backing up portable data settings..." -ForegroundColor DarkGray
        Move-Item -Path "$TargetDir\data" -Destination $dataBackup -Force
    }
    
    if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    
    $tempDownload = Join-Path $PSScriptRoot $TempName
    if (Test-Path $tempDownload) { Remove-Item -Recurse -Force $tempDownload }
    New-Item -ItemType Directory -Path $tempDownload -Force | Out-Null
    
    $7zExe = Get-7ZipExecutable -TempDownload $tempDownload
    Write-ManagerLog "Extractor for ${AppId}: $7zExe"
    
    Write-Host "Downloading $AppId via winget..." -ForegroundColor Yellow
    Write-ManagerLog "Running winget download for $AppId into $tempDownload"
    & winget download --id $AppId --exact --accept-package-agreements --accept-source-agreements --download-directory $tempDownload | Out-Null
    
    $installer = Get-PrimaryInstallerFromFolder -Folder $tempDownload
    
    if ($installer) {
        Write-Host "Extracting installer: $($installer.Name)..." -ForegroundColor Yellow
        Write-ManagerLog "Selected installer for ${AppId}: $($installer.Name) ($($installer.Length) bytes)"
        Extract-InstallerFile -InstallerPath $installer.FullName -TargetDir $TargetDir -SevenZipExe $7zExe
        Write-Host "Extraction completed successfully." -ForegroundColor Green
        Write-ManagerLog "Extraction completed for $AppId into $TargetDir"
    } else {
        Write-Host "Error: Could not download or locate the installer file." -ForegroundColor Red
        Write-ManagerLog "ERROR: No installer candidate found in $tempDownload for $AppId"
    }
    
    if (Test-Path $tempDownload) { Remove-Item -Recurse -Force $tempDownload }
    if (Test-Path $dataBackup) {
        Move-Item -Path $dataBackup -Destination "$TargetDir\data" -Force
    } else {
        New-Item -ItemType Directory -Path "$TargetDir\data" -Force | Out-Null
    }
}

# --- 5. INSTALLERS ---
function Install-Tool {
    param([string]$Tool, [string]$Scope)
    
    if ($Scope -eq 'System') { Write-Host "Configuring launcher for current System installation of $Tool..." -ForegroundColor Cyan } 
    else { Write-Host "Installing/Updating $Tool ($Scope Portable)..." -ForegroundColor Cyan }

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
        'OpenChamber' {
            if ($Scope -ne 'System') {
                if (-not $global:Latest.OpenChamberUrl) { throw "OpenChamber download URL not found." }
                Extract-UrlAppPortable -DownloadUrl $global:Latest.OpenChamberUrl -TargetDir "$target\OpenChamber" -TempName "temp_openchamber"
            }
            Crear-Lanzador -NuevoNombre 'OpenChamber.exe'
            Crear-Lanzador -NuevoNombre 'OpencodeCLI.exe'
            $legacyDesktopLauncher = Join-Path $BaseDir 'OpencodeDesktop.exe'
            if (Test-Path $legacyDesktopLauncher) {
                Remove-Item -Path $legacyDesktopLauncher -Force
                Write-ManagerLog "Removed legacy launcher: OpencodeDesktop.exe"
            }
        }
    }
    Write-Host "$Tool setup/update completed successfully." -ForegroundColor Green
}

# --- 6. MAIN LOGIC (MENUS) ---
function Menu-Install {
    while ($true) {
        Write-Title "INSTALL TOOLS"
        Write-Host "1. Git"
        Write-Host "2. Node (LTS)"
        Write-Host "3. uv (Python)"
        Write-Host "4. PHP"
        Write-Host "5. OpenChamber Desktop (UI principal)"
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
        if ($toolOpt -match '5' -or $toolOpt -match '6') { Install-Tool -Tool 'OpenChamber' -Scope $scope }
        
        Write-Host "`nPress Enter to return to the Install Menu..."
        pause > $null
    }
}

function Menu-Update {
    while ($true) {
        Write-Title "UPDATE TOOLS"
        Get-LatestVersions
        
        $tools = @('Git', 'Node', 'UV', 'PHP', 'OpenChamber')
        $folderMap = @{ 'Git'='Git'; 'Node'='NodeJS'; 'UV'='uv'; 'PHP'='PHP'; 'OpenChamber'='OpenChamber' }
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
            if ($ans -match '(?i)^y$') { foreach ($upd in $pendingUpdates) { Install-Tool -Tool $upd.Tool -Scope $upd.Scope }; Write-Host "`nAll updates finished successfully." -ForegroundColor Green } elseif ($ans -match '(?i)^q$') { return }
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
        $folders = @('Git', 'NodeJS', 'uv', 'PHP', 'OpenChamber')
        
        foreach ($f in $folders) {
            if (Test-Path "$AppDir\$f") { $found += [PSCustomObject]@{ Tool=$f; Scope='App'; Path="$AppDir\$f" } }
            if (Test-Path "$CommonFilesDir\$f") { $found += [PSCustomObject]@{ Tool=$f; Scope='Common'; Path="$CommonFilesDir\$f" } }
        }
        
        if ($found.Count -eq 0) { Write-Host "No portable tools found to uninstall."; pause > $null; return }
        
        for ($i=0; $i -lt $found.Count; $i++) { Write-Host "$($i+1). $($found[$i].Tool) ($($found[$i].Scope) Portable)" }
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

function Get-7ZipExecutable {
    param([string]$TempDownload)

    $7zExe = $null
    $persistent7zDir = Join-Path $BaseDir 'Data\home\.7-zip'
    $persistent7zExe = Join-Path $persistent7zDir '7z.exe'

    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        return '7z'
    }

    if (Test-Path $persistent7zExe) {
        return $persistent7zExe
    }

    $portable7Zip = Join-Path $BaseDir '..\7-ZipPortable\App\7-Zip64\7z.exe'
    $portable7Zip32 = Join-Path $BaseDir '..\7-ZipPortable\App\7-Zip\7z.exe'
    if (Test-Path $portable7Zip) { return $portable7Zip }
    if (Test-Path $portable7Zip32) { return $portable7Zip32 }
    if (Test-Path 'C:\Program Files\7-Zip\7z.exe') { return 'C:\Program Files\7-Zip\7z.exe' }
    if (Test-Path 'C:\Program Files (x86)\7-Zip\7z.exe') { return 'C:\Program Files (x86)\7-Zip\7z.exe' }

    Write-Host 'Downloading and preparing latest 7-Zip extractor (v24.07)...' -ForegroundColor Yellow
    $7zMsi = Join-Path $TempDownload '7z_latest.msi'
    $7zExtractDir = Join-Path $TempDownload '7z_extracted'
    try {
        Invoke-WebRequest -Uri 'https://www.7-zip.org/a/7z2407-x64.msi' -OutFile $7zMsi -UseBasicParsing
        Start-Process msiexec -ArgumentList "/a `"$7zMsi`" /qb TARGETDIR=`"$7zExtractDir`"" -Wait -NoNewWindow
        $extractedExe = Get-ChildItem $7zExtractDir -Filter '7z.exe' -Recurse | Select-Object -ExpandProperty FullName -First 1
        if ($extractedExe) {
            $extractedDir = Split-Path $extractedExe
            New-Item -ItemType Directory -Path $persistent7zDir -Force | Out-Null
            Get-ChildItem "$extractedDir\*" | Copy-Item -Destination $persistent7zDir -Force
            Write-ManagerLog "Prepared persistent 7-Zip in $persistent7zDir"
            return $persistent7zExe
        }
    } catch {
        Write-Host 'Warning: Failed to download latest 7-Zip.' -ForegroundColor Red
        Write-ManagerLog "Failed preparing 7-Zip MSI extractor: $($_.Exception.Message)"
    }

    $7zZip = Join-Path $TempDownload '7za.zip'
    Invoke-WebRequest -Uri 'https://www.7-zip.org/a/7za920.zip' -OutFile $7zZip -UseBasicParsing
    Expand-Archive -Path $7zZip -DestinationPath $TempDownload -Force
    Write-ManagerLog 'Using fallback 7za.exe extractor'
    return (Join-Path $TempDownload '7za.exe')
}

function Extract-UrlAppPortable {
    param([string]$DownloadUrl, [string]$TargetDir, [string]$TempName)

    $dataBackup = "$TargetDir\_Data_Backup"
    if (Test-Path "$TargetDir\data") {
        Write-Host "Backing up portable data settings..." -ForegroundColor DarkGray
        Move-Item -Path "$TargetDir\data" -Destination $dataBackup -Force
    }

    if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }

    $tempDownload = Join-Path $PSScriptRoot $TempName
    if (Test-Path $tempDownload) { Remove-Item -Recurse -Force $tempDownload }
    New-Item -ItemType Directory -Path $tempDownload -Force | Out-Null

    $7zExe = Get-7ZipExecutable -TempDownload $tempDownload
    $installerPath = Join-Path $tempDownload (Split-Path $DownloadUrl -Leaf)
    Write-ManagerLog "Downloading URL installer to $installerPath"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $installerPath -UseBasicParsing

    Write-Host "Extracting installer: $(Split-Path $installerPath -Leaf)..." -ForegroundColor Yellow
    Extract-InstallerFile -InstallerPath $installerPath -TargetDir $TargetDir -SevenZipExe $7zExe
    Write-Host "Extraction completed successfully." -ForegroundColor Green
    Write-ManagerLog "Extraction completed for URL installer into $TargetDir"

    if (Test-Path $tempDownload) { Remove-Item -Recurse -Force $tempDownload }
    if (Test-Path $dataBackup) {
        Move-Item -Path $dataBackup -Destination "$TargetDir\data" -Force
    } else {
        New-Item -ItemType Directory -Path "$TargetDir\data" -Force | Out-Null
    }
}

function Get-PrimaryInstallerFromFolder {
    param([string]$Folder)

    $candidates = Get-ChildItem $Folder -File | Where-Object {
        $_.Extension -in '.exe', '.msi', '.zip' -and
        $_.Name -notmatch '(?i)^7z_latest\.msi$|^7za\.zip$|^7za\.exe$|\.blockmap$|^latest.*\.yml$|license|readme'
    }

    if (-not $candidates) { return $null }

    return $candidates |
        Sort-Object @{Expression='Length';Descending=$true}, @{Expression='Name';Descending=$false} |
        Select-Object -First 1
}

function Extract-InstallerFile {
    param(
        [string]$InstallerPath,
        [string]$TargetDir,
        [string]$SevenZipExe
    )

    $installer = Get-Item -LiteralPath $InstallerPath
    if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }

    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

    if ($installer.Extension -eq '.msi') {
        Start-Process msiexec -ArgumentList "/a `"$($installer.FullName)`" /qb TARGETDIR=`"$TargetDir`"" -Wait -NoNewWindow
    } elseif ($installer.Extension -eq '.zip') {
        Expand-Archive -Path $installer.FullName -DestinationPath $TargetDir -Force
    } else {
        Start-Process $SevenZipExe -ArgumentList "x `"$($installer.FullName)`" -o`"$TargetDir`" -y" -Wait -NoNewWindow | Out-Null
        Start-Sleep -Seconds 2

        $nestedArchive = Get-ChildItem -Path $TargetDir -Filter '*.7z' -Recurse | Select-Object -First 1
        if ($nestedArchive) {
            Start-Process $SevenZipExe -ArgumentList "x `"$($nestedArchive.FullName)`" -o`"$TargetDir`" -y" -Wait -NoNewWindow | Out-Null
            Start-Sleep -Seconds 2
            Remove-Item -Path $nestedArchive.FullName -Force
        }
    }

    if (Test-Path "$TargetDir\`$INSTDIR") { Get-ChildItem -Path "$TargetDir\`$INSTDIR\*" | Move-Item -Destination $TargetDir -Force; Remove-Item -Path "$TargetDir\`$INSTDIR" -Recurse -Force }
    if (Test-Path "$TargetDir\`$_OUTDIR") { Get-ChildItem -Path "$TargetDir\`$_OUTDIR\*" | Move-Item -Destination $TargetDir -Force; Remove-Item -Path "$TargetDir\`$_OUTDIR" -Recurse -Force }
    if (Test-Path "$TargetDir\{app}") { Get-ChildItem -Path "$TargetDir\{app}\*" | Move-Item -Destination $TargetDir -Force; Remove-Item -Path "$TargetDir\{app}" -Recurse -Force }
    if (Test-Path "$TargetDir\`$PLUGINSDIR") { Remove-Item -Path "$TargetDir\`$PLUGINSDIR" -Recurse -Force }
}

function Write-ManagerLog {
    param([string]$Message)
    return
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
