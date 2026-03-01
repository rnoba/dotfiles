#!/usr/bin/env bash

MODULE_NAME="dev"
MODULE_DESCRIPTION="Install development tools"
MODULE_DEPENDS=("base")

readonly DEV_PACKAGES=(
  base-devel
  gcc
  clang
  git
  curl
  direnv
  cmake
  fd
  luarocks
  rustup
  ripgrep
  fzf
  ffmpeg
  tmux
  p7zip
  unzip

  python-devel
  dbus-glib-devel
  libX11-devel
  libXfixes-devel
  libXext-devel
  SDL
  SDL-devel
  SDL2
  SDL2-devel
  SDL3
  SDL3-devel
)

dev_run() {
  log_info "=== DEVELOPMENT TOOLS INSTALLATION ==="
  install_packages "${DEV_PACKAGES[@]}"
}
