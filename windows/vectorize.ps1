<#
.SYNOPSIS
    vectorize - Raster (PNG) to SVG. Default: black vector (potrace).
    -Color: color layers (vtracer).

.DESCRIPTION
    Usage: vectorize [-c|--color] INPUT.png [OUTPUT.svg]

.PARAMETER Color
    Use vtracer (color layers) instead of potrace (black vector).

.PARAMETER Input
    Input image (png).

.PARAMETER Output
    Output svg. Defaults to INPUT.svg in the same directory.

.EXAMPLE
    .\vectorize.ps1 photo.png
    .\vectorize.ps1 -Color logo.png logo.svg
#>
[CmdletBinding()]
param(
    [Alias('c', 'color')][switch]$Color,
    [Alias('h', 'help')][switch]$Help,
    [Parameter(Mandatory, Position = 0)][string]$Input,
    [Parameter(Position = 1)][string]$Output
)

if ($Help) { Write-Host "Usage: vectorize [-c|--color] INPUT.png [OUTPUT.svg]"; exit 0 }
if (-not (Test-Path $Input)) { throw "input not found: $Input" }

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

$conv = if (Test-Command magick) { 'magick' } elseif (Test-Command convert) { 'convert' } else { $null }

if ($Color) {
    if (-not (Test-Command vtracer)) { throw "color tracing needs vtracer: pip install --user vtracer" }
    if (-not $Output) { $Output = [System.IO.Path]::ChangeExtension($Input, '.svg') }
    & vtracer --input $Input --output $Output --colormode color --mode spline
    Write-Host "→ $Output"; exit 0
}

# black-only path (default)
if (-not (Test-Command potrace)) { throw "potrace not found. Install potrace + ImageMagick (winget install potrace ImageMagick.ImageMagick)" }
if (-not $conv) { throw "ImageMagick not found (need convert/magick)" }
if (-not $Output) { $Output = [System.IO.Path]::ChangeExtension($Input, '.svg') }

$tmp = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName() + '.pgm')
try {
    $flattenArgs = @($Input, '-flatten', '-grayscale', 'Rec709Luminance', '-threshold', '50%', $tmp)
    & $conv @flattenArgs
    & potrace @($tmp, '-s', '-o', $Output)
    Write-Host "→ $Output"
}
finally {
    if (Test-Path $tmp) { Remove-Item $tmp -ErrorAction SilentlyContinue }
}
