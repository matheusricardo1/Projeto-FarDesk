param(
  [string]$SourceDirectory = "",
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = if ($SourceDirectory) { $SourceDirectory } else { Join-Path $repoRoot "native\tailscale" }
$outputDir = Join-Path $repoRoot ".tools\tailscale\windows-x64"

if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
  throw "Go is required to build the official Tailscale Windows binaries."
}
if (-not (Test-Path (Join-Path $sourceDir "go.mod"))) {
  throw "The official Tailscale source is missing at $sourceDir."
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $sourceDir
try {
  $env:CGO_ENABLED = "1"
  go build -trimpath -ldflags="-s -w" -o (Join-Path $outputDir "tailscale.exe") ./cmd/tailscale
  if ($LASTEXITCODE -ne 0) { throw "tailscale.exe build failed." }
  go build -trimpath -ldflags="-s -w" -o (Join-Path $outputDir "tailscaled.exe") ./cmd/tailscaled
  if ($LASTEXITCODE -ne 0) { throw "tailscaled.exe build failed." }
}
finally {
  Pop-Location
}

Write-Host "Built embedded Tailscale binaries in $outputDir"
