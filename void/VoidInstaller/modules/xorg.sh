#!/usr/bin/env bash

MODULE_NAME="xorg"
MODULE_DESCRIPTION="Install Xorg display server"
MODULE_DEPENDS=("base")

readonly XORG_PACKAGES=(
	xorg
	xorg-server
	xclip
)

xorg_run() {
	log_info "=== XORG INSTALLATION ==="

	xorg_install
}

xorg_install() {
	log_info "Installing Xorg packages..."

	install_packages "${XORG_PACKAGES[@]}"
}
