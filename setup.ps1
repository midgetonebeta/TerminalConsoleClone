# ================================
# TerminalConsoleClone Setup Script
# ================================

# Ensure running as Admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting this script as Administrator..." -ForegroundColor Yellow
    Start-Process pwsh "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Bypass execution policy for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# -------------------------------
# Detect correct Documents\PowerShell path
# -------------------------------
$docPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell"
if (!(Test-Path $docPath)) {
    New-Item -ItemType Directory -Path $docPath -Force | Out-Null
}

Write-Host "Using profile folder: $docPath" -ForegroundColor Cyan

# -------------------------------
# Backup existing profile if present
# -------------------------------
if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak"
    Copy-Item $PROFILE $backup -Force
    Write-Host "Backed up existing profile to $backup" -ForegroundColor Yellow
}

# -------------------------------
# Copy our custom profile template
# -------------------------------
$sourceProfile = Join-Path $PSScriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$destProfile   = $PROFILE

if (Test-Path $sourceProfile) {
    Copy-Item $sourceProfile -Destination $destProfile -Force
    Write-Host "Copied profile to $destProfile" -ForegroundColor Green
} else {
    Write-Warning "Profile template not found: $sourceProfile"
}

# -------------------------------
# Copy Oh My Posh theme file
# -------------------------------
$sourceTheme = Join-Path $PSScriptRoot "Profile_Data\midgetsrampage.omp.json"
$themeDest   = Join-Path $docPath "midgetsrampage.omp.json"

if (Test-Path $sourceTheme) {
    Copy-Item $sourceTheme -Destination $themeDest -Force
    Write-Host "Copied theme file to $themeDest" -ForegroundColor Green
} else {
    Write-Warning "Theme file not found: $sourceTheme"
}

# -------------------------------
# Fix dynamic paths inside profile
# -------------------------------
$profileContent = Get-Content $destProfile -Raw

# Insert correct OneDrive/Documents path for theme
$profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\(OneDrive\\)?Documents\\PowerShell\\midgetsrampage.omp.json', `
    [Regex]::Escape($themeDest)

# Insert correct wt.exe path (if found)
$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
if ($wtPath) {
    $profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\AppData\\Local\\Microsoft\\WindowsApps(\\[^\\]+)?\\wt.exe', `
        [Regex]::Escape($wtPath)
}

# Save patched profile
Set-Content -Path $destProfile -Value $profileContent -Encoding UTF8
Write-Host "Patched profile with correct paths." -ForegroundColor Green

# -------------------------------
# Install PowerShell modules
# -------------------------------
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host "Installed $moduleName" -ForegroundColor Green
        } else {
            Write-Host "$moduleName already installed." -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Failed to install $moduleName: $($_.Exception.Message)"
    }
}

# -------------------------------
# Install Fonts
# -------------------------------
$fontPath = Join-Path $PSScriptRoot "Font"
if (Test-Path $fontPath) {
    Write-Host "Installing fonts from $fontPath ..." -ForegroundColor Cyan
    Get-ChildItem -Path $fontPath -Filter *.ttf | ForEach-Object {
        $fontDest = Join-Path "$env:WINDIR\Fonts" $_.Name
        if (!(Test-Path $fontDest)) {
            Copy-Item $_.FullName -Destination $fontDest
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
                             -Name $_.BaseName -Value $_.Name -PropertyType String -Force | Out-Null
            Write-Host "Installed font: $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "Font already installed: $($_.Name)" -ForegroundColor Gray
        }
    }
} else {
    Write-Warning "Font folder not found: $fontPath"
}

# -------------------------------
# Copy Windows Terminal settings
# -------------------------------
$sourceSettings = Join-Path $PSScriptRoot "TerminalSettings\settings.json"
$terminalPath = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $sourceSettings) {
    Copy-Item $sourceSettings -Destination $terminalPath -Force
    Write-Host "Copied Windows Terminal settings to $terminalPath" -ForegroundColor Green
} else {
    Write-Warning "Terminal settings not found: $sourceSettings"
}

Write-Host "`nSetup complete! Restart PowerShell to apply changes." -ForegroundColor Cyan
