<#
.SYNOPSIS
  Automated setup for TerminalConsoleClone
.DESCRIPTION
  - Elevation auto-relaunch with -ExecutionPolicy Bypass
  - Install Chocolatey (optional) or use winget
  - Install oh-my-posh, Terminal-Icons
  - Install fonts from ./Font (copy to C:\Windows\Fonts and register)
  - Copy PowerShell profile files from ./Profile_Data to user's Documents\PowerShell
  - Apply Windows Terminal settings from ./TerminalSettings (best-effort)
  - Safe, idempotent, backs up existing files
.NOTES
  Run as Admin for full functionality (the script will relaunch itself elevated).
#>

# --- CONFIG ---
$RepoRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$FontFolder = Join-Path $RepoRoot 'Font'
$ProfileDataFolder = Join-Path $RepoRoot 'Profile_Data'
$TerminalSettingsFolder = Join-Path $RepoRoot 'TerminalSettings'
$UserPowerShellDir = Join-Path $env:USERPROFILE 'Documents\PowerShell'
$FontsDest = Join-Path $env:WINDIR 'Fonts'
$WinTermPaths = @(
    # Store (package) path
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json',
    # New Windows Terminal (msixbundle sometimes)
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json',
    # Fall back to roaming app data path (non-store)
    Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
)

# --- helper functions ---
function Write-Ok($msg){ Write-Host "✔ $msg" -ForegroundColor Green }
function Write-Info($msg){ Write-Host "→ $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "✖ $msg" -ForegroundColor Red }

function Ensure-Elevated {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Warn "Script is not running as Administrator. Relaunching elevated with Bypass execution policy..."
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'powershell.exe'
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
        $psi.Verb = 'runas'
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            Exit 0
        } catch {
            Write-Err "Failed to elevate. Please run PowerShell as Administrator and re-run setup.ps1"
            Exit 1
        }
    } else {
        Write-Ok "Running elevated (Administrator)."
    }
}

function Ensure-ChocoOrWinget {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Ok "choco found."
        return 'choco'
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Ok "winget found."
        return 'winget'
    } else {
        Write-Warn "No choco or winget found. Installing Chocolatey (requires internet)."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                Write-Ok "Chocolatey installed."
                return 'choco'
            } else {
                Write-Err "Chocolatey install failed. Install choco or winget manually and re-run."
                return $null
            }
        } catch {
            Write-Err "Failed to install Chocolatey: $_"
            return $null
        }
    }
}

function Install-PackageIfMissing($manager, $packageId, $chocoName = $null) {
    if ($manager -eq 'choco') {
        $name = $chocoName ?? $packageId
        if ((choco list --localonly | Select-String -Pattern "^$name") -ne $null) {
            Write-Info "$name already installed via choco."
        } else {
            Write-Info "Installing $name via choco..."
            choco install $name -y --no-progress
        }
    } elseif ($manager -eq 'winget') {
        Write-Info "Installing $packageId via winget..."
        winget install --id $packageId -e --silent --accept-package-agreements --accept-source-agreements
    } else {
        Write-Warn "No package manager available to install $packageId"
    }
}

function Install-OhMyPosh {
    $manager = Ensure-ChocoOrWinget
    if (-not $manager) { Write-Warn "Skipping oh-my-posh install." ; return }
    # Attempt choco first (common); fallback to winget command if choco missing
    if ($manager -eq 'choco') {
        Install-PackageIfMissing 'choco' 'oh-my-posh'
    } elseif ($manager -eq 'winget') {
        Install-PackageIfMissing 'winget' 'JanDeDobbeleer.OhMyPosh'
    }
    # Also ensure posh is on PATH (usually installed to %USERPROFILE%\scoop or choco)
    Write-Info "oh-my-posh install attempted. You may need to run 'Import-Module oh-my-posh' or add theme config to your profile."
}

function Install-PowerShellModuleIfMissing($moduleName) {
    if (Get-Module -ListAvailable -Name $moduleName) {
        Write-Info "Module $moduleName already available."
    } else {
        Write-Info "Installing PS module $moduleName (CurrentUser)..."
        try {
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
            Write-Ok "Module $moduleName installed."
        } catch {
            Write-Warn "Failed to install $moduleName: $_"
        }
    }
}

function Install-FontsFromFolder {
    param($SourceFolder)
    if (-not (Test-Path $SourceFolder)) { Write-Warn "Font folder $SourceFolder not found. Skipping fonts." ; return }
    $ttfs = Get-ChildItem -Path $SourceFolder -Include *.ttf,*.otf -File -Recurse -ErrorAction SilentlyContinue
    if (-not $ttfs) { Write-Warn "No TTF/OTF files in $SourceFolder. Skipping fonts." ; return }
    foreach ($f in $ttfs) {
        $dest = Join-Path $FontsDest $f.Name
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $f.FullName -Destination $dest -Force
            Write-Ok "Copied $($f.Name) → $FontsDest"
        } else {
            Write-Info "$($f.Name) already present in $FontsDest"
        }

        # register font in registry under HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
        try {
            $fontName = (& powershell -NoProfile -Command "(New-Object System.Drawing.Text.PrivateFontCollection).AddFontFile('$dest'); (New-Object System.Drawing.Text.PrivateFontCollection).Families | ForEach-Object { $_.Name }" ) -ErrorAction SilentlyContinue
        } catch {
            $fontName = $null
        }
        # fallback to using file base name as registry value if we couldn't query family name
        if (-not $fontName) { $fontName = $f.BaseName }

        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        $valueName = "$fontName (TrueType)"
        # Some fonts may have different display strings - we'll attempt a few common keys
        if (-not (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $regPath -Name $valueName -Value $f.Name -PropertyType String -Force | Out-Null
            Write-Ok "Registered '$valueName' in registry"
        } else {
            Write-Info "Registry entry for $valueName already exists"
        }
    }
    Write-Ok "Font install finished. Windows may need a logoff/login to pick up fonts."
}

function Backup-And-Copy($srcFile, $destFile) {
    if (Test-Path $destFile) {
        $bak = "$destFile.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
        Copy-Item -Path $destFile -Destination $bak -Force
        Write-Info "Backed up existing $destFile → $bak"
    }
    Copy-Item -Path $srcFile -Destination $destFile -Force
    Write-Ok "Copied $srcFile → $destFile"
}

function Deploy-Profiles {
    if (-not (Test-Path $ProfileDataFolder)) { Write-Warn "Profile_Data not found; skipping profile copy." ; return }
    if (-not (Test-Path $UserPowerShellDir)) {
        New-Item -Path $UserPowerShellDir -ItemType Directory -Force | Out-Null
        Write-Info "Created $UserPowerShellDir"
    }

    Get-ChildItem -Path $ProfileDataFolder -File | ForEach-Object {
        $src = $_.FullName
        $dest = Join-Path $UserPowerShellDir $_.Name
        Backup-And-Copy $src $dest
    }
    Write-Ok "Profiles deployed. Reload profile by running: . $PROFILE"
}

function Deploy-WindowsTerminalSettings {
    if (-not (Test-Path $TerminalSettingsFolder)) { Write-Warn "TerminalSettings folder not found; skipping." ; return }
    $settingsFile = Get-ChildItem -Path $TerminalSettingsFolder -Filter '*.json' -File | Select-Object -First 1
    if (-not $settingsFile) { Write-Warn "No settings json found in TerminalSettings; skipping." ; return }
    $src = $settingsFile.FullName
    $applied = $false
    foreach ($possible in $WinTermPaths) {
        $dir = Split-Path $possible -Parent
        if (-not (Test-Path $dir)) { continue }
        $dest = $possible
        Backup-And-Copy $src $dest
        Write-Ok "Windows Terminal settings written to $dest"
        $applied = $true
    }
    if (-not $applied) {
        # fallback: write to LOCALAPPDATA Microsoft\Windows Terminal
        $fallbackDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal'
        if (-not (Test-Path $fallbackDir)) { New-Item -Path $fallbackDir -ItemType Directory -Force | Out-Null }
        $dest = Join-Path $fallbackDir 'settings.json'
        Backup-And-Copy $src $dest
        Write-Ok "Windows Terminal settings written to $dest (fallback)"
    }
}

# --- MAIN ---
Write-Host "========== TerminalConsoleClone Setup ==========" -ForegroundColor Magenta
Ensure-Elevated

# Install core tooling (optional)
$packManager = Ensure-ChocoOrWinget
if ($packManager) {
    Install-OhMyPosh
}

# Install Terminal-Icons module (makes 'ls' pretty)
Install-PowerShellModuleIfMissing -moduleName 'Terminal-Icons'

# Deploy Profiles
Deploy-Profiles

# Install fonts
Install-FontsFromFolder -SourceFolder $FontFolder

# Deploy Windows Terminal settings
Deploy-WindowsTerminalSettings

Write-Host "Setup complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host " - Restart Windows (or log off/log on) so new fonts are recognized." -ForegroundColor Cyan
Write-Host " - Open a new Windows Terminal and run: . $PROFILE to load the profile (or restart terminal)." -ForegroundColor Cyan
Write-Host " - If oh-my-posh isn't showing, ensure POSH_THEMES_PATH is set or your profile points to the .omp.json." -ForegroundColor Cyan
Write-Host ""
Write-Host "If anything failed, re-run this script from an elevated PowerShell and paste the error output to debug." -ForegroundColor Yellow
