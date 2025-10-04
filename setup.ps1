# ===============================
# Setup Script for TerminalConsoleClone
# ===============================

Write-Host ">>> Starting environment setup..." -ForegroundColor Cyan

# -------------------------------
# 1. Install PowerShell 7 if not installed
# -------------------------------
$PS7Installer = "E:\TerminalConsoleClone\PowerShell 7\PowerShell-7.5.3-win-x64.exe"
if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PowerShell 7.5.3..." -ForegroundColor Yellow
    Start-Process -FilePath $PS7Installer -ArgumentList "/quiet" -Wait
    Write-Host "✔ PowerShell 7 installed" -ForegroundColor Green
} else {
    Write-Host "✔ PowerShell 7 already installed" -ForegroundColor Green
}

# -------------------------------
# 2. Install Chocolatey if missing
# -------------------------------
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Host "✔ Chocolatey installed" -ForegroundColor Green
} else {
    Write-Host "✔ Chocolatey already installed" -ForegroundColor Green
}

# -------------------------------
# 3. Install core tools
# -------------------------------
$packages = "git","neovim","python","nodejs","yarn","7zip"
foreach ($pkg in $packages) {
    if (-not (choco list --local-only | Select-String $pkg)) {
        Write-Host "Installing $pkg..." -ForegroundColor Yellow
        choco install $pkg -y
    } else {
        Write-Host "✔ $pkg already installed" -ForegroundColor Green
    }
}

# -------------------------------
# 4. Copy PowerShell profile + theme
# -------------------------------
$ProfileDest = "$HOME\Documents\PowerShell"
if (-not (Test-Path $ProfileDest)) {
    New-Item -Path $ProfileDest -ItemType Directory | Out-Null
}

Copy-Item -Force "E:\TerminalConsoleClone\Profile_Data\Microsoft.PowerShell_profile.ps1" "$ProfileDest\Microsoft.PowerShell_profile.ps1"
Copy-Item -Force "E:\TerminalConsoleClone\Profile_Data\midgetsrampage.omp.json" "$ProfileDest\midgetsrampage.omp.json"
Copy-Item -Force "E:\TerminalConsoleClone\Profile_Data\powershell.config.json" "$ProfileDest\powershell.config.json"

Write-Host "✔ PowerShell profile and theme installed" -ForegroundColor Green

# -------------------------------
# 5. Install PowerShell modules
# -------------------------------
$modules = "Terminal-Icons","z"
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Installing $mod..." -ForegroundColor Yellow
        Install-Module -Name $mod -Scope CurrentUser -Force
    } else {
        Write-Host "✔ Module $mod already installed" -ForegroundColor Green
    }
}

# -------------------------------
# 6. Install Fonts
# -------------------------------
$FontSource = "E:\TerminalConsoleClone\Font"
$FontDest   = "$env:WINDIR\Fonts"
$RegPath    = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

Write-Host "Installing fonts from $FontSource ..." -ForegroundColor Cyan

Get-ChildItem -Path $FontSource -Filter *.ttf | ForEach-Object {
    $fontFile = $_.FullName
    $fontName = $_.Name
    $destFile = Join-Path $FontDest $fontName

    if (-not (Test-Path $destFile)) {
        Copy-Item $fontFile -Destination $FontDest -Force
        Write-Host "✔ Copied $fontName"

        $fontRegName = ($fontName -replace ".ttf$", "") + " (TrueType)"
        New-ItemProperty -Path $RegPath -Name $fontRegName -Value $fontName -PropertyType String -Force | Out-Null
        Write-Host "✔ Registered $fontName in Registry"
    }
    else {
        Write-Host "⚠ $fontName already installed, skipping."
    }
}

Write-Host ">>> Setup complete!" -ForegroundColor Green
