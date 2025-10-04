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
    - Logs installed fonts
#>

# --- AUTO-ELEVATE ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..."
    Start-Process pwsh "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host "`n=== Starting Environment Setup ===`n"

# --- Install PowerShell 7 (if missing) ---
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Installing PowerShell 7..."
    winget install --id Microsoft.Powershell --source winget -e
}

# --- Install Chocolatey (if missing) ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# --- Core Tools via Choco ---
$packages = @("git", "neovim", "python", "nodejs", "yarn", "7zip")
foreach ($pkg in $packages) {
    if (-not (choco list --localonly | Select-String $pkg)) {
        choco install $pkg -y
    } else {
        Write-Host "$pkg already installed."
    }
}

# --- PowerShell Modules ---
$modules = @("Terminal-Icons", "z")
foreach ($module in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing module $module..."
            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
        } else {
            Write-Host "Module $module already installed."
        }
    } catch {
        Write-Warning "Failed to install module $module: $($_.Exception.Message)"
    }
}

# --- Install Fonts ---
$FontSource = Join-Path $PSScriptRoot "Font"
$FontDest = "C:\Windows\Fonts"

if (Test-Path $FontSource) {
    Write-Host "`nInstalling fonts from $FontSource ..."
    $shell = New-Object -ComObject Shell.Application
    foreach ($fontFile in Get-ChildItem $FontSource -Filter *.ttf) {
        $fontName = $fontFile.Name
        $target = Join-Path $FontDest $fontFile.Name
        if (-not (Test-Path $target)) {
            Write-Host "Installing font: $fontName"
            Copy-Item $fontFile.FullName $FontDest
        } else {
            Write-Host "Font already installed: $fontName"
        }
    }
} else {
    Write-Warning "Font folder not found, skipping fonts."
}

# --- Copy PowerShell Profile & Theme ---
$profileSource = Join-Path $PSScriptRoot "Profile_Data"
if (Test-Path $profileSource) {
    Copy-Item "$profileSource\Microsoft.PowerShell_profile.ps1" $PROFILE -Force
    Copy-Item "$profileSource\midgetsrampage.omp.json" (Split-Path $PROFILE) -Force
    Write-Host "Profile and theme copied."
}

# --- Copy Windows Terminal Settings ---
$termSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$termDest = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $termSource) {
    Copy-Item $termSource $termDest -Force
    Write-Host "Terminal settings copied."
}

Write-Host "`n=== Setup Complete! Restart terminal to see changes. ===`n"
