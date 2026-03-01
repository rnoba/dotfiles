#!/usr/bin/env bash

MODULE_NAME="i3"
MODULE_DESCRIPTION="Install i3 window manager and tools"
MODULE_DEPENDS=("xorg")

readonly I3_PACKAGES=(
  i3
  i3blocks
  dmenu
)

i3_run() {
  log_info "=== I3 INSTALLATION ==="

  i3_install
}

i3_install() {
  log_info "Installing i3 packages..."
  install_packages "${I3_PACKAGES[@]}"
}
