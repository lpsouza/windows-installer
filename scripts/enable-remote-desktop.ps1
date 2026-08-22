Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  throw "This script must be run as Administrator."
}

$rdpRegistryPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
$rdpRegistryName = "fDenyTSConnections"
$currentValue = (Get-ItemProperty -Path $rdpRegistryPath -Name $rdpRegistryName).$rdpRegistryName

Set-ItemProperty -Path $rdpRegistryPath -Name $rdpRegistryName -Value 0

$rdpRuleName = "[WindowsInstaller] Allow Remote Desktop (TCP-In)"
$existingRule = Get-NetFirewallRule -DisplayName $rdpRuleName -ErrorAction SilentlyContinue
if ($null -eq $existingRule) {
  New-NetFirewallRule \
    -DisplayName $rdpRuleName \
    -Direction Inbound \
    -Action Allow \
    -Protocol TCP \
    -LocalPort 3389 \
    -Profile Private | Out-Null
} else {
  Set-NetFirewallRule -DisplayName $rdpRuleName -Enabled True -Profile Private | Out-Null
}

if ($currentValue -ne 0) {
  Restart-Service -Name "TermService" -Force
}

Write-Host "Remote Desktop is enabled and firewall rule is configured."
