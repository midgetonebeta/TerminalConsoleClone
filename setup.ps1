# ===============================
# setup.ps1 - TerminalConsoleClone
# ===============================
# Auto-elevate if not running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..." -ForegroundColor Yellow
    Start-Process pwsh "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Make sure script runs even with restrictive execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# -------------------------------
# Helper: Install Chocolatey
# -------------------------------
function Install-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey already installed." -ForegroundColor Green
    }
}

# -------------------------------
# Helper: Install Choco Packages
# -------------------------------
function Install-ChocoPackage($package) {
    if (-not (choco list --local-only | Select-String $package)) {
        Write-Host "Installing $package..." -ForegroundColor Cyan
        choco install $package -y --no-progress
    } else {
        Write-Host "$package already installed." -ForegroundColor Green
    }
}

# -------------------------------
# Step 1: Install Chocolatey
# -------------------------------
Install-Choco

# -------------------------------
# Step 2: Core Tools
# -------------------------------
$packages = @("git", "neovim", "nodejs", "python", "7zip", "oh-my-posh")
foreach ($pkg in $packages) { Install-ChocoPackage $pkg }

# -------------------------------
# Step 3: Install Fonts
# -------------------------------
$fontPath = Join-Path $PSScriptRoot "Font"
$fonts = Get-ChildItem -Path $fontPath -Filter *.ttf
foreach ($font in $fonts) {
    Write-Host "Installing font: $($font.Name)" -ForegroundColor Cyan
    Copy-Item $font.FullName -Destination "$env:WINDIR\Fonts" -Force
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "$($font.BaseName) (TrueType)" /t REG_SZ /d $font.Name /f | Out-Null
}

# -------------------------------
# Step 4: Install PowerShell Modules
# -------------------------------
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-Host "Installing PowerShell module: $moduleName" -ForegroundColor Cyan
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        } else {
            Write-Host "Module already installed: $moduleName" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to install ${moduleName}: $($_.Exception.Message)"
    }
}

# -------------------------------
# Step 5: Setup PowerShell Profile
# -------------------------------
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) { New-Item -Path $profileDir -ItemType Directory -Force }

# Rename any existing profile
if (Test-Path $PROFILE) {
    Rename-Item -Path $PROFILE -NewName "Microsoft.PowerShell_profile.ps1.bak" -Force
}

# Create new blank profile file
New-Item -Path $PROFILE -ItemType File -Force | Out-Null

# Copy in our custom profile
$sourceProfile = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$profileContent = Get-Content $sourceProfile -Raw

# Auto-replace user paths
$userProfile = $env:USERPROFILE
$oneDriveDoc = Join-Path $userProfile "OneDrive\Documents\PowerShell"
$plainDoc   = Join-Path $userProfile "Documents\PowerShell"

# Pick whichever exists, fallback to OneDrive
if (Test-Path $oneDriveDoc) {
    $docPath = $oneDriveDoc
} else {
    $docPath = $plainDoc
}

# Update profile contents dynamically
$profileContent = $profileContent -replace 'C:\\Users.*?\\Documents\\PowerShell', [Regex]::Escape($docPath)
$wtPath = (Get-Command wt.exe -ErrorAction SilentlyContinue).Source
if ($wtPath) {
    $profileContent = $profileContent -replace 'C:\\Users.*?WindowsTerminal.*?\\wt.exe', [Regex]::Escape($wtPath)
}

# Write fixed profile
Set-Content -Path $PROFILE -Value $profileContent -Force -Encoding UTF8

# -------------------------------
# Step 6: Terminal Settings
# -------------------------------
$terminalSettingsSrc = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalSettingsDst = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSettingsSrc) {
    Copy-Item $terminalSettingsSrc -Destination $terminalSettingsDst -Force
    Write-Host "Applied Windows Terminal settings." -ForegroundColor Green
}

Write-Host "`nSetup completed successfully! Restart your terminal to see changes." -ForegroundColor Magenta
