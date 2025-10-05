Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== TerminalConsoleClone Setup Starting ==="

# --- Detect script root ---
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script root: $scriptRoot"

# --- Paths for template + theme ---
$templatePath = Join-Path $scriptRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$themeSource  = Join-Path $scriptRoot "Profile_Data\midgetsrampage.omp.json"
$profileDir   = Split-Path $PROFILE
$themeDest    = Join-Path $profileDir "midgetsrampage.omp.json"

Write-Host "Template profile: $templatePath"
Write-Host "Theme source: $themeSource"
Write-Host "Theme destination: $themeDest"
Write-Host "Profile path: $PROFILE"

# --- Ensure profile dir exists ---
if (-not (Test-Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    Write-Host "Created profile directory: $profileDir"
}

# --- Copy template profile ---
if (Test-Path $templatePath) {
    $profileContent = Get-Content $templatePath -Raw
    Write-Host "Loaded template profile."
} else {
    Write-Error "Template profile not found at $templatePath"
    exit 1
}

# --- Ensure theme JSON copied into profile dir ---
try {
    if (-not (Test-Path $themeDest)) {
        Copy-Item -Path $themeSource -Destination $themeDest -Force
        Write-Host "✔ Copied theme to $themeDest"
    } else {
        Write-Host "✔ Theme already exists at $themeDest"
    }
}
catch {
    Write-Warning "Failed to copy theme: $($_.Exception.Message)"
}

# --- Fix oh-my-posh line ---
$profileContent = $profileContent -replace 'oh-my-posh init pwsh --config ".*"',
    "oh-my-posh init pwsh --config `"$themeDest`" | Invoke-Expression"

# --- Detect wt.exe path ---
$wtPath = Get-Command wt.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
if (-not $wtPath) {
    Write-Warning "wt.exe not found in PATH, alias may not work"
} else {
    Write-Host "Detected wt.exe at $wtPath"
    $profileContent = $profileContent -replace 'Set-Alias wt ".*"',
        "Set-Alias wt `"$wtPath`""
}

# --- Write profile ---
Set-Content -Path $PROFILE -Value $profileContent -Force
Write-Host "✔ Updated $PROFILE"

# --- Install required modules ---
$modules = @("Terminal-Icons", "z")
foreach ($moduleName in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-Host "Installing $moduleName..."
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber
        } else {
            Write-Host "$moduleName already installed."
        }
    }
    catch {
        Write-Warning "Failed to install $moduleName : $($_.Exception.Message)"
    }
}

# --- Install fonts ---
$fontDir = Join-Path $scriptRoot "Font"
if (Test-Path $fontDir) {
    Write-Host "Installing fonts from $fontDir..."
    Get-ChildItem -Path $fontDir -Include *.ttf -Recurse | ForEach-Object {
        $fontDest = Join-Path "$env:WINDIR\Fonts" $_.Name
        if (-not (Test-Path $fontDest)) {
            Copy-Item $_.FullName -Destination $fontDest
            Write-Host "✔ Installed font: $($_.Name)"
        } else {
            Write-Host "✔ Font already installed: $($_.Name)"
        }
    }
}

# --- Copy terminal settings ---
$terminalSrc = Join-Path $scriptRoot "TerminalSettings\settings.json"
$terminalDest = Join-Path $env:LocalAppData "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSrc) {
    try {
        Copy-Item -Path $terminalSrc -Destination $terminalDest -Force
        Write-Host "✔ Copied terminal settings to $terminalDest"
    }
    catch {
        Write-Warning "Failed to copy terminal settings: $($_.Exception.Message)"
    }
}

Write-Host "=== Setup Complete. Restart your terminal. ==="
