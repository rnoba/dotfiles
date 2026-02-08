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
	neovim
	xdg-settings
	p7zip
	unzip
	ntfs-3g
	exa
)

dev_run() {
	log_info "=== DEVELOPMENT TOOLS INSTALLATION ==="
	install_packages "${DEV_PACKAGES[@]}"
}
