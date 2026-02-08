#!/usr/bin/env bash

MODULE_NAME="fonts"
MODULE_DESCRIPTION="Install fonts"
MODULE_DEPENDS=("base")

readonly FONT_PACKAGES=(
	noto-fonts-ttf
	noto-fonts-cjk
	noto-fonts-emoji
	nerd-fonts
)

fonts_run() {
	log_info "=== FONTS INSTALLATION ==="
	install_packages "${FONT_PACKAGES[@]}"
}
