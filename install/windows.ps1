Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# ImageMagick
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id ImageMagick.ImageMagick --accept-package --accept-source-agreements
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install -y imagemagick
} else {
    Write-Host "Install ImageMagick manually: https://imagemagick.org"
}
# potrace
if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install -y potrace
} else {
    Write-Host "Install potrace manually (https://potrace.sourceforge.net) or via chocolatey"
}
# vtracer (color tracing)
pip install vtracer
Write-Host "Done. Usage: vectorize image.png   or   vectorize -c image.png"
