#!/bin/sh
# vectorize-cli installer — deteksi OS/distro, skip jika sudah ada.
# Usage: ./install.sh
set -eu

have() { command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"
echo "Detected: $OS"

ensure_pip() {
  have pip3 && return 0
  have pip && return 0
  echo "-> pip belum ada, install pip..."
  case "$OS" in
    Darwin)
      brew install python || python3 -m ensurepip --user
      ;;
    Linux)
      if have apt; then
        sudo apt update && sudo apt install -y python3-pip
      elif have dnf; then
        sudo dnf install -y python3-pip
      elif have pacman; then
        sudo pacman -S --noconfirm --needed python-pip
      else
        python3 -m ensurepip --user
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      py -m ensurepip --default-pip || python -m ensurepip --default-pip
      ;;
  esac
}

install_binaries() {
  have magick || have convert || need_magick=1
  have potrace || need_potrace=1
  [ -z "${need_magick:-}${need_potrace:-}" ] && { echo "-> ImageMagick + potrace sudah ada (skip)"; return 0; }
  case "$OS" in
    Darwin)
      command -v brew >/dev/null || { echo "butuh Homebrew: https://brew.sh" >&2; exit 1; }
      brew install imagemagick potrace python
      ;;
    Linux)
      if have apt; then
        sudo apt update && sudo apt install -y imagemagick potrace
      elif have dnf; then
        sudo dnf install -y ImageMagick potrace
      elif have pacman; then
        sudo pacman -S --noconfirm --needed imagemagick potrace
      else
        echo "distro tak dikenal, install ImageMagick + potrace manual" >&2; exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows: winget install ImageMagick.ImageMagick; choco install potrace" >&2; exit 1
      ;;
  esac
}

install_vtracer() {
  have vtracer && { echo "-> vtracer sudah ada (skip)"; return 0; }
  ensure_pip
  PIP="pip3"; have pip3 || PIP="pip"
  case "$OS" in
    Linux)
      if have paru; then
        paru -S --noconfirm vtracer-bin || paru -S --noconfirm vtracer || $PIP install --user vtracer
      elif have yay; then
        yay -S --noconfirm vtracer-bin || yay -S --noconfirm vtracer || $PIP install --user vtracer
      elif have dnf; then
        $PIP install --user vtracer || sudo dnf install -y python3-pip && $PIP install --user vtracer
      else
        $PIP install --user vtracer
      fi
      ;;
    Darwin|MINGW*|MSYS*|CYGWIN*)
      $PIP install --user vtracer
      ;;
  esac
}

install_binaries
install_vtracer
echo "Done. vectorize image.png | vectorize -c image.png"
