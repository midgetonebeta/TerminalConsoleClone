# ================================
# TerminalConsoleClone Setup Script
# ================================

# Auto-elevate to Admin if not already
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..." -ForegroundColor Yellow
    Start-Process pwsh "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== TerminalConsoleClone Setup Starting ===" -ForegroundColor Cyan

# -------------------------------
# Install Chocolatey if missing
# -------------------------------
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor Green
}

# -------------------------------
# Install core tools
# -------------------------------
$tools = @("git", "neovim", "python", "nodejs", "yarn", "7zip")
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $tool..." -ForegroundColor Yellow
        choco install $tool -y
    } else {
        Write-Host "$tool already installed." -ForegroundColor Green
    }
}

# -------------------------------
# Install PowerShell Modules
# -------------------------------
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-Host "Installing $moduleName module..." -ForegroundColor Yellow
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
        } else {
            Write-Host "$moduleName module already installed." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to install $moduleName: $($_.Exception.Message)"
    }
}

# -------------------------------
# Install Fonts
# -------------------------------
$fontsPath = Join-Path $PSScriptRoot "Font"
if (Test-Path $fontsPath) {
    Write-Host "Installing fonts from $fontsPath..." -ForegroundColor Cyan
    Get-ChildItem -Path $fontsPath -Filter *.ttf | ForEach-Object {
        Write-Host "Installing font: $($_.Name)" -ForegroundColor Yellow
        Copy-Item $_.FullName -Destination "$env:SystemRoot\Fonts" -Force
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "$($_.BaseName) (TrueType)" /t REG_SZ /d $_.Name /f | Out-Null
    }
} else {
    Write-Warning "Font folder not found. Skipping font install."
}

# -------------------------------
# Copy Oh My Posh theme + profile
# -------------------------------
Write-Host "`n=== Setting up PowerShell Profile ===" -ForegroundColor Cyan

# Backup existing profile if it exists
if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak"
    Write-Host "Backing up existing profile to $backup" -ForegroundColor Yellow
    Move-Item -Force $PROFILE $backup
}

# Ensure profile directory exists
$profileDir = Split-Path -Parent $PROFILE
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

# Create a fresh profile file
New-Item -ItemType File -Force -Path $PROFILE | Out-Null

# Copy template profile content
$templateProfile = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
if (Test-Path $templateProfile) {
    $profileContent = Get-Content $templateProfile -Raw

    # Rewrite paths dynamically
    $docsPath = [Environment]::GetFolderPath("MyDocuments")
    $poshConfigPath = Join-Path $docsPath "PowerShell\midgetsrampage.omp.json"
    $terminalPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\wt.exe"

    $profileContent = $profileContent -replace 'C:\\Users\\.*?\\Documents\\PowerShell\\midgetsrampage.omp.json', [Regex]::Escape($poshConfigPath)
    $profileContent = $profileContent -replace 'C:\\Users\\.*?\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.WindowsTerminal.*?\\wt.exe', [Regex]::Escape($terminalPath)

    # Write updated content into new profile
    $profileContent | Set-Content -Path $PROFILE -Encoding UTF8

    Write-Host "New profile created at $PROFILE" -ForegroundColor Green
} else {
    Write-Warning "Template profile not found at $templateProfile"
}

# Copy theme JSON
$themeSource = Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json"
$themeDest = Join-Path $docsPath "PowerShell\midgetsrampage.omp.json"
Copy-Item -Force $themeSource $themeDest

# -------------------------------
# Copy Terminal Settings
# -------------------------------
$terminalSettings = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalDest = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSettings) {
    Write-Host "Copying terminal settings..." -ForegroundColor Cyan
    Copy-Item -Force $terminalSettings $terminalDest
} else {
    Write-Warning "No terminal settings found."
}

Write-Host "`n=== Setup Complete! Restart PowerShell ===" -ForegroundColor Green
