<# 
    setup.ps1 - Automated PowerShell Terminal Environment Setup
    Features:
    - Auto elevate to Administrator
    - Installs PowerShell 7 (if missing)
    - Installs Chocolatey (if missing)
    - Installs tools: git, neovim, python, nodejs, yarn, 7zip
    - Installs PowerShell modules: Terminal-Icons, z
    - Installs all fonts in Font/ (Cascadia + Arcade Interlaced, etc.)
    - Copies profile & theme from Profile_Data/
    - Copies Windows Terminal settings from TerminalSettings/
    - Auto-updates terminal font face (Arcade Interlaced > CascadiaCove Nerd Font)
    - Logs all actions to setup.log
#>

# --- Logging ---
$LogFile = Join-Path $PSScriptRoot "setup.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# --- Auto-Elevate ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Restarting script as Administrator..."
    Start-Process pwsh "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Log "=== Starting Environment Setup ==="

# --- Install PowerShell 7 (if missing) ---
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Log "Installing PowerShell 7..."
    winget install --id Microsoft.Powershell --source winget -e
} else {
    Write-Log "PowerShell 7 is already installed."
}

# --- Install Chocolatey (if missing) ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    Write-Log "Chocolatey already installed."
}

# --- Core Tools via Choco ---
$packages = @("git", "neovim", "python", "nodejs", "yarn", "7zip")
foreach ($pkg in $packages) {
    if (-not (choco list --localonly | Select-String $pkg)) {
        Write-Log "Installing $pkg..."
        choco install $pkg -y
    } else {
        Write-Log "$pkg already installed."
    }
}

# --- PowerShell Modules ---
$modules = @("Terminal-Icons", "z")
foreach ($module in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Log "Installing module $module..."
            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
        } else {
            Write-Log "Module $module already installed."
        }
    } catch {
        Write-Log "Failed to install module $module: $($_.Exception.Message)" "WARN"
    }
}

# --- Install Fonts ---
$FontSource = Join-Path $PSScriptRoot "Font"
$FontDest = "C:\Windows\Fonts"
$installedFonts = @()

if (Test-Path $FontSource) {
    Write-Log "Installing fonts from $FontSource ..."
    foreach ($fontFile in Get-ChildItem $FontSource -Filter *.ttf) {
        $fontName = $fontFile.Name
        $target = Join-Path $FontDest $fontFile.Name
        if (-not (Test-Path $target)) {
            Write-Log "Installing font: $fontName"
            Copy-Item $fontFile.FullName $FontDest
            $installedFonts += $fontFile.BaseName
        } else {
            Write-Log "Font already installed: $fontName"
        }
    }
} else {
    Write-Log "Font folder not found, skipping fonts." "WARN"
}

# --- Copy PowerShell Profile & Theme ---
$profileSource = Join-Path $PSScriptRoot "Profile_Data"
if (Test-Path $profileSource) {
    Copy-Item "$profileSource\Microsoft.PowerShell_profile.ps1" $PROFILE -Force
    Copy-Item "$profileSource\midgetsrampage.omp.json" (Split-Path $PROFILE) -Force
    Write-Log "Profile and theme copied."
} else {
    Write-Log "Profile_Data folder not found." "WARN"
}

# --- Copy Windows Terminal Settings ---
$termSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$termDest = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $termSource) {
    $settings = Get-Content $termSource -Raw

    # Choose Arcade Interlaced if available, else Cascadia
    if ($installedFonts -match "Arcade Interlaced") {
        $settings = $settings -replace '"fontFace":\s*".*?"', '"fontFace": "Arcade Interlaced"'
        Write-Log "Set terminal font to Arcade Interlaced."
    } else {
        $settings = $settings -replace '"fontFace":\s*".*?"', '"fontFace": "CaskaydiaCove Nerd Font"'
        Write-Log "Set terminal font to CaskaydiaCove Nerd Font."
    }

    $settings | Set-Content $termDest -Encoding UTF8
    Write-Log "Terminal settings copied and updated."
} else {
    Write-Log "TerminalSettings folder not found." "WARN"
}

Write-Log "=== Setup Complete! Restart terminal to see changes. ==="
