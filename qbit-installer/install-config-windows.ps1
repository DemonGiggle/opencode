$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "opencode.json"
if (-not (Test-Path $source)) {
  Write-Error "Missing source config: $source"
}

$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$target = Join-Path $configDir "opencode.json"

New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $target -Force

Write-Output $target
