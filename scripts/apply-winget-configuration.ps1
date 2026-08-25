[CmdletBinding(DefaultParameterSetName = "Default")]
param(
  [Parameter(Position = 0)]
  [string]$ConfigurationPath = (Join-Path $PSScriptRoot "..\.config\configuration.winget"),

  [Parameter(ParameterSetName = "Filtered")]
  [Alias("Name", "Id")]
  [string[]]$Package,

  [Parameter(ParameterSetName = "Interactive")]
  [Alias("Select")]
  [switch]$Interactive,

  [Parameter(ParameterSetName = "List")]
  [switch]$List,

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

function Get-WinGetConfigurationPackages {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $content = Get-Content -Path $Path -Raw -Encoding utf8

  $headerMatch = [regex]::Match($content, '(?s)^.*?(?=\r?\n\s{2,4}-\s+resource:)')
  $header = if ($headerMatch.Success) {
    $headerMatch.Value.TrimEnd()
  } else {
    "# yaml-language-server: `$schema=https://aka.ms/configuration-dsc-schema/0.2`nproperties:`n  configurationVersion: 0.2.0`n  resources:"
  }

  $resourceMatches = [regex]::Matches($content, '(?ms)(\s{2,4}-\s+resource:.*?)(?=(?:\r?\n\s{2,4}-\s+resource:)|\Z)')

  $packages = foreach ($match in $resourceMatches) {
    $block = $match.Value
    $id = if ($block -match '(?m)^\s*id:\s*([^\r\n#]+)') { $Matches[1].Trim() } else { "" }
    $desc = if ($block -match '(?m)^\s*description:\s*([^\r\n#]+)') { $Matches[1].Trim() } else { "" }
    $source = if ($block -match '(?m)^\s*source:\s*([^\r\n#]+)') { $Matches[1].Trim() } else { "" }

    [PSCustomObject]@{
      Id          = $id
      Description = $desc
      Source      = $source
      RawBlock    = $block
    }
  }

  return [PSCustomObject]@{
    Header   = $header
    Packages = $packages
  }
}

if (-not (Test-CommandExists -Name "winget")) {
  throw "winget is not available. Install App Installer from Microsoft Store and try again."
}

$resolvedConfigurationPath = (Resolve-Path -Path $ConfigurationPath -ErrorAction Stop).Path
$parsedConfig = Get-WinGetConfigurationPackages -Path $resolvedConfigurationPath
$availablePackages = $parsedConfig.Packages

if ($List) {
  Write-Host "Available packages in configuration ($($availablePackages.Count)):" -ForegroundColor Cyan
  for ($i = 0; $i -lt $availablePackages.Count; $i++) {
    $pkg = $availablePackages[$i]
    Write-Host (" [{0,2}] {1,-32} {2,-10} {3}" -f ($i + 1), $pkg.Id, "[$($pkg.Source)]", $pkg.Description)
  }
  return
}

$selectedPackages = @()

if ($Interactive) {
  $gridSucceeded = $false
  if (Test-CommandExists -Name "Out-GridView") {
    try {
      $gridSelection = $availablePackages |
        Select-Object @{Name = "Package ID"; Expression = { $_.Id } },
                      @{Name = "Source"; Expression = { $_.Source } },
                      @{Name = "Description"; Expression = { $_.Description } },
                      RawBlock |
        Out-GridView -Title "Select WinGet Packages to Install" -PassThru

      if ($null -ne $gridSelection -and $gridSelection.Count -gt 0) {
        $selectedPackages = foreach ($item in $gridSelection) {
          $availablePackages | Where-Object { $_.Id -eq $item.'Package ID' }
        }
        $gridSucceeded = $true
      } else {
        Write-Host "No packages selected. Exiting."
        return
      }
    } catch {
      $gridSucceeded = $false
    }
  }

  if (-not $gridSucceeded) {
    Write-Host "`nAvailable packages in configuration:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $availablePackages.Count; $i++) {
      $pkg = $availablePackages[$i]
      Write-Host (" [{0,2}] {1,-32} {2,-10} {3}" -f ($i + 1), $pkg.Id, "[$($pkg.Source)]", $pkg.Description)
    }

    Write-Host ""
    $inputSelection = Read-Host "Enter numbers separated by commas or ranges (e.g. 1, 3, 5-8), or 'all' to select everything"
    if ([string]::IsNullOrWhiteSpace($inputSelection) -or $inputSelection.Trim() -eq 'q') {
      Write-Host "Installation cancelled."
      return
    }

    if ($inputSelection.Trim() -eq 'all') {
      $selectedPackages = $availablePackages
    } else {
      $selectedIndices = [System.Collections.Generic.HashSet[int]]::new()
      $parts = $inputSelection -split ','
      foreach ($part in $parts) {
        $p = $part.Trim()
        if ($p -match '^(\d+)-(\d+)$') {
          $start = [int]$Matches[1]
          $end = [int]$Matches[2]
          for ($idx = $start; $idx -le $end; $idx++) {
            if ($idx -ge 1 -and $idx -le $availablePackages.Count) {
              [void]$selectedIndices.Add($idx - 1)
            }
          }
        } elseif ($p -match '^\d+$') {
          $idx = [int]$p
          if ($idx -ge 1 -and $idx -le $availablePackages.Count) {
            [void]$selectedIndices.Add($idx - 1)
          }
        }
      }

      $selectedPackages = foreach ($idx in $selectedIndices) {
        $availablePackages[$idx]
      }
    }
  }
} elseif ($PSBoundParameters.ContainsKey("Package") -and $Package.Count -gt 0) {
  $matchedList = [System.Collections.Generic.List[object]]::new()

  foreach ($pattern in $Package) {
    $wildcard = if ($pattern -notmatch '^\*|\*$') { "*$pattern*" } else { $pattern }
    $found = $availablePackages | Where-Object {
      $_.Id -like $wildcard -or
      $_.Description -like $wildcard -or
      $_.Id -eq $pattern
    }

    if ($null -ne $found) {
      foreach ($f in $found) {
        if (-not $matchedList.Contains($f)) {
          $matchedList.Add($f)
        }
      }
    } else {
      Write-Warning "No package found matching: '$pattern'"
    }
  }

  $selectedPackages = @($matchedList)
  if ($selectedPackages.Count -eq 0) {
    throw "No matching packages found for the specified pattern(s)."
  }
}

$module = Get-Module -ListAvailable -Name "Microsoft.WinGet.DSC" | Sort-Object Version -Descending | Select-Object -First 1
if ($null -eq $module) {
  Write-Host "Microsoft.WinGet.DSC is not installed. Installing now..."

  $installParams = @{
    Name         = "Microsoft.WinGet.DSC"
    Force        = $true
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

$targetConfigPath = $resolvedConfigurationPath
$tempConfigFile = $null

try {
  if ($selectedPackages.Count -gt 0 -and $selectedPackages.Count -lt $availablePackages.Count) {
    Write-Host "`nApplying configuration for $($selectedPackages.Count) selected package(s):" -ForegroundColor Cyan
    foreach ($p in $selectedPackages) {
      Write-Host " - $($p.Id) ($($p.Description))"
    }

    $tempConfigYaml = $parsedConfig.Header + "`n" + ($selectedPackages.RawBlock -join "`n`n") + "`n"
    $tempConfigFile = Join-Path ([System.IO.Path]::GetTempPath()) ("winget-config-" + [System.Guid]::NewGuid().ToString("N") + ".winget")
    Set-Content -Path $tempConfigFile -Value $tempConfigYaml -Encoding utf8
    $targetConfigPath = $tempConfigFile
  }

  $configureArgs = @(
    "configure"
    "-f"; $targetConfigPath
    "--accept-configuration-agreements"
  )

  winget @configureArgs

  if ($LASTEXITCODE -ne 0) {
    throw "winget configure failed with exit code $LASTEXITCODE."
  }

  Write-Host "`nWinget configuration applied successfully." -ForegroundColor Green
} finally {
  if ($null -ne $tempConfigFile -and (Test-Path -Path $tempConfigFile)) {
    Remove-Item -Path $tempConfigFile -Force -ErrorAction SilentlyContinue
  }
}
