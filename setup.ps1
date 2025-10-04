# ========================
# setup.ps1
# Automated PowerShell Environment Setup
# ========================

Write-Host "🚀 Starting environment setup..." -ForegroundColor Cyan

# ------------------------
# Install Chocolatey (if missing)
# ------------------------
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor Green
}

# ------------------------
# Install core tools
# ------------------------
$packages = "git", "neovim", "python", "nodejs", "yarn", "7zip"
foreach ($pkg in $packages) {
    if (-not (choco list --local-only | Select-String $pkg)) {
        Write-Host "Installing $pkg..." -ForegroundColor Yellow
        choco install $pkg -y
    } else {
        Write-Host "$pkg already installed." -ForegroundColor Green
    }
}

# ------------------------
# Install PowerShell modules
# ------------------------
$modules = "Terminal-Icons", "z"
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Installing module $mod..." -ForegroundColor Yellow
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    } else {
        Write-Host "Module $mod already installed." -ForegroundColor Green
    }
}

# ------------------------
# Install Fonts
# ------------------------
$fontPath = Join-Path $PSScriptRoot "Font"
if (Test-Path $fontPath) {
    Write-Host "Installing fonts from $fontPath..." -ForegroundColor Yellow
    $fonts = Get-ChildItem -Path $fontPath -Filter *.ttf
    foreach ($font in $fonts) {
        $target = Join-Path $env:WINDIR "Fonts\$($font.Name)"
        if (-not (Test-Path $target)) {
            Copy-Item $font.FullName -Destination $target
            Write-Host "Installed $($font.Name)" -ForegroundColor Green
        } else {
            Write-Host "$($font.Name) already installed." -ForegroundColor Gray
        }
    }
}

# ------------------------
# Copy PowerShell profile + theme
# ------------------------
$profileSource = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$themeSource   = Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json"
$profileTarget = $PROFILE
$themeTarget   = Join-Path (Split-Path $PROFILE) "midgetsrampage.omp.json"

Write-Host "Copying PowerShell profile..." -ForegroundColor Yellow
Copy-Item -Force $profileSource $profileTarget
Write-Host "Copying Oh My Posh theme..." -ForegroundColor Yellow
Copy-Item -Force $themeSource $themeTarget

# ------------------------
# Copy Windows Terminal settings
# ------------------------
$terminalSettingsSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalSettingsTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $terminalSettingsSource) {
    Write-Host "Copying Windows Terminal settings..." -ForegroundColor Yellow
    Copy-Item -Force $terminalSettingsSource $terminalSettingsTarget
    Write-Host "Windows Terminal settings updated." -ForegroundColor Green
} else {
    Write-Host "No Terminal settings found in repo." -ForegroundColor Red
}

# ------------------------
# Done
# ------------------------
Write-Host "✅ Setup complete! Restart your terminal to apply changes." -ForegroundColor Cyan
