# vectorize-cli

raster → SVG from the command line. Single PNG in, SVG out. One tool, three platforms.

- `vectorize` — POSIX shell script (default: black vector via **potrace**)
- `vectorize` — POSIX shell script (default: black vector via **potrace**)
- `vectorize.bat` — pure Windows batch port (no Execution Policy issues) → `windows/vectorize.bat`
- `vectorize.py` — Python variant with the same flags
- `install.sh` — Linux/macOS installer
- `install-vectorize.bat` — Windows installer (user scope, `--deps` auto-bootstrap) → `windows/install-vectorize.bat`

Repository layout:

```
install.sh              # Linux/macOS installer
vectorize               # POSIX shell script (black-path entry point)
vectorize.py
windows/
  install-vectorize.bat # Windows installer (run from this folder)
  vectorize.bat         # Windows port (pure batch, CRLF line endings)
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

- **Installs the CLI itself** to `~/.local/bin/vectorize` (creates the folder, `chmod +x`; prints a PATH hint if the folder isn't on PATH yet — e.g. macOS doesn't have `~/.local/bin` on PATH by default)
- **Installs the runtime binaries**: ImageMagick + potrace via `brew` (apple Silicon/Intel), `apt` / `dnf` / `pacman` on Debian/Ubuntu, Fedora, Arch
- **vtracer** via `pip` (+ AUR `vtracer-bin` via `paru`/`yay` on Arch); failures here are warnings, not fatal — vtracer is only needed for `-c`
- Handles PEP 668 automatically (retries with `--break-system-packages` on Debian 12+/Fedora)
- macOS → Homebrew (`brew install imagemagick potrace`) + vtracer via `pip`
- Debian/Ubuntu → `apt` for ImageMagick + potrace, vtracer via `pip`
- Arch / derivatives → `pacman` for ImageMagick + potrace, and `paru -S vtracer-bin` for vtracer (the AUR package; `pacman -S vtracer` is "target not found")

Note: `install.sh` must be run from the repo folder (`./install.sh`); it resolves its own location before copying.

Install vtracer standalone (non-Arch):

```sh
pip install --user vtracer                         # preferred
pip install --user --break-system-packages vtracer # if PEP 668 blocks you
```

### Windows

Everything is plain **`.bat`** (cmd batch), so Windows' script execution policy / digital-signing restrictions never apply — the files run in cmd, PowerShell, and Windows Terminal alike. From the project directory:

```bat
:: User scope — no admin required. Installs for the current user.
.\install-vectorize.bat

:: Also bootstrap dependencies automatically:
::   ImageMagick + potrace via winget, vtracer via pip
.\install-vectorize.bat --deps

:: All users — run THIS terminal as Administrator
.\install-vectorize.bat --system
```

What it does:

1. Copies `vectorize.bat` to `%LOCALAPPDATA%\Microsoft\WindowsApps` — already on the user `PATH` on Windows 10/11, so no PATH edit is needed. If that folder is missing, it falls back to `%LOCALAPPDATA%\Programs\Vectorize` and adds it to the user PATH via the registry.
2. Registers a one-line `vectorize` command in the PowerShell profiles — Windows PowerShell 5.1 and PowerShell 7 (`pwsh`) when installed — the way bash installers append to `~/.bashrc`. It queries each shell's real `$PROFILE` (handles OneDrive-redirected Documents), skips if a shim already exists, and appends:

   ```powershell
   # >>> vectorize shim >>>
   $Global:VectorizeShim = 'C:\Users\you\AppData\Local\Microsoft\WindowsApps\vectorize.bat'
   function vectorize {
       & $Global:VectorizeShim @args
   }
   # <<< vectorize shim <<<
   ```

   So `vectorize logo.png` works in PowerShell exactly like in bash — no `.\`, no full path, independent of PATH staleness.
3. With `--deps`: installs missing dependencies via `winget` (ImageMagick, potrace) and `pip` (vtracer); prints manual instructions if `winget`/`pip` are unavailable.
4. Runs a self-test (`vectorize -h`).

Open a **new terminal** after installing; in an already-open PowerShell you can enable the command right away with `. $PROFILE`. Under strict execution policies (Restricted/AllSigned) profiles may not load — `vectorize` then still resolves via PATH in new terminals.

Uninstall later: delete the installed `vectorize.bat` (locations in step 1, or `%ProgramFiles%\Vectorize` for `--system`) and remove the `vectorize shim` block from each PowerShell profile.

> Why batch and not PowerShell? `.ps1` scripts downloaded from the internet are blocked by Windows' default execution policy ("... is not digitally signed") — exactly what happened to the previous `vectorize.ps1`. Batch files are unaffected.

Install dependencies manually if you prefer:

```bat
winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
winget install Potrace.Potrace -e
pip install --user vtracer
```

## Usage

Identical across shells; only the leading `.\` differs on Windows.

```sh
# Linux / macOS
vectorize logo.png              # black vector  -> logo.svg
vectorize logo.png out.svg      # custom output name
vectorize -c logo.png           # color vector  -> logo.svg  (needs vtracer)
```

```bat
:: Windows — after installing; in a terminal that started before the install
:: you can also run the file directly: .\<repo path>\windows\vectorize.bat
vectorize logo.png              :: black vector  -> logo.svg
vectorize logo.png out.svg      :: custom output name
vectorize -c logo.png           :: color vector  -> logo.svg  (needs vtracer)
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
