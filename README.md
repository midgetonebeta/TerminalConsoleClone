# TerminalConsoleClone

![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey?logo=windows)
[![Release](https://img.shields.io/github/v/release/midgetonebeta/TerminalConsoleClone?logo=github)](https://github.com/midgetonebeta/TerminalConsoleClone/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/midgetonebeta/TerminalConsoleClone/total?logo=github)](https://github.com/midgetonebeta/TerminalConsoleClone/releases)
[![License](https://img.shields.io/github/license/midgetonebeta/TerminalConsoleClone)](LICENSE)
[![Stars](https://img.shields.io/github/stars/midgetonebeta/TerminalConsoleClone?style=social)](https://github.com/midgetonebeta/TerminalConsoleClone/stargazers)

Terminal config and install that’s cloned as Perseh from my main setup.

## Troubleshooting

- You need to Run the Setup.ps1 File as Admin.
- Requirements: Windows 10/11, Git installed.
- Run PowerShell as Administrator if fonts fail.

## Features

- Custom PowerShell profile with aliases and functions
- Oh My Posh theme (`midgetsrampage.omp.json`)
- Auto-install PowerShell 7, fonts, and terminal settings
- Fonts: CascadiaCode Nerd Font
- Easy setup with `setup.ps1`

## 📸 Screenshots

### File Tree

![File Tree](Screenshots/Screenshot.png)

### Running Setup

![Running Setup](Screenshots/Screenshot_1.png)

### Final Look

![Final Look](Screenshots/Screenshot_3.png)

---

## 📂 Contents

- `Profile_Data/` → PowerShell profile + Oh My Posh theme
- `Font/` → CascadiaCove Nerd Font TTFs
- `TerminalSettings/` → Windows Terminal settings JSON
- `Screenshots/` → Preview images for this README
- `setup.ps1` → Automates setup (fonts, modules, profile, settings)

---

## ⚡ Installation

Clone this repository and run the setup:

```powershell
git clone https://github.com/midgetonebeta/TerminalConsoleClone.git
cd TerminalConsoleClone
.\setup.ps1
```
