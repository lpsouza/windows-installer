Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  throw "This script must be run as Administrator."
}

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

try {
  Get-NetFirewallRule | Remove-NetFirewallRule
} catch {
  Write-Warning "Some firewall rules could not be removed: $($_.Exception.Message)"
}

function Ensure-FirewallRule {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [hashtable]$RuleDefinition
  )

  $existing = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
  if ($null -ne $existing) {
    Remove-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
  }

  New-NetFirewallRule @RuleDefinition | Out-Null
}

Ensure-FirewallRule -DisplayName "[WindowsInstaller] Allow mDNS (UDP-In)" -RuleDefinition @{
  DisplayName = "[WindowsInstaller] Allow mDNS (UDP-In)"
  Direction = "Inbound"
  Action = "Allow"
  Enabled = "True"
  Protocol = "UDP"
  LocalPort = 5353
  Profile = "Private"
}

Ensure-FirewallRule -DisplayName "[WindowsInstaller] Allow Wireless Display (TCP-In)" -RuleDefinition @{
  DisplayName = "[WindowsInstaller] Allow Wireless Display (TCP-In)"
  Direction = "Inbound"
  Action = "Allow"
  Enabled = "True"
  Program = "$env:SystemRoot\System32\WUDFHost.exe"
  Profile = "Private"
}

try {
  Set-NetFirewallProfile -Profile Domain, Public, Private -NotifyOnListen False
} catch {
  Write-Warning "Could not disable firewall block notifications: $($_.Exception.Message)"
}

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

Write-Host "Firewall rules were reset and required inbound rules were recreated."
