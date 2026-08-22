# windows-installer

This repository contains PowerShell scripts used to configure a Windows machine after installation.

## Structure

- `scripts/enable-remote-desktop.ps1`: Enables Remote Desktop and ensures the RDP inbound firewall rule is present.
- `scripts/windows-firewall.ps1`: Resets firewall rules and recreates the inbound rules used by this setup.
- `scripts/apply-winget-configuration.ps1`: Validates/install `Microsoft.WinGet.DSC` and applies winget configuration.
- `.config/configuration.winget`: WinGet Configuration file with package definitions.

## Run scripts

Run scripts from an elevated PowerShell session:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\scripts\enable-remote-desktop.ps1
.\scripts\windows-firewall.ps1
.\scripts\apply-winget-configuration.ps1
```

## Manage packages with WinGet Configuration

Run everything (checks/install DSC module when needed, then runs `winget configure`):

```powershell
.\scripts\apply-winget-configuration.ps1
```

To add or remove packages, edit `.config/configuration.winget`.

Optional: install the DSC module for all users.

```powershell
.\scripts\apply-winget-configuration.ps1 -InstallModuleForAllUsers
```
