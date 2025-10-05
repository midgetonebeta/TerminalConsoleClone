# ============================
# TerminalConsoleClone Setup
# ============================

# Force execution policy bypass so unsigned scripts can run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Write-Host "=== TerminalConsoleClone Setup ===" -ForegroundColor Cyan

# Detect user Documents path (works with or without OneDrive)
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$psProfileDir  = Join-Path $documentsPath "PowerShell"

if (-not (Test-Path $psProfileDir)) {
    New-Item -ItemType Directory -Path $psProfileDir -Force | Out-Null
}

# ----------------------------
# Copy profile + theme
# ----------------------------
$profileSource = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$profileDest   = Join-Path $psProfileDir "Microsoft.PowerShell_profile.ps1.bak"   # we save as .bak first
$themeSource   = Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json"
$themeDest     = Join-Path $psProfileDir "midgetsrampage.omp.json"

Copy-Item $profileSource $profileDest -Force
Copy-Item $themeSource   $themeDest   -Force

# ----------------------------
# Fix paths inside profile
# ----------------------------
$profileContent = Get-Content $profileSource -Raw

# Insert correct theme path
$profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\(OneDrive\\)?Documents\\PowerShell\\midgetsrampage.omp.json',
    $themeDest

# Find Windows Terminal path
$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
if ($wtPath) {
    $profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\AppData\\Local\\Microsoft\\WindowsApps(\\[^\\]+)?\\wt.exe',
        $wtPath
}

# Write new profile
$profileFinal = Join-Path $psProfileDir "Microsoft.PowerShell_profile.ps1"
$profileContent | Set-Content -Path $profileFinal -Encoding UTF8

Write-Host "✔ PowerShell profile installed to $profileFinal" -ForegroundColor Green

# ----------------------------
# Copy config.json (optional)
# ----------------------------
$configSource = Join-Path $PSScriptRoot "Profile_Data\powershell.config.json"
$configDest   = Join-Path $psProfileDir "powershell.config.json"
Copy-Item $configSource $configDest -Force

# ----------------------------
# Fonts install
# ----------------------------
$fontDir = Join-Path $PSScriptRoot "Font"
$windowsFontDir = "$env:WINDIR\Fonts"

Write-Host "Installing fonts..." -ForegroundColor Cyan
Get-ChildItem -Path $fontDir -Filter *.ttf | ForEach-Object {
    $target = Join-Path $windowsFontDir $_.Name
    if (-not (Test-Path $target)) {
        Copy-Item $_.FullName $target
        Write-Host "✔ Installed font: $($_.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "Skipped font (already installed): $($_.Name)" -ForegroundColor Yellow
    }
}

# ----------------------------
# Terminal settings
# ----------------------------
$terminalSettingsDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$settingsSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$settingsDest   = Join-Path $terminalSettingsDir "settings.json"

if (Test-Path $terminalSettingsDir) {
    Copy-Item $settingsSource $settingsDest -Force
    Write-Host "✔ Windows Terminal settings applied." -ForegroundColor Green
}
else {
    Write-Warning "Windows Terminal not found. Skipping terminal settings."
}

# ----------------------------
# Install modules
# ----------------------------
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
            Write-Host "✔ Installed module: $moduleName" -ForegroundColor Green
        }
        else {
            Write-Host "Skipped module (already installed): $moduleName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning ("Failed to install module {0}: {1}" -f $moduleName, $_.Exception.Message)
    }
}

Write-Host "`n=== Setup Complete! Restart PowerShell to apply changes. ===" -ForegroundColor Cyan
