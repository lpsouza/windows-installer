[CmdletBinding()]
param(
  [string]$ConfigurationPath = (Join-Path $PSScriptRoot "..\.config\configuration.winget"),
  [switch]$InstallModuleForAllUsers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-CommandExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-CommandExists -Name "winget")) {
  throw "winget is not available. Install App Installer from Microsoft Store and try again."
}

$resolvedConfigurationPath = (Resolve-Path -Path $ConfigurationPath -ErrorAction Stop).Path

$module = Get-Module -ListAvailable -Name "Microsoft.WinGet.DSC" | Sort-Object Version -Descending | Select-Object -First 1
if ($null -eq $module) {
  Write-Host "Microsoft.WinGet.DSC is not installed. Installing now..."

  $installParams = @{
    Name = "Microsoft.WinGet.DSC"
    Force = $true
    AllowClobber = $true
  }

  if ($InstallModuleForAllUsers) {
    $installParams["Scope"] = "AllUsers"
  } else {
    $installParams["Scope"] = "CurrentUser"
  }

  Install-Module @installParams
} else {
  Write-Host "Microsoft.WinGet.DSC already installed (version $($module.Version))."
}

$configureArgs = @(
  "configure"
  "-f"; $resolvedConfigurationPath
  "--accept-configuration-agreements"
)

winget @configureArgs

if ($LASTEXITCODE -ne 0) {
  throw "winget configure failed with exit code $LASTEXITCODE."
}

Write-Host "Winget configuration applied successfully."
