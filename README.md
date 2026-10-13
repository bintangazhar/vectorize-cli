# vectorize-cli

PNG → SVG from the command line.

- `vectorize` — POSIX shell script (default: black vector via potrace)
- `vectorize.py` — Python variant with the same flags
- `install.sh` — one installer that auto-detects Linux/macOS
- `-c` / `--color` — color tracing (requires `vtracer` / `paru -S vtracer-bin`)

## Requirements

| Tool | Purpose |
|---|---|
| ImageMagick (`magick` v7, `convert` fallback) | PNG preprocessing |
| potrace | black-and-white tracing |
| vtracer *(optional, color only)* | per-layer color tracing — Arch AUR: `vtracer-bin` |

## Install

Linux or macOS — run from the project directory:

```sh
./install.sh
```

`install.sh` detects your environment:
- **macOS** → Homebrew (`brew install imagemagick potrace`) + vtracer via pip
- **Debian/Ubuntu** → `apt` for ImageMagick + potrace, vtracer via pip
- **Arch / derivatives** → `pacman` for ImageMagick + potrace, and `paru -S vtracer-bin` for vtracer

> On Arch, `vtracer` lives only in the AUR (not official repos), so `pacman -S vtracer` gives `target not found`. `install.sh` uses `paru -S vtracer-bin` automatically.  
> Color tracing alone: `paru -S vtracer-bin`

Install vtracer standalone (non-Arch):
```sh
pip install --user vtracer   # avoids PEP 668 on most distros
# if still blocked:
pip install --user --break-system-packages vtracer
```

## Usage

```sh
vectorize logo.png              # black vector  -> logo.svg
vectorize logo.png out.svg      # custom output name
vectorize -c logo.png           # color vector  -> logo.svg  (needs vtracer)
```

Both `vectorize` (shell) and `vectorize.py` support the same flags. Put the script on your `PATH`:
```sh
cp vectorize ~/.local/bin/ && chmod +x ~/.local/bin/vectorize
```

## Detail retention (e.g. shield interiors)

The black path (`potrace`) binarizes the grayscale image at a single threshold, so fine/thin strokes can vanish — notably interior shield lines. Two options:

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
