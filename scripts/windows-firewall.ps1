Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  throw "This script must be run as Administrator."
}

Write-Host "Resetting Windows Firewall to default state..."
netsh advfirewall reset | Out-Null

Write-Host "Enforcing Default Inbound Block policy across all profiles..."
Set-NetFirewallProfile -Profile Domain, Public, Private `
  -Enabled True `
  -DefaultInboundAction Block `
  -DefaultOutboundAction Allow `
  -NotifyOnListen False

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

Write-Host "Applying custom inbound rules..."

Ensure-FirewallRule -DisplayName "[WindowsInstaller] Allow mDNS (UDP-In)" -RuleDefinition @{
  DisplayName = "[WindowsInstaller] Allow mDNS (UDP-In)"
  Direction   = "Inbound"
  Action      = "Allow"
  Enabled     = "True"
  Protocol    = "UDP"
  LocalPort   = 5353
  Profile     = "Private"
}

Ensure-FirewallRule -DisplayName "[WindowsInstaller] Allow Wireless Display (TCP-In)" -RuleDefinition @{
  DisplayName = "[WindowsInstaller] Allow Wireless Display (TCP-In)"
  Direction   = "Inbound"
  Action      = "Allow"
  Enabled     = "True"
  Program     = "$env:SystemRoot\System32\WUDFHost.exe"
  Profile     = "Private"
}

Write-Host "Firewall reset to default state, default inbound block enforced, and custom rules configured."
