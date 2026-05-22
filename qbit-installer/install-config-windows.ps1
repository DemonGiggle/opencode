param(
  [string]$ProviderID,
  [string]$ModelID,
  [string]$AppId = "ai.opencode.desktop",
  [string]$StorePath,
  [string]$ConfigTargetPath,
  [switch]$SkipGlobalConfig,
  [switch]$SkipDesktopModel
)

$ErrorActionPreference = "Stop"

function ConvertTo-Native($value) {
  if ($null -eq $value) {
    return $null
  }

  if ($value -is [string] -or $value -is [bool] -or $value -is [int] -or $value -is [long] -or $value -is [double]) {
    return $value
  }

  if ($value -is [System.Collections.IDictionary]) {
    $result = [ordered]@{}
    foreach ($key in $value.Keys) {
      $result[$key] = ConvertTo-Native $value[$key]
    }
    return $result
  }

  if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
    $items = @()
    foreach ($item in $value) {
      $items += ,(ConvertTo-Native $item)
    }
    return $items
  }

  if ($value.PSObject -and $value.PSObject.Properties) {
    $result = [ordered]@{}
    foreach ($property in $value.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-Native $property.Value
    }
    return $result
  }

  return $value
}

function Read-JsonMap([string]$path) {
  if (-not (Test-Path $path)) {
    return @{}
  }

  $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if (-not $raw.Trim()) {
    return @{}
  }

  return ConvertTo-Native (ConvertFrom-Json -InputObject $raw)
}

function Read-JsonStringMap([string]$raw) {
  if (-not $raw) {
    return @{}
  }

  return ConvertTo-Native (ConvertFrom-Json -InputObject $raw)
}

function Escape-JsonString([string]$value) {
  return $value.Replace("\", "\\").Replace('"', '\"')
}

function Install-GlobalConfig([string]$source, [string]$targetPath) {
  $configDir = Split-Path -Parent $targetPath
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
  Copy-Item -LiteralPath $source -Destination $targetPath -Force
  return $targetPath
}

$modelEntryPattern = '(?m)^\s*"model"\s*:\s*"((?:\\.|[^"\\])*)"'

$configPath = Join-Path $PSScriptRoot "opencode.json"
if (-not (Test-Path $configPath)) {
  Write-Error "Missing source config: $configPath"
}

$config = Read-JsonMap $configPath
$configInstalledPath = $null
if (-not $ConfigTargetPath) {
  $ConfigTargetPath = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"
}

if (-not $SkipGlobalConfig) {
  $configInstalledPath = Install-GlobalConfig $configPath $ConfigTargetPath
}

if ($SkipDesktopModel) {
  if ($configInstalledPath) {
    Write-Output "config=$configInstalledPath"
  }
  return
}

$providers = $config.provider
if (-not $providers -or $providers.Count -eq 0) {
  Write-Error "No providers found in $configPath"
}

if (-not $ProviderID -and $config.model -match '^([^/]+)/(.+)$') {
  $ProviderID = $matches[1]
}

if (-not $ModelID -and $config.model -match '^([^/]+)/(.+)$') {
  $ModelID = $matches[2]
}

if (-not $ProviderID) {
  $ProviderID = $providers.Keys | Select-Object -First 1
}

$provider = $providers[$ProviderID]
if (-not $provider) {
  Write-Error "Provider '$ProviderID' not found in $configPath"
}

$providerModels = @()
if ($provider.models) {
  $providerModels = @($provider.models.Keys)
}

if (-not $ModelID) {
  $ModelID = $providerModels | Select-Object -First 1
}

if (-not $ModelID) {
  Write-Error "No model available for provider '$ProviderID'"
}

if (-not $StorePath) {
  $StorePath = Join-Path $env:APPDATA $AppId
  $StorePath = Join-Path $StorePath "opencode.global.dat"
}

$storeDir = Split-Path -Parent $StorePath
New-Item -ItemType Directory -Path $storeDir -Force | Out-Null

$storeRaw = if (Test-Path $StorePath) {
  [System.IO.File]::ReadAllText($StorePath, [System.Text.Encoding]::UTF8)
} else {
  "{}"
}

$existingModel = @{
  user = @()
  recent = @()
  variant = @{}
}

if ($storeRaw -match $modelEntryPattern) {
  $currentModelRaw = [regex]::Unescape($matches[1])
  $parsed = Read-JsonStringMap $currentModelRaw
  if ($parsed) {
    if ($parsed.user) {
      $existingModel.user = @($parsed.user)
    }
    if ($parsed.recent) {
      $existingModel.recent = @($parsed.recent)
    }
    if ($parsed.variant) {
      $existingModel.variant = $parsed.variant
    }
  }
}

$visible = if ($providerModels.Count -gt 0) {
  @($providerModels | ForEach-Object {
      @{
        providerID = $ProviderID
        modelID = $_
        visibility = "show"
      }
    })
} else {
  @(
    @{
      providerID = $ProviderID
      modelID = $ModelID
      visibility = "show"
    }
  )
}

$keepUser = @($existingModel.user | Where-Object {
    $_.providerID -ne $ProviderID
  })

$keepRecent = @($existingModel.recent | Where-Object {
    -not ($_.providerID -eq $ProviderID -and $_.modelID -eq $ModelID)
  })

$recent = @(
  @{
    providerID = $ProviderID
    modelID = $ModelID
  }
) + $keepRecent

if ($recent.Count -gt 5) {
  $recent = @($recent[0..4])
}

$modelStore = @{
  user = $keepUser + $visible
  recent = $recent
  variant = $existingModel.variant
}

$modelJson = $modelStore | ConvertTo-Json -Depth 100 -Compress
$escapedModelJson = Escape-JsonString $modelJson
$newModelEntry = '"model": "' + $escapedModelJson + '"'

$nextStoreRaw = if ($storeRaw -match $modelEntryPattern) {
  [regex]::Replace($storeRaw, $modelEntryPattern, "  $newModelEntry", 1)
} elseif ($storeRaw.Trim() -eq "{}") {
  "{`n  $newModelEntry`n}"
} else {
  [regex]::Replace($storeRaw, '}\s*$', ",`n  $newModelEntry`n}")
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($StorePath, $nextStoreRaw, $utf8NoBom)

if ($configInstalledPath) {
  Write-Output "config=$configInstalledPath"
}
Write-Output "desktop-model-store=$StorePath"
