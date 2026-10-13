# vectorize-cli

raster → SVG from the command line. Single PNG in, SVG out. One tool, three platforms.

- `vectorize` — POSIX shell script (default: black vector via **potrace**)
- `vectorize.ps1` — native PowerShell port (PS 5.1 / 7, Windows) → `windows/vectorize.ps1`
- `vectorize.py` — Python variant with the same flags
- `install.sh` — Linux/macOS installer
- `install-vectorize.ps1` — Windows installer (user- or system-wide) → `windows/install-vectorize.ps1`

Repository layout:

```
install.sh              # Linux/macOS installer
vectorize               # POSIX shell script (black-path entry point)
vectorize.py
windows/
  install-vectorize.ps1 # Windows installer (uses $PSScriptRoot; run from here)
  vectorize.ps1         # PowerShell port
```

Flags (all variants):
- `-c` / `--color` — color tracing via **vtracer** (per-layer color regions)
- `-h` / `--help` — print usage

## Requirements

| Tool | Purpose |
|---|---|
| ImageMagick (`magick` v7+, `convert` fallback) | raster preprocessing (grayscale + threshold) |
| potrace | black-and-white vector tracing |
| vtracer *(optional, color only)* | per-layer color tracing |

## Install

Pick your OS.

### Linux or macOS

Run from the project directory:

```sh
./install.sh
```

`install.sh` auto-detects the environment:

- **macOS** → Homebrew (`brew install imagemagick potrace`) + vtracer via `pip`
- **Debian/Ubuntu** → `apt` for ImageMagick + potrace, vtracer via `pip`
- **Arch / derivatives** → `pacman` for ImageMagick + potrace, and `paru -S vtracer-bin` for vtracer (the AUR package; `pacman -S vtracer` is "target not found")

Install vtracer standalone (non-Arch):

```sh
pip install --user vtracer                         # preferred
pip install --user --break-system-packages vtracer # if PEP 668 blocks you
```

### Windows

Use **PowerShell 5.1 or 7** (works in Windows PowerShell, PowerShell 7, and Windows Terminal). From the project directory:

```powershell
# User scope — no admin required
.\install-vectorize.ps1

# Also bootstrap ImageMagick via winget; prints canonical commands for potrace/vtracer if missing
.\install-vectorize.ps1 -InstallDeps

# All users — run THIS shell as Administrator
.\install-vectorize.ps1 -Scope system
```

What it does:

1. Copies `vectorize.ps1` to `%LOCALAPPDATA%\Microsoft\WindowsApps` (already on user `PATH` on modern Windows).
2. Writes a `vectorize.bat` shim that prefers `pwsh` and falls back to `powershell`:
   ```bat
   @echo off
   set "PSCMD=pwsh"
   where pwsh >nul 2>&1 || set "PSCMD=powershell"
   %PSCMD% -NoProfile -ExecutionPolicy Bypass -File "%~dp0vectorize.ps1" %*
   ```
3. Adds the install dir to the right `PATH` only if missing (idempotent).
4. Runs a self-test (`vectorize -h`).

Install dependencies manually if you prefer:

```powershell
winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
winget install Potrace.Potrace -e
pip install --user vtracer
```

> A `.ps1` can't be run as `vectorize` directly — `.PS1` isn't in `PATHEXT`, and PowerShell won't launch a bare-name script from `PATH`. The `.bat` shim is what makes `vectorize` resolve in cmd, PowerShell, and Windows Terminal alike.

## Usage

Identical across shells; only the leading `.\`/`-File` prefix differs.

```sh
# Linux / macOS
vectorize logo.png              # black vector  -> logo.svg
vectorize logo.png out.svg      # custom output name
vectorize -c logo.png           # color vector  -> logo.svg  (needs vtracer)
```

```powershell
# Windows
vectorize logo.png              # black vector  -> logo.svg
vectorize logo.png out.svg      # custom output name
vectorize -c logo.png           # color vector  -> logo.svg  (needs vtracer)
```

Put any variant on your `PATH` manually (Linux/macOS example):

```sh
cp vectorize ~/.local/bin/ && chmod +x ~/.local/bin/vectorize
```

## Detail retention (e.g. shield interiors)

The black path (`potrace`) binarizes the grayscale image at a single threshold, so fine/thin strokes can vanish — notably interior shield lines.

**Option A — sharpen the black path:**

```sh
magick logo.png -flatten -grayscale Rec709Luminance -threshold 35% ppm:- \
  | potrace -s --turd-size 2 --turnpolicy=minor -o logo.svg
```

- `-threshold 35%` (vs default 50%) keeps thinner strokes black
- `--turd-size 2` keeps shapes down to 2 px (default 4 eats small strokes)
- `--turnpolicy=minor` fills the smaller side of a boundary — preserves interior detail

**Option B — color path (`-c`):**

Color tracing via vtracer keeps each color/luma region as a separate layer, so interior shield strokes survive inherently — no threshold tuning needed.

## License

MIT
