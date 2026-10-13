#!/bin/sh
# vectorize-cli installer — auto-detects Linux/macOS and installs all deps.
# Usage: ./install.sh
set -eu

OS="$(uname -s)"
echo "Detected: $OS"

install_binaries() {
  case "$OS" in
    Darwin)
      echo "macOS: installing via Homebrew..."
      command -v brew >/dev/null 2>&1 || { echo "Homebrew required: https://brew.sh" >&2; exit 1; }
      brew install imagemagick potrace
      ;;
    Linux)
      if command -v apt >/dev/null 2>&1; then
        echo "Debian/Ubuntu: installing via apt..."
        sudo apt update && sudo apt install -y imagemagick potrace
      elif command -v pacman >/dev/null 2>&1; then
        echo "Arch/derivatives: installing via pacman..."
        sudo pacman -S --noconfirm --needed imagemagick potrace
      else
        echo "Unsupported distro. Install ImageMagick + potrace manually." >&2
        exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows (MSYS/Git Bash): install ImageMagick + potrace via winget/choco manually." >&2
      exit 1
      ;;
    *)
      echo "Unsupported OS: $OS" >&2; exit 1
      ;;
  esac
}

install_vtracer() {
  # vtracer (color tracing) — only in AUR on Arch; pip elsewhere.
  case "$OS" in
    Darwin)
      pip3 install --user vtracer || pip3 install vtracer
      ;;
    Linux)
      if command -v paru >/dev/null 2>&1; then
        echo "Installing vtracer via paru (AUR)..."
        paru -S --noconfirm vtracer-bin || paru -S --noconfirm vtracer
      elif command -v yay >/dev/null 2>&1; then
        echo "Installing vtracer via yay (AUR)..."
        yay -S --noconfirm vtracer-bin || yay -S --noconfirm vtracer
      else
        echo "Installing vtracer via pip..."
        pip install --user vtracer || pip install --break-system-packages vtracer
      fi
      ;;
    *)
      echo "Unsupported OS for vtracer: $OS" >&2; exit 1
      ;;
  esac
}

install_binaries
install_vtracer

echo "Done. Run:  vectorize image.png        (black SVG)"
echo "      or:  vectorize -c image.png     (color SVG, needs vtracer)"
