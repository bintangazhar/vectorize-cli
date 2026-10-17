#!/bin/sh
# vectorize-cli installer — deteksi OS/distro, skip jika sudah ada.
# Usage: ./install.sh
set -eu

have() { command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"
echo "Detected: $OS"

cd "$(dirname "$0")"   # jalankan dari folder repo supaya `cp vectorize` selalu ketemu

SUDO=sudo
[ "$(id -u)" = 0 ] && SUDO=""

pick_pip() {
  PIP="pip3"; have pip3 && return 0
  PIP="pip"; have pip && return 0
  echo "-> pip belum ada, install pip..."
  case "$OS" in
    Darwin)
      brew install python || python3 -m ensurepip --user
      ;;
    Linux)
      if have apt; then
        $SUDO apt update && $SUDO apt install -y python3-pip
      elif have dnf; then
        $SUDO dnf install -y python3-pip
      elif have pacman; then
        $SUDO pacman -S --noconfirm --needed python-pip
      else
        python3 -m ensurepip --user
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      py -m ensurepip --default-pip || python -m ensurepip --default-pip
      ;;
  esac
  PIP="pip3"; have pip3 && return 0
  PIP="pip"; have pip && return 0
  return 1
}

pip_install() {
  # $1 = bin pip, $2 = paket. Debian 12+/Fedora menolak pip --user (PEP 668),
  # jadi ulangi dengan --break-system-packages sebelum menyerah.
  "$1" install --user "$2" && return 0
  "$1" install --user --break-system-packages "$2" && return 0
  echo "pip gagal install $2 (PEP 668?). coba manual: $1 install --user --break-system-packages $2" >&2
  return 1
}

install_binaries() {
  have magick || have convert || need_magick=1
  have potrace || need_potrace=1
  [ -z "${need_magick:-}${need_potrace:-}" ] && { echo "-> ImageMagick + potrace sudah ada (skip)"; return 0; }
  case "$OS" in
    Darwin)
      if ! have brew; then
        echo "Homebrew tidak ada; install manual lalu jalankan ulang installer ini:" >&2
        echo "  https://brew.sh  ->  brew install imagemagick potrace" >&2
        return 0
      fi
      brew install imagemagick potrace python || echo "-> brew gagal; install manual: brew install imagemagick potrace" >&2
      ;;
    Linux)
      if have apt; then
        $SUDO apt update && $SUDO apt install -y imagemagick potrace || echo "-> apt gagal; manual: $SUDO apt install imagemagick potrace" >&2
      elif have dnf; then
        $SUDO dnf install -y ImageMagick potrace || echo "-> dnf gagal; manual: $SUDO dnf install ImageMagick potrace" >&2
      elif have pacman; then
        $SUDO pacman -S --noconfirm --needed imagemagick potrace || echo "-> pacman gagal; manual: sudo pacman -S imagemagick potrace" >&2
      else
        echo "distro tak dikenal, install ImageMagick + potrace manual. tool tetap dipasang ke ~/.local/bin" >&2
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows: jalankan windows\\install-vectorize.bat --deps (winget + pip otomatis)" >&2
      return 0
      ;;
  esac
}

try_vtracer_pip() {
  if ! pip_install "$PIP" vtracer; then
    echo "-> vtracer tidak terpasang; mode -c butuh dia. manual: pip install --user vtracer" >&2
  fi
}

install_vtracer() {
  have vtracer && { echo "-> vtracer sudah ada (skip)"; return 0; }
  if ! pick_pip; then
    echo "-> pip tidak ketemu; lewati vtracer (mode -c butuh dia)" >&2
    return 0
  fi
  if [ "$OS" = Linux ] && have paru; then
    if ! paru -S --noconfirm vtracer-bin; then
      if ! paru -S --noconfirm vtracer; then
        try_vtracer_pip
      fi
    fi
  elif [ "$OS" = Linux ] && have yay; then
    if ! yay -S --noconfirm vtracer-bin; then
      if ! yay -S --noconfirm vtracer; then
        try_vtracer_pip
      fi
    fi
  else
    try_vtracer_pip
  fi
}

install_binaries
install_vtracer

BIN="$HOME/.local/bin"
mkdir -p "$BIN"
cp vectorize "$BIN/vectorize"
chmod +x "$BIN/vectorize"
echo "-> vectorize terpasang di $BIN/vectorize"

# bash-parity: pastikan `vectorize` bisa dipanggil satu baris dari shell baru.
case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    SHELL_RC="rc"
    case "${SHELL:-}" in
      */zsh) SHELL_RC="zshrc" ;;
      */bash) SHELL_RC="bashrc" ;;
    esac
    echo "CATATAN: $BIN belum ada di PATH. tambahkan, mis:"
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/$SHELL_RC"
    ;;
esac

echo "Done."
