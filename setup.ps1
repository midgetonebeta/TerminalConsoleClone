# ================================
# TerminalConsoleClone Setup Script
# ================================

# --- Force execution policy bypass for this process ---
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== TerminalConsoleClone Setup Started ===" -ForegroundColor Cyan

# --- Helper function for logging ---
function Log($msg, $color="White") {
    Write-Host ">>> $msg" -ForegroundColor $color
}

# --- Paths ---
$scriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$themeSource  = Join-Path $scriptRoot "Profile_Data\midgetsrampage.omp.json"
$profileDir   = Split-Path $PROFILE
$themeDest    = Join-Path $profileDir "midgetsrampage.omp.json"

# --- Install Fonts ---
$fontDir = Join-Path $scriptRoot "Font"
if (Test-Path $fontDir) {
    Log "Installing fonts from $fontDir" "Yellow"
    Get-ChildItem -Path $fontDir -Include *.ttf -Recurse | ForEach-Object {
        try {
            Copy-Item $_.FullName -Destination "C:\Windows\Fonts" -Force
            Log "Installed font: $($_.Name)" "Green"
        } catch {
            Log "Failed to install font: $($_.Name)" "Red"
        }
    }
} else {
    Log "Font directory not found, skipping font install" "DarkYellow"
}

# --- Copy theme file ---
if (Test-Path $themeSource) {
    Copy-Item -Path $themeSource -Destination $themeDest -Force
    Log "Theme copied to $themeDest" "Green"
} else {
    Log "Theme source missing: $themeSource" "Red"
}

# --- Setup PowerShell profile ---
if (-not (Test-Path $templatePath)) {
    Log "Template profile not found: $templatePath" "Red"
    exit 1
}

# Ensure profile directory exists
if (-not (Test-Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
}

# Always recreate profile file
New-Item -Path $PROFILE -Type File -Force | Out-Null
$profileContent = Get-Content $templatePath -Raw

# --- Fix oh-my-posh line ---
$profileContent = $profileContent -replace 'oh-my-posh init pwsh --config ".*midgetsrampage\.omp\.json".*',
    "oh-my-posh init pwsh --config `"$themeDest`" | Invoke-Expression"

# --- Fix wt alias ---
$wtPath = (Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if ($wtPath) {
    $profileContent = $profileContent -replace 'Set-Alias wt ".*"', "Set-Alias wt `"$wtPath`""
    Log "wt.exe detected at $wtPath" "Green"
} else {
    Log "wt.exe not found - skipping alias update" "Red"
}

# Save final profile
Set-Content -Path $PROFILE -Value $profileContent -Force -Encoding UTF8
Log "Profile updated at $PROFILE" "Green"

# --- Install required modules ---
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Log "Installing module $moduleName" "Yellow"
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
        } else {
            Log "Module $moduleName already installed" "Green"
        }
    } catch {
        Log "Failed to install module $moduleName : $($_.Exception.Message)" "Red"
    }
}

# --- Configure Windows Terminal default profile ---
Log "Configuring Windows Terminal default profile..." "Cyan"

# Look for both Store & Preview installations
$wtSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
)

$wtSettingsPath = $wtSettingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($wtSettingsPath) {
    Log "Found Windows Terminal settings: $wtSettingsPath" "Yellow"

    $settingsJson = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json

    # Detect PowerShell 7 profile by name
    $psProfile = $settingsJson.profiles.list | Where-Object { $_.name -match "PowerShell" -and $_.commandline -match "pwsh.exe" } | Select-Object -First 1

    if ($psProfile) {
        $settingsJson.defaultProfile = $psProfile.guid
        $settingsJson | ConvertTo-Json -Depth 10 | Set-Content $wtSettingsPath -Encoding UTF8
        Log "Default profile set to PowerShell 7 (GUID: $($psProfile.guid))" "Green"
    } else {
        Log "Could not find PowerShell 7 profile in settings.json" "Red"
    }
} else {
    Log "Windows Terminal settings.json not found - skipping" "DarkYellow"
}

Write-Host "=== TerminalConsoleClone Setup Complete ===" -ForegroundColor Cyan
