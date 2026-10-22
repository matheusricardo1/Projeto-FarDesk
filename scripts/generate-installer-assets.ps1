param(
  [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$sourceIcon = Join-Path $RepoRoot "app_desktop\assets\branding\icon.png"
if (-not (Test-Path $sourceIcon)) {
  throw "Logo de origem não encontrada: $sourceIcon"
}

$outputDirectory = Join-Path $RepoRoot "build\installer-assets"
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

# Mesma paleta de `app_desktop/lib/core/design_system/tokens/colors.dart` —
# os bitmaps do instalador têm que combinar com o resto do app.
$background = [System.Drawing.Color]::FromArgb(0x0A, 0x0C, 0x10) # AppColors.background
$titleColor = [System.Drawing.Color]::FromArgb(0xF5, 0xF6, 0xFA) # AppColors.textPrimary

function New-WizardBitmap {
  param(
    [int]$Width,
    [int]$Height,
    [int]$LogoSize,
    [int]$LogoTop,
    [switch]$WithTitle,
    [string]$OutputPath
  )

  $source = [System.Drawing.Image]::FromFile($sourceIcon)
  $canvas = New-Object System.Drawing.Bitmap($Width, $Height)
  $graphics = [System.Drawing.Graphics]::FromImage($canvas)
  try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear($background)

    $logoX = [int](($Width - $LogoSize) / 2)
    $graphics.DrawImage($source, $logoX, $LogoTop, $LogoSize, $LogoSize)

    if ($WithTitle) {
      $font = New-Object System.Drawing.Font("Segoe UI", 17, [System.Drawing.FontStyle]::Bold)
      $brush = New-Object System.Drawing.SolidBrush($titleColor)
      try {
        $title = "FarDesk"
        $textSize = $graphics.MeasureString($title, $font)
        $textX = [single](($Width - $textSize.Width) / 2)
        $textY = [single]($LogoTop + $LogoSize + 18)
        $graphics.DrawString($title, $font, $brush, $textX, $textY)
      } finally {
        $brush.Dispose()
        $font.Dispose()
      }
    }
  } finally {
    $graphics.Dispose()
  }

  $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
  $canvas.Dispose()
  $source.Dispose()
}

# Banner vertical da página de boas-vindas/conclusão do instalador.
New-WizardBitmap -Width 164 -Height 314 -LogoSize 108 -LogoTop 56 -WithTitle `
  -OutputPath (Join-Path $outputDirectory "wizard-image.bmp")

# Logo pequena no canto superior direito das demais páginas do assistente.
New-WizardBitmap -Width 55 -Height 58 -LogoSize 46 -LogoTop 6 `
  -OutputPath (Join-Path $outputDirectory "wizard-small.bmp")

Write-Host "Assets visuais do instalador gerados em $outputDirectory"
