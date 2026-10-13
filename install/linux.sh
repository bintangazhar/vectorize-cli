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
# vtracer (color tracing) — only in AUR, not official repos.
if command -v paru >/dev/null 2>&1; then
  paru -S --noconfirm vtracer-bin || paru -S --noconfirm vtracer
elif command -v yay >/dev/null 2>&1; then
  yay -S --noconfirm vtracer-bin || yay -S --noconfirm vtracer
else
  pip install --user vtracer || pip install --break-system-packages vtracer
fi
echo "Done. Usage: vectorize image.png   or   vectorize -c image.png"
