$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $PSScriptRoot "windows"

New-Item -ItemType Directory -Path $target -Force | Out-Null

$legacyFiles = @("opencode.exe", "opencode-cli.exe", "OpenCode.exe")
foreach ($legacy in $legacyFiles) {
  $legacyPath = Join-Path $target $legacy
  if (Test-Path $legacyPath) {
    Remove-Item -LiteralPath $legacyPath -Force -ErrorAction SilentlyContinue
  }
}

$files = @(
  @{
    source = "packages\opencode\dist\opencode-windows-x64-baseline\bin\opencode.exe"
    name = "opencode-cli-build.exe"
  },
  @{
    source = "packages\desktop\src-tauri\sidecars\opencode-cli-x86_64-pc-windows-msvc.exe"
    name = "opencode-cli-x86_64-pc-windows-msvc.exe"
  },
  @{
    source = "packages\desktop\src-tauri\target\x86_64-pc-windows-msvc\release\OpenCode.exe"
    name = "OpenCode-desktop.exe"
  }
)

foreach ($file in $files) {
  $source = Join-Path $root $file.source
  $destination = Join-Path $target $file.name
  if (-not (Test-Path $source)) {
    Write-Error "Missing build artifact: $source"
  }

  if (Test-Path $destination) {
    $sourceItem = Get-Item -LiteralPath $source
    $destinationItem = Get-Item -LiteralPath $destination
    if ($sourceItem.Length -eq $destinationItem.Length) {
      continue
    }
  }

  Copy-Item -LiteralPath $source -Destination $destination -Force
}

$bundleDir = Join-Path $root "packages\desktop\src-tauri\target\x86_64-pc-windows-msvc\release\bundle\nsis"
if (Test-Path $bundleDir) {
  Get-ChildItem -LiteralPath $bundleDir -File -Filter *.exe | ForEach-Object {
    $destination = Join-Path $target $_.Name
    if (Test-Path $destination) {
      $destinationItem = Get-Item -LiteralPath $destination
      if ($_.Length -eq $destinationItem.Length) {
        return
      }
    }

    Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
  }
}

Write-Output $target
