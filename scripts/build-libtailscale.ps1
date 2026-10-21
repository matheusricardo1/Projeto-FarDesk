param(
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "native\libtailscale"
$outputDir = Join-Path $repoRoot ".tools\libtailscale\windows-x64"

if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
  throw "Go is required to build libtailscale. Install the version declared by native\libtailscale\go.mod."
}

if (-not (Test-Path (Join-Path $sourceDir "go.mod"))) {
  throw "The libtailscale submodule is not initialized at $sourceDir."
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $sourceDir
try {
  $env:CGO_ENABLED = "1"
  go build -buildmode=c-shared -trimpath `
    -ldflags="-s -w" `
    -o (Join-Path $outputDir "libtailscale.dll")
  if ($LASTEXITCODE -ne 0) {
    throw "libtailscale.dll build failed."
  }
}
finally {
  Pop-Location
}

Write-Host "Built libtailscale.dll in $outputDir"
