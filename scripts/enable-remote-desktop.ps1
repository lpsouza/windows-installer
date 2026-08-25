Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  throw "This script must be run as Administrator."
}

$rdpRegistryPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
$rdpRegistryName = "fDenyTSConnections"
$currentRdpValue = (Get-ItemProperty -Path $rdpRegistryPath -Name $rdpRegistryName -ErrorAction SilentlyContinue).$rdpRegistryName

# Enable Remote Desktop
Set-ItemProperty -Path $rdpRegistryPath -Name $rdpRegistryName -Value 0

# Enforce Network Level Authentication (NLA)
$nlaRegistryPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$currentNlaValue = (Get-ItemProperty -Path $nlaRegistryPath -Name "UserAuthentication" -ErrorAction SilentlyContinue).UserAuthentication
Set-ItemProperty -Path $nlaRegistryPath -Name "UserAuthentication" -Value 1
Set-ItemProperty -Path $nlaRegistryPath -Name "SecurityLayer" -Value 2

$rdpRuleName = "[WindowsInstaller] Allow Remote Desktop (TCP-In)"
$existingRule = Get-NetFirewallRule -DisplayName $rdpRuleName -ErrorAction SilentlyContinue

$rdpRuleDefinition = @{
  DisplayName = $rdpRuleName
  Direction   = "Inbound"
  Action      = "Allow"
  Protocol    = "TCP"
  LocalPort   = 3389
  Profile     = "Private"
  Enabled     = "True"
}

if ($null -eq $existingRule) {
  New-NetFirewallRule @rdpRuleDefinition | Out-Null
} else {
  Set-NetFirewallRule -DisplayName $rdpRuleName -Enabled True -Profile Private | Out-Null
}

if ($currentRdpValue -ne 0 -or $currentNlaValue -ne 1) {
  Restart-Service -Name "TermService" -Force
}

Write-Host "Remote Desktop is enabled with Network Level Authentication (NLA) and firewall rule configured."
