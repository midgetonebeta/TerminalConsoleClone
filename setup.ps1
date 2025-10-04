# ============================================================
# setup.ps1 - Automated Environment Setup
# ============================================================

# Ensure script runs even if system ExecutionPolicy blocks unsigned scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Write-Host "=== Starting Terminal Console Clone Setup ===" -ForegroundColor Cyan

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

function Write-Info($msg) {
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-Success($msg) {
    Write-Host "[SUCCESS] $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "[WARNING] $msg" -ForegroundColor Yellow
}

function Write-ErrorMsg($msg) {
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

# ------------------------------------------------------------
# Install PowerShell Module if Missing
# ------------------------------------------------------------

function Install-PowerShellModuleIfMissing($moduleName) {
    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        try {
            Write-Info "Installing PowerShell module: $moduleName..."
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
            Write-Success "$moduleName installed successfully."
        } catch {
            Write-Warn "Failed to install ${moduleName}: $_"
        }
    } else {
        Write-Info "Module $moduleName already installed."
    }
}

# ------------------------------------------------------------
# Step 1: Install Chocolatey (if missing)
# ------------------------------------------------------------

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Success "Chocolatey installed."
} else {
    Write-Info "Chocolatey already installed."
}

# ------------------------------------------------------------
# Step 2: Install Core Tools
# ------------------------------------------------------------

$packages = @("git", "neovim", "nodejs", "yarn", "7zip")
foreach ($pkg in $packages) {
    if (-not (choco list --local-only | Select-String $pkg)) {
        Write-Info "Installing $pkg..."
        choco install $pkg -y
        Write-Success "$pkg installed."
    } else {
        Write-Info "$pkg already installed."
    }
}

# ------------------------------------------------------------
# Step 3: Install Oh My Posh
# ------------------------------------------------------------

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Oh My Posh..."
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
    Write-Success "Oh My Posh installed."
} else {
    Write-Info "Oh My Posh already installed."
}

# ------------------------------------------------------------
# Step 4: Install Fonts
# ------------------------------------------------------------

$fontFolder = Join-Path $PSScriptRoot "Font"
$fonts = Get-ChildItem $fontFolder -Filter *.ttf

foreach ($font in $fonts) {
    $fontDest = Join-Path "$env:WINDIR\Fonts" $font.Name
    if (-not (Test-Path $fontDest)) {
        Write-Info "Installing font: $($font.Name)"
        Copy-Item $font.FullName $fontDest
        # Register font in registry
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        New-ItemProperty -Path $regPath -Name $font.BaseName -Value $font.Name -PropertyType String -Force | Out-Null
        Write-Success "Font $($font.Name) installed."
    } else {
        Write-Info "Font $($font.Name) already installed."
    }
}

# ------------------------------------------------------------
# Step 5: Copy PowerShell Profile + Theme
# ------------------------------------------------------------

$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir | Out-Null
}

Copy-Item -Force (Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1") $PROFILE
Copy-Item -Force (Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json") (Join-Path $profileDir "midgetsrampage.omp.json")

Write-Success "PowerShell profile and theme installed."

# ------------------------------------------------------------
# Step 6: Install PowerShell Modules
# ------------------------------------------------------------

Install-PowerShellModuleIfMissing -moduleName "Terminal-Icons"
Install-PowerShellModuleIfMissing -moduleName "z"

# ------------------------------------------------------------
# Step 7: Apply Terminal Settings
# ------------------------------------------------------------

$terminalSettingsSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalSettingsDest = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $terminalSettingsSource) {
    Write-Info "Applying Windows Terminal settings..."
    Copy-Item -Force $terminalSettingsSource $terminalSettingsDest
    Write-Success "Windows Terminal settings applied."
} else {
    Write-Warn "No TerminalSettings found to apply."
}

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------

Write-Host "`n=== Setup Completed! Restart PowerShell or Windows Terminal. ===" -ForegroundColor Green
