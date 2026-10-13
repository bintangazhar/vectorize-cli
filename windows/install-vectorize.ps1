<#
.SYNOPSIS
  Installs the `vectorize` raster→SVG CLI so `vectorize [-c] INPUT.png [OUT.svg]`
  is callable from cmd, PowerShell, and Windows Terminal — user- or system-wide.

.DESCRIPTION
  - Copies vectorize.ps1 to the install dir.
  - Writes a `vectorize.bat` shim (honored by PATHEXT; works in cmd + pwsh).
  - Ensures the install dir is on the right PATH (no admin for user scope).
  - -InstallDeps: best-effort dep bootstrap (ImageMagick; prints potrace/vtracer steps).

.NOTES
  Run an *elevated* prompt for -Scope system.

.EXAMPLE
  .\install-vectorize.ps1                 # user scope
  .\install-vectorize.ps1 -Scope system -InstallDeps
#>
[CmdletBinding()]
param(
  [ValidateSet('user', 'system')] [string] $Scope = 'user',
  [switch] $InstallDeps,
  [string] $SourceDir = $PSScriptRoot
)
$ErrorActionPreference = 'Stop'

if ($Scope -eq 'system') {
  $admin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $admin) { throw "System scope needs an elevated (Run as Administrator) shell." }
}

$src = Join-Path $SourceDir 'vectorize.ps1'
if (-not (Test-Path $src)) { throw "vectorize.ps1 not found in $SourceDir" }

$installDir = if ($Scope -eq 'user') {
  "$env:LOCALAPPDATA\Microsoft\WindowsApps"
} else {
  "$env:PROGRAMFILES\Vectorize"
}
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force }

Copy-Item -Path $src -Destination (Join-Path $installDir 'vectorize.ps1') -Force

# Cross-shell shim. PATHEXT includes .BAT so `vectorize` resolves in cmd/ps/pwsh.
# Prefer pwsh if present, fall back to Windows PowerShell 5.1.
$shim = Join-Path $installDir 'vectorize.bat'
@'
@echo off
set "PSCMD=pwsh"
where pwsh >nul 2>&1 || set "PSCMD=powershell"
%PSCMD% -NoProfile -ExecutionPolicy Bypass -File "%~dp0vectorize.ps1" %*
'@ | Set-Content -Path $shim -Encoding ASCII

# Make sure the install dir is on the right PATH (idempotent).
$target = if ($Scope -eq 'user') { [EnvironmentVariableTarget]::User } else { [EnvironmentVariableTarget]::Machine }
$paths = [Environment]::GetEnvironmentVariable('Path', $target) -split ';' | Where-Object { $_ }
if ($installDir -notin $paths) {
  [Environment]::SetEnvironmentVariable('Path', ($paths + $installDir) -join ';', $target)
  Write-Host "Added $installDir to $Scope PATH. Open a new shell for it to take effect."
} else {
  Write-Host "$installDir already on $Scope PATH."
}

if ($InstallDeps) {
  # ImageMagick (provides `magick` and `convert`).
  if (Get-Command magick -ErrorAction SilentlyContinue) {
    Write-Host "ImageMagick OK."
  } else {
    Write-Host "Installing ImageMagick via winget..."
    winget.exe install --id ImageMagick.ImageMagick --accept-source-agreements --accept-package-agreements -e
  }
  # potrace — best-effort; print canonical command regardless.
  if (Get-Command potrace -ErrorAction SilentlyContinue) {
    Write-Host "potrace OK."
  } else {
    Write-Host "potrace missing. Run: winget install Potrace.Potrace   (or)   choco install potrace"
  }
  # vtracer (color mode) — pip only.
  if (Get-Command vtracer -ErrorAction SilentlyContinue) {
    Write-Host "vtracer OK."
  } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host "Installing vtracer..."
    pip install --user vtracer
  } else {
    Write-Host "vtracer missing. Run: pip install --user vtracer"
  }
}

# Self-test: run the shim directly (bypasses PATH lookup) and check usage exits 0.
& $shim -h >$null 2>&1
if ($LASTEXITCODE -eq 0) { Write-Host "Self-test OK: vectorize -h" } else { Write-Warning "Self-test failed (LASTEXITCODE=$LASTEXITCODE)." }

Write-Host "Done. Usage: vectorize [-c|--color] INPUT.png [OUTPUT.svg]"
