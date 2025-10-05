# =========================================
# ProfileTest.ps1
# Test script for creating a fresh profile
# =========================================

$logFile = Join-Path $PSScriptRoot "ProfileTest.log"
"=== ProfileTest run $(Get-Date) ===" | Out-File -FilePath $logFile -Encoding utf8

function Log($msg, $color="White") {
    Write-Host $msg -ForegroundColor $color
    Add-Content -Path $logFile -Value $msg
}

Log ">>> Running ProfileTest.ps1" Cyan

# Detect repo root (where this script lives)
$repoRoot   = Split-Path -Parent $PSScriptRoot
$repoProfile = Join-Path $repoRoot "Profile_Data\Microsoft.PowerShell_profile.ps1"
$repoTheme   = Join-Path $repoRoot "Profile_Data\midgetsrampage.omp.json"

if (-not (Test-Path $repoProfile)) {
    Log "ERROR: Repo profile not found at $repoProfile" Red
    exit 1
}
if (-not (Test-Path $repoTheme)) {
    Log "ERROR: Repo theme not found at $repoTheme" Red
    exit 1
}

# Step 1: Detect correct Documents path (prefer OneDrive)
$baseDocs = Join-Path $env:USERPROFILE "OneDrive\Documents"
if (Test-Path $baseDocs) {
    Log "Using OneDrive Documents path: $baseDocs" Yellow
} else {
    $baseDocs = Join-Path $env:USERPROFILE "Documents"
    Log "Using Local Documents path: $baseDocs" Yellow
}
$psDocs = Join-Path $baseDocs "PowerShell"
Log "Final PowerShell profile path will be: $psDocs" Cyan

# Ensure folder exists
if (-not (Test-Path $psDocs)) {
    New-Item -Path $psDocs -ItemType Directory -Force | Out-Null
    Log "Created missing folder: $psDocs" Green
}

# Step 2: Always create a fresh profile file
New-Item -Path $PROFILE -ItemType File -Force | Out-Null
Log "Fresh profile created at: $PROFILE" Green

# Step 3: Load repo profile content
$profileContent = Get-Content $repoProfile -Raw
Log "Loaded repo profile from: $repoProfile" Cyan

# Step 4: Rewrite oh-my-posh config path
$themeDest = Join-Path $psDocs "midgetsrampage.omp.json"
$profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\(OneDrive\\)?Documents\\PowerShell\\midgetsrampage\.omp\.json',
    [Regex]::Escape($themeDest)
Log "Updated oh-my-posh config path -> $themeDest" Green

# Step 5: Rewrite Windows Terminal path
$wtPath = (Get-Command wt.exe -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if ($wtPath) {
    $profileContent = $profileContent -replace 'C:\\Users\\[^\\]+\\AppData\\Local\\Microsoft\\WindowsApps(\\[^\\]+)?\\wt\.exe',
        [Regex]::Escape($wtPath)
    Log "Updated wt.exe alias path -> $wtPath" Green
} else {
    Log "WARNING: wt.exe not found in PATH" Yellow
}

# Step 6: Write new profile with updated content
Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
Log "New profile written to: $PROFILE" Cyan

# Step 7: Copy theme file into Documents\PowerShell
Copy-Item -Path $repoTheme -Destination $psDocs -Force
Log "Theme copied to: $themeDest" Cyan

# Step 8: Show preview of important lines
Log "`n>>> Preview of updated lines:" Cyan
$profileContent -split "`n" | ForEach-Object {
    if ($_ -match "oh-my-posh" -or $_ -match "wt.exe") {
        Log $_ Green
    }
}

# Step 9: Dump full profile to log
Log "`n>>> Full profile content written:" Cyan
$profileContent | Out-File -Append -FilePath $logFile -Encoding utf8

Log ">>> ProfileTest complete. Restart your terminal to apply changes." Cyan
