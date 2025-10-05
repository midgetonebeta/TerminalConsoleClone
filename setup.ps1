# Ensure script runs as Admin with Bypass ExecutionPolicy
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Restarting with Administrator rights..."
    Start-Process pwsh "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set ExecutionPolicy to Bypass for this process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Write-Output "=== TerminalConsoleClone Setup Starting ==="

# -------------------------------
# 1. Install Chocolatey if missing
# -------------------------------
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Output "Chocolatey already installed."
}

# -------------------------------
# 2. Install core tools
# -------------------------------
$packages = @("git", "neovim", "python", "nodejs", "yarn", "7zip", "oh-my-posh")

foreach ($pkg in $packages) {
    if (-not (choco list --local-only | Select-String $pkg)) {
        Write-Output "Installing ${pkg}..."
        choco install $pkg -y
    } else {
        Write-Output "${pkg} already installed."
    }
}

# -------------------------------
# 3. Install PowerShell Modules
# -------------------------------
$modules = @("Terminal-Icons", "z")

foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-Output "Installing PowerShell module: ${moduleName}"
            Install-Module -Name $moduleName -Scope CurrentUser -Force -ErrorAction Stop
        } else {
            Write-Output "Module ${moduleName} already installed."
        }
    }
    catch {
        Write-Warning "Failed to install ${moduleName}: $($_.Exception.Message)"
    }
}

# -------------------------------
# 4. Install Fonts
# -------------------------------
$fontPath = Join-Path $PSScriptRoot "Font"
$fonts = Get-ChildItem $fontPath -Filter *.ttf

foreach ($font in $fonts) {
    $dest = "$env:WINDIR\Fonts\$($font.Name)"
    if (-not (Test-Path $dest)) {
        Write-Output "Installing font: $($font.Name)"
        Copy-Item $font.FullName -Destination $env:WINDIR\Fonts -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
            -Name $font.BaseName -Value $font.Name -PropertyType String -Force | Out-Null
    } else {
        Write-Output "Font already installed: $($font.Name)"
    }
}

# -------------------------------
# 5. Copy Profile and Theme
# -------------------------------
$profileSource = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$profileDest = $PROFILE
$themeSource = Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json"
$themeDestDir = Split-Path $PROFILE
$themeDest = Join-Path $themeDestDir "midgetsrampage.omp.json"

# Backup old profile if it exists
if (Test-Path $profileDest) {
    Write-Output "Backing up existing profile..."
    Rename-Item $profileDest "${profileDest}.bak" -Force
}

# Copy theme
Copy-Item $themeSource -Destination $themeDest -Force

# Copy profile template and rewrite user paths
$profileContent = Get-Content $profileSource -Raw

# Insert correct OneDrive/Documents path for theme
$profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\(OneDrive\\)?Documents\\PowerShell\\midgetsrampage.omp.json', `
    [Regex]::Escape($themeDest)

# Insert correct wt.exe path (if found)
$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
if ($wtPath) {
    $profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\AppData\\Local\\Microsoft\\WindowsApps(\\[^\\]+)?\\wt.exe', `
        [Regex]::Escape($wtPath)
}

# Write new profile
Set-Content -Path $profileDest -Value $profileContent -Force -Encoding UTF8

Write-Output "Profile and theme installed."

# -------------------------------
# 6. Copy Terminal Settings
# -------------------------------
$terminalSource = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalDestDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $terminalSource) {
    Copy-Item $terminalSource -Destination (Join-Path $terminalDestDir "settings.json") -Force
    Write-Output "Terminal settings copied."
}

Write-Output "=== Setup Completed Successfully ==="
