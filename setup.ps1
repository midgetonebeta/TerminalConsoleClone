# Ensure script runs even if system blocks unsigned scripts
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== TerminalConsoleClone Setup Starting ===" -ForegroundColor Cyan

# --- Detect script root ---
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Ensure PowerShell profile folder exists ---
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    Write-Host "Creating profile directory: $profileDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# --- Paths for template + theme ---
$templatePath = Join-Path $scriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$themeSource  = Join-Path $scriptRoot "Profile_Data\midgetsrampage.omp.json"
$themeDest    = Join-Path $profileDir "midgetsrampage.omp.json"

# --- Copy template profile ---
if (Test-Path $templatePath) {
    Write-Host "Copying profile template → $PROFILE" -ForegroundColor Green
    Copy-Item $templatePath $PROFILE -Force
} else {
    Write-Warning "Template profile missing: $templatePath"
}

# --- Copy theme JSON ---
if (Test-Path $themeSource) {
    Write-Host "Copying theme → $themeDest" -ForegroundColor Green
    Copy-Item $themeSource $themeDest -Force
} else {
    Write-Warning "Theme file missing: $themeSource"
}

# --- Load profile content ---
$profileContent = Get-Content $PROFILE -Raw

# --- Fix oh-my-posh line (dynamic Documents path) ---
$newOhMyPosh = "oh-my-posh init pwsh --config `"$themeDest`" | Invoke-Expression"
if ($profileContent -match "oh-my-posh init pwsh") {
    Write-Host "Updating oh-my-posh init line → $themeDest" -ForegroundColor Yellow
    $profileContent = ($profileContent -split "`r?`n") | ForEach-Object {
        if ($_ -match "oh-my-posh init pwsh") { $newOhMyPosh } else { $_ }
    } | Out-String
}

# --- Detect wt.exe ---
$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
if (-not $wtPath) {
    $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
}
$newWT = "Set-Alias wt `"$wtPath`""

# --- Fix wt alias ---
if ($profileContent -match "Set-Alias wt") {
    Write-Host "Updating wt alias → $wtPath" -ForegroundColor Yellow
    $profileContent = ($profileContent -split "`r?`n") | ForEach-Object {
        if ($_ -match "Set-Alias wt") { $newWT } else { $_ }
    } | Out-String
}

# --- Save updated profile ---
$profileContent | Set-Content $PROFILE -Force -Encoding UTF8
Write-Host "Profile updated at $PROFILE" -ForegroundColor Green

# --- Install Fonts ---
$fontPath = Join-Path $scriptRoot "Font"
if (Test-Path $fontPath) {
    Write-Host "Installing fonts from $fontPath ..." -ForegroundColor Cyan
    $fonts = Get-ChildItem -Path $fontPath -Include *.ttf, *.otf -Recurse
    foreach ($font in $fonts) {
        Write-Host " → Installing $($font.Name)" -ForegroundColor Yellow
        Copy-Item $font.FullName -Destination "$env:WINDIR\Fonts" -Force
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v $font.BaseName /t REG_SZ /d $font.Name /f | Out-Null
    }
} else {
    Write-Warning "Font folder missing: $fontPath"
}

# --- Copy Terminal Settings ---
$terminalSrc = Join-Path $scriptRoot "TerminalSettings\settings.json"
$terminalDestDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $terminalSrc) {
    if (-not (Test-Path $terminalDestDir)) { New-Item -ItemType Directory -Path $terminalDestDir -Force | Out-Null }
    Write-Host "Copying terminal settings → $terminalDestDir" -ForegroundColor Green
    Copy-Item $terminalSrc (Join-Path $terminalDestDir "settings.json") -Force
} else {
    Write-Warning "Terminal settings file missing: $terminalSrc"
}

# --- Install modules ---
$modules = @("Terminal-Icons", "z")
foreach ($m in $modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing module: $m" -ForegroundColor Yellow
        try {
            Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber
        } catch {
            Write-Warning "Failed to install module: $m"
        }
    } else {
        Write-Host "Module already installed: $m" -ForegroundColor Green
    }
}

Write-Host "=== Setup Finished! Restart PowerShell to load changes. ===" -ForegroundColor Cyan
