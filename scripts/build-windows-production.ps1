param(
  [string]$Version = "1.0.0",
  [int]$BuildNumber = 1,
  [string]$BackendBaseUrl = "https://fardesk-api.vercel.app",
  [switch]$SkipTailscaleBuild
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name, [string]$Message) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw $Message
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$appDirectory = Join-Path $repoRoot "app_desktop"
$releaseDirectory = Join-Path $appDirectory "build\windows\x64\runner\Release"
$tailscaleDirectory = Join-Path $repoRoot ".tools\tailscale\windows-x64"

Require-Command "flutter" "Flutter is required to build the Windows release."

if (-not $SkipTailscaleBuild) {
  Require-Command "go" "Go is required to build the bundled Tailscale runtime."
  & (Join-Path $PSScriptRoot "build-tailscale-windows.ps1")
  if ($LASTEXITCODE -ne 0) {
    throw "The bundled Tailscale runtime build failed."
  }
}

foreach ($binary in @("tailscale.exe", "tailscaled.exe")) {
  $path = Join-Path $tailscaleDirectory $binary
  if (-not (Test-Path $path)) {
    throw "Missing production network binary: $path"
  }
}

Push-Location $appDirectory
try {
  flutter build windows --release `
    --build-name $Version `
    --build-number $BuildNumber `
    --dart-define=APP_VERSION=$Version `
    --dart-define=BACKEND_BASE_URL=$BackendBaseUrl
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows release build failed."
  }
}
finally {
  Pop-Location
}

foreach ($required in @(
  (Join-Path $releaseDirectory "FarDesk.exe"),
  (Join-Path $releaseDirectory "network\tailscale.exe"),
  (Join-Path $releaseDirectory "network\tailscaled.exe"),
  (Join-Path $releaseDirectory "data\flutter_assets")
)) {
  if (-not (Test-Path $required)) {
    throw "The release bundle is incomplete: $required"
  }
}

$iscc = Get-Command iscc -ErrorAction SilentlyContinue
if ($null -eq $iscc) {
  $knownPaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 7\ISCC.exe",
    "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe",
    "${env:LOCALAPPDATA}\Programs\Inno Setup 7\ISCC.exe"
  )
  $isccPath = $knownPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($null -eq $isccPath) {
    throw "Inno Setup is required to create the single FarDesk-Setup.exe artifact."
  }
} else {
  $isccPath = $iscc.Source
}

$installerDirectory = Join-Path $repoRoot "build\installer"
New-Item -ItemType Directory -Force -Path $installerDirectory | Out-Null
& $isccPath "/DAppVersion=$Version" "/DAppBuild=$BuildNumber" "/O$installerDirectory" (Join-Path $repoRoot "scripts\FarDesk.iss")
if ($LASTEXITCODE -ne 0) {
  throw "FarDesk installer build failed."
}

Write-Host "Production installer created at $(Join-Path $installerDirectory 'FarDesk-Setup.exe')"
