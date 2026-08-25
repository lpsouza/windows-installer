# windows-installer

This repository contains PowerShell scripts and WinGet configurations to automate the setup and customization of Windows environments. You can use it as a reference to create your own configuration.

## Requirements

- **Windows 10 / 11** or **Windows Server 2022+**
- **Windows Package Manager (`winget`)** (pre-installed via App Installer from Microsoft Store)
- **PowerShell 5.1+ or PowerShell 7+**
- **Administrator privileges**

## Structure

- `scripts/apply-winget-configuration.ps1`: Validates/installs `Microsoft.WinGet.DSC` and applies WinGet configuration with support for package filtering and interactive selection.
- `scripts/enable-remote-desktop.ps1`: Enables Remote Desktop with Network Level Authentication (NLA) and configures the inbound firewall rule.
- `scripts/windows-firewall.ps1`: Resets firewall rules, enforces default inbound blocking, and configures required inbound rules.
- `.config/configuration.winget`: WinGet Configuration file containing declarative package definitions.

## How to Use

Run scripts from an elevated PowerShell session:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Initial Setup (Full Execution)

To run the complete machine configuration:

```powershell
.\scripts\enable-remote-desktop.ps1
.\scripts\windows-firewall.ps1
.\scripts\apply-winget-configuration.ps1
```

### Manage Packages with WinGet Configuration

#### Install all applications

```powershell
.\scripts\apply-winget-configuration.ps1
```

#### Install a specific application

```powershell
.\scripts\apply-winget-configuration.ps1 -Package "Obsidian.Obsidian"
```

#### Install multiple specific applications

```powershell
.\scripts\apply-winget-configuration.ps1 -Package "Git.Git", "Microsoft.VisualStudioCode", "Docker.DockerDesktop"
```

#### Install applications using wildcards

```powershell
.\scripts\apply-winget-configuration.ps1 -Package "*Docker*", "*Sysinternals*"
```

#### Interactive selection

Select packages interactively using GUI GridView (or interactive console menu):

```powershell
.\scripts\apply-winget-configuration.ps1 -Interactive
```

#### List available applications

List all applications declared in `.config/configuration.winget`:

```powershell
.\scripts\apply-winget-configuration.ps1 -List
```

#### Optional: install DSC module for all users

```powershell
.\scripts\apply-winget-configuration.ps1 -InstallModuleForAllUsers
```

---

## Applications Installation Guide

This guide lists all applications available for installation through `.config/configuration.winget`.

### Core & Shell Tools

| Application | Package ID | Source | Description |
| :--- | :--- | :--- | :--- |
| **PowerShell 7** | `Microsoft.PowerShell` | `winget` | Modern cross-platform PowerShell shell |
| **Intelligent Terminal** | `Microsoft.IntelligentTerminal` | `winget` | Windows Terminal with intelligent enhancements |
| **Starship** | `Starship.Starship` | `winget` | Fast, customizable cross-shell prompt |
| **gsudo** | `gerardog.gsudo` | `winget` | Sudo-like elevation tool for Windows |
| **Coreutils** | `Microsoft.Coreutils` | `winget` | Standard GNU core utilities |

### Development & DevOps

| Application | Package ID | Source | Description |
| :--- | :--- | :--- | :--- |
| **Git** | `Git.Git` | `winget` | Distributed version control system |
| **Visual Studio Code** | `Microsoft.VisualStudioCode` | `winget` | Extensible code editor |
| **Docker Desktop** | `Docker.DockerDesktop` | `winget` | Container runtime and development environment |
| **Helm** | `Helm.Helm` | `winget` | The Kubernetes Package Manager |
| **k9s** | `Derailed.k9s` | `winget` | Kubernetes CLI management UI |
| **Google Antigravity** | `Google.Antigravity` | `winget` | Antigravity developer tools |
| **Google Antigravity CLI** | `Google.AntigravityCLI` | `winget` | Antigravity command line interface |

### System Utilities

| Application | Package ID | Source | Description |
| :--- | :--- | :--- | :--- |
| **PowerToys** | `Microsoft.PowerToys` | `winget` | Windows system utilities for power users |
| **7-Zip** | `7zip.7zip` | `winget` | File archiver with high compression ratio |
| **Sysinternals Suite** | `Microsoft.Sysinternals.Suite` | `winget` | Complete suite of troubleshooting utilities |
| **RDCMan** | `Microsoft.Sysinternals.RDCMan` | `winget` | Remote Desktop Connection Manager |
| **Flameshot** | `Flameshot.Flameshot` | `winget` | Powerful screenshot and annotation tool |
| **Logi Options+** | `Logitech.OptionsPlus` | `winget` | Logitech device configuration app |

### Productivity & Networking

| Application | Package ID | Source | Description |
| :--- | :--- | :--- | :--- |
| **Google Chrome** | `Google.Chrome` | `winget` | Fast and secure web browser |
| **Google Drive** | `Google.GoogleDrive` | `winget` | Cloud file storage and synchronization |
| **Tailscale** | `Tailscale.Tailscale` | `winget` | Zero-config Mesh VPN based on WireGuard |
| **Obsidian** | `Obsidian.Obsidian` | `winget` | Knowledge base and Markdown note-taking app |
| **1Password** | `AgileBits.1Password` | `winget` | Password manager and credential vault |
| **Todoist** | `9MWF2DWS5Z9N` | `msstore` | Task manager, planner, and calendar |

---

## Other Configuration Scripts

### Remote Desktop Hardening

The `scripts/enable-remote-desktop.ps1` script enables Remote Desktop connections while applying security best practices:

- Enables RDP service (`fDenyTSConnections = 0`).
- Enforces **Network Level Authentication (NLA)** (`UserAuthentication = 1`) and TLS negotiation (`SecurityLayer = 2`).
- Restricts the RDP inbound firewall rule (`3389/TCP`) strictly to the **Private** network profile.

### Windows Firewall Configuration

The `scripts/windows-firewall.ps1` script hardens the network layer:

- Resets firewall policies to factory defaults using `netsh advfirewall reset`.
- Enforces **Default Inbound Block** (`DefaultInboundAction = Block`) and **Default Outbound Allow** across Domain, Public, and Private profiles.
- Creates explicit and idempotent inbound rules for **mDNS** (`5353/UDP`) and **Wireless Display** (`WUDFHost.exe`) restricted to the Private profile.
