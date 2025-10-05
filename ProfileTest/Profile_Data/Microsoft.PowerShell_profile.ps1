oh-my-posh init pwsh --config "C:\Users\MotherBrain V\Documents\PowerShell\midgetsrampage.omp.json" | Invoke-Expression

# ========================
# Custom Aliases
# ========================

# Easier directory listing
# Alias-like function for tree
Set-Alias tt tree
Set-Alias ll Get-ChildItem
Set-Alias la "Get-ChildItem -Force"
# Instead of Set-Alias .. Set-Location ..
function .. { Set-Location .. }

# Jump to HyperSpin Attraction folder
function HS_A {
    Set-Location "E:\HyperSpin Attraction"
}


# Clear screen
Set-Alias cls Clear-Host

# Open Windows Terminal (wt) quickly
Set-Alias wt "C:\Users\MotherBrain V\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_1.23.12681.0_x64__8wekyb3d8bbwe\wt.exe"

#Terminal-Icons
Import-Module Terminal-Icons

#PSReadLine
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionViewStyle ListView

# Shortcut to nvim
Set-Alias vim nvim
Set-Alias vi nvim

# Git shortcuts
function g  { git @args }
function gs { git status @args }
function gcm { git commit @args }
function gph { git push @args }
function gpl { git pull @args }

# Go up multiple directories: up 2 -> cd ../..
function up { Set-Location ('.' + ('\..' * $args[0])) }


# Yarn/npm
Set-Alias y yarn
Set-Alias np npm

# ========================
# Utility Functions
# ========================

# Go up multiple directories: up 2 -> cd ../..
function up { Set-Location ('.' + ('\..' * $args[0])) }

# Reload profile without restarting terminal
function reload-profile { . $PROFILE }

# Quickly open profile in nvim
function edit-profile { nvim $PROFILE }# ========================
# Custom Aliases
# ========================

# Easier directory listing
Set-Alias ll Get-ChildItem
function la { Get-ChildItem -Force }

# Clear screen
Set-Alias cls Clear-Host

# Open Windows Terminal
Set-Alias wt "C:\Users\MotherBrain V\AppData\Local\Microsoft\WindowsApps\Microsoft.WindowsTerminal_1.23.12681.0_x64__8wekyb3d8bbwe\wt.exe"

# Shortcut to nvim
Set-Alias vim nvim
Set-Alias vi nvim

# Git shortcuts (must use functions to avoid conflicts with built-ins)
function g  { git @args }
function gs { git status @args }
function gcm { git commit @args }
function gph { git push @args }
function gpl { git pull @args }

# Yarn/npm
Set-Alias y yarn
Set-Alias np npm

# ========================
# Utility Functions
# ========================

Function whereis ($command) {
	Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue	
}

# Go up multiple directories: up 2 -> cd ../..
function up { Set-Location ('.' + ('\..' * $args[0])) }

# Reload profile without restarting terminal
function reload-profile { . $PROFILE }

# Quickly open profile in nvim
function edit-profile { nvim $PROFILE }


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
