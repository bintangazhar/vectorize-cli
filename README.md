# Vectorize Image Shell Script

Turn PNG logos into clean SVG vectors from the command line.

- `vectorize` — POSIX shell script
- `vectorize.py` — Python fallback with the same flags
- `install/` — Linux / macOS / Windows installers
- `-c` flag — color tracing (requires `vtracer`)

## Requirements

| Tool | Purpose |
|---|---|
| **ImageMagick** (`magick` v7, `convert` fallback) | PNG preprocessing |
| **potrace** | black-and-white tracing |
| **vtracer** *(optional, color only)* | per-layer color tracing |

## Install

### Linux
```sh
sh install/linux.sh
```

### macOS
```sh
bash install/macos.sh
```

### Windows (PowerShell)
```powershell
.\install\windows.ps1
```
Then ensure ImageMagick, potrace, and `vtracer` are on `%PATH%`.

Install vtracer alone:
```sh
pip install --user vtracer
```
(`--user` sidesteps PEP 668 restrictions.)

## Usage

```sh
vectorize logo.png            # black vector -> logo.svg
vectorize logo.png out.svg    # custom output
vectorize -c logo.png         # color vector (needs vtracer)
```

## Detail retention (e.g. shield interiors)

The default black path binarizes grayscale at a single threshold, so fine/stroke
and mid-tone edges can vanish. If detail drops out:

```sh
# Sharper binarization + lower turd floor + fill-rule that keeps interior strokes
magick logo.png -flatten -grayscale Rec709Luminance -threshold 35% ppm:- \
  | potrace -s --turd-size 2 --turnpolicy=minor -o logo.svg
```

- `-threshold 35%` — lower than default 50% keeps thinner strokes black
- `--turd-size 2` — keep shapes down to 2 px (default 4 eats small strokes)
- `--turnpolicy=minor` — fill the smaller side of a boundary (preserves interior detail)

Color mode (`-c`) recovers this structurally — each color/luma region becomes a
layer, so interior strokes survive regardless of a single threshold.

## License

MIT
