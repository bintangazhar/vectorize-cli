#!/bin/sh
set -e
# Linux: ImageMagick + potrace (black tracing) + vtracer (color tracing).
if command -v apt >/dev/null 2>&1; then
  sudo apt update && sudo apt install -y imagemagick potrace
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed imagemagick potrace
else
  echo "Unsupported package manager. Install ImageMagick + potrace manually." >&2
  exit 1
fi
pip install --user vtracer   # --user avoids PEP 668; needed for -c color mode
echo "Done. Usage: vectorize image.png   or   vectorize -c image.png"
