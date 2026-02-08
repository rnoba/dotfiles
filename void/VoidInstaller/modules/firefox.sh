#!/usr/bin/env bash

MODULE_NAME="firefox"
MODULE_DESCRIPTION="Install and configure Firefox"
MODULE_DEPENDS=("base")

readonly FIREFOX_PACKAGES=(
	firefox
)

firefox_run() {
	log_info "=== FIREFOX CONFIGURATION ==="

	firefox_install
}

firefox_install() {
	log_info "Installing Firefox..."

	install_packages "${FIREFOX_PACKAGES[@]}"
}
