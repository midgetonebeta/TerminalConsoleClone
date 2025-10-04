<#
.SYNOPSIS
 Automated PowerShell environment setup

.DESCRIPTION
 Installs PowerShell 7 (if missing), fonts, modules, Oh My Posh theme,
 and Windows Terminal settings.
#>

# Ensure script is run as admin (auto-elevate)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Restarting script as administrator..."
    Start-Process pwsh "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# -----------------------------
# 1. Install PowerShell 7 if missing
# -----------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Installing PowerShell 7..."
    winget install --id Microsoft.Powershell --source winget -e
}

# -----------------------------
# 2. Install Fonts
# -----------------------------
$fontSource = Join-Path $PSScriptRoot "Font"
$fonts = @(
    "CaskaydiaCoveNerdFont-Bold.ttf",
    "CaskaydiaCoveNerdFont-BoldItalic.ttf",
    "CaskaydiaCoveNerdFont-ExtraLight.ttf",
    "CaskaydiaCoveNerdFont-ExtraLightItalic.ttf",
    "CaskaydiaCoveNerdFont-Italic.ttf",
    "CaskaydiaCoveNerdFont-Light.ttf",
    "CaskaydiaCoveNerdFont-LightItalic.ttf",
    "CaskaydiaCoveNerdFont-Regular.ttf",
    "CaskaydiaCoveNerdFont-SemiBold.ttf",
    "CaskaydiaCoveNerdFont-SemiBoldItalic.ttf",
    "CaskaydiaCoveNerdFont-SemiLight.ttf",
    "CaskaydiaCoveNerdFont-SemiLightItalic.ttf",
    "CaskaydiaCoveNerdFontMono-Bold.ttf",
    "CaskaydiaCoveNerdFontMono-BoldItalic.ttf",
    "CaskaydiaCoveNerdFontMono-ExtraLight.ttf",
    "CaskaydiaCoveNerdFontMono-ExtraLightItalic.ttf",
    "CaskaydiaCoveNerdFontMono-Italic.ttf",
    "CaskaydiaCoveNerdFontMono-Light.ttf",
    "CaskaydiaCoveNerdFontMono-LightItalic.ttf",
    "CaskaydiaCoveNerdFontMono-Regular.ttf",
    "CaskaydiaCoveNerdFontMono-SemiBold.ttf",
    "CaskaydiaCoveNerdFontMono-SemiBoldItalic.ttf",
    "CaskaydiaCoveNerdFontMono-SemiLight.ttf",
    "CaskaydiaCoveNerdFontMono-SemiLightItalic.ttf",
    "CaskaydiaCoveNerdFontPropo-Bold.ttf",
    "CaskaydiaCoveNerdFontPropo-BoldItalic.ttf",
    "CaskaydiaCoveNerdFontPropo-ExtraLight.ttf",
    "CaskaydiaCoveNerdFontPropo-ExtraLightItalic.ttf",
    "CaskaydiaCoveNerdFontPropo-Italic.ttf",
    "CaskaydiaCoveNerdFontPropo-Light.ttf",
    "CaskaydiaCoveNerdFontPropo-LightItalic.ttf",
    "CaskaydiaCoveNerdFontPropo-Regular.ttf",
    "CaskaydiaCoveNerdFontPropo-SemiBold.ttf",
    "CaskaydiaCoveNerdFontPropo-SemiBoldItalic.ttf",
    "CaskaydiaCoveNerdFontPropo-SemiLight.ttf",
    "CaskaydiaCoveNerdFontPropo-SemiLightItalic.ttf",
    "ARCADE_I.TTF"   # <-- Added Arcade Interlaced font
)

Write-Host "Installing Fonts..."
foreach ($font in $fonts) {
    $fontPath = Join-Path $fontSource $font
    if (Test-Path $fontPath) {
        Write-Host "Installing $font..."
        Copy-Item $fontPath -Destination "C:\Windows\Fonts" -Force
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font)
        New-ItemProperty -Path $regPath -Name $fontName -Value $font -PropertyType String -Force | Out-Null
    } else {
        Write-Warning "Font not found: $font"
    }
}

# -----------------------------
# 3. Copy PowerShell Profile + Theme
# -----------------------------
$profileDest = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDest)) { New-Item -ItemType Directory -Path $profileDest -Force }

Copy-Item -Force (Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1") $PROFILE
Copy-Item -Force (Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json") "$profileDest\midgetsrampage.omp.json"

# -----------------------------
# 4. Copy Terminal Settings
# -----------------------------
$terminalSettingsSrc = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalSettingsDest = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $terminalSettingsSrc) {
    Copy-Item -Force $terminalSettingsSrc $terminalSettingsDest
    Write-Host "Windows Terminal settings applied."
}

# -----------------------------
# 5. Install PowerShell Modules
# -----------------------------
$modules = @("Terminal-Icons","z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
        }
    } catch {
        Write-Warning "Failed to install $moduleName : $($_.Exception.Message)"
    }
}

Write-Host "`nSetup complete! Restart your terminal to apply changes." -ForegroundColor Green
