#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly EMAIL="rnoba.iwb@gmail.com"
readonly NAME="rnoba (Rafael Barros)"

readonly DOTFILES_DIR="./config"

readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# It seems that firefox respects XDG specs now
# readonly MOZILLA_HOME="$DATA_HOME/mozilla"

# Stupid programs that does not respect XDG directory specs
# $HOME/.pki - Normally created by Chromium
# https://chromium.googlesource.com/chromium/src/base/+/535b6a8e45ea7b23343488f2abd8068c1cc7548b/nss_init.cc
readonly PKI_HOME="$DATA_HOME/pki"

#
readonly NV_HOME="$DATA_HOME/nv"

log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1"; }

backup_path() { mv "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"; }

safe_copy() {
	local src="$1" dst="$2"

	[[ -e "$src" ]] || { log_warn "Missing $src (skipping)"; return 0; }

	if [[ -e "$dst" ]]; then
		log_warn "Destination exists: $dst (backing up)"
		backup_path "$dst"
	fi

	cp -a "$src" "$dst"
	log_info "Copied: $src -> $dst"
}

safe_link() {
	local src="$1" dst="$2"
	[[ -e "$src" ]] || { log_warn "Missing $src (skipping)"; return 0; }

	if [[ -L "$dst" || -e "$dst" ]]; then
		log_warn "Backing up $dst"
		backup_path "$dst"
	fi

	ln -s "$src" "$dst"
	log_info "Linked $dst -> $src"
}


main() {
	log_info "Starting..."
	mkdir -p "$CONFIG_HOME" "$DATA_HOME" "$STATE_HOME" "$HOME/.local/bin"
	mkdir -p "$STATE_HOME/history"
	mkdir -p "$PKI_HOME" "$NV_HOME"
	
	log_info "Copying dotfiles..."

	safe_copy "./.zshenv" "$HOME/.zshenv"
	safe_copy "./.Xsession" "$HOME/.Xsession"

	if [[ -e "$HOME/.zshenv" ]]; then
		source "$HOME/.zshenv"
	fi

	safe_copy "$DOTFILES_DIR/zsh" "$CONFIG_HOME/zsh"
	safe_copy "$DOTFILES_DIR/alacritty" "$CONFIG_HOME/alacritty"
	safe_copy "$DOTFILES_DIR/nvim" "$CONFIG_HOME/nvim"
	safe_copy "$DOTFILES_DIR/tmux" "$CONFIG_HOME/tmux"
	safe_copy "$DOTFILES_DIR/i3" "$CONFIG_HOME/i3"
	safe_copy "$DOTFILES_DIR/i3blocks" "$CONFIG_HOME/i3blocks"
	safe_copy "$DOTFILES_DIR/mozilla" "$CONFIG_HOME/mozilla"
	safe_copy "$DOTFILES_DIR/tmux-sessionizer" "$CONFIG_HOME/tmux-sessionizer"
	safe_copy "$DOTFILES_DIR/X11" "$CONFIG_HOME/X11"
	
	if [[ -d "$HOME/.pki" && ! -e "$PKI_HOME" ]]; then
		log_warn "Existing ~/.pki found, moving to XDG_DATA_HOME"
		mv "$HOME/.pki" "$PKI_HOME"
	fi

	if [[ -d "$HOME/.nv" && ! -e "$NV_HOME" ]]; then
		log_warn "Existing ~/.nv found, moving to XDG_DATA_HOME"
		mv "$HOME/.nv" "$NV_HOME"
	fi

	safe_link "$PKI_HOME" "$HOME/.pki"
	safe_link "$NV_HOME" "$HOME/.nv"
	
	log_info "Configuring SSH..."

	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"

	if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
		log_info "Generating SSH key..."
		ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519" -N ''

		chmod 600 "$HOME/.ssh/id_ed25519"
		chmod 644 "$HOME/.ssh/id_ed25519.pub"

		log_info "SSH public key:"
		cat "$HOME/.ssh/id_ed25519.pub"
	else
		log_warn "SSH key already exists at ~/.ssh/id_ed25519"
	fi
	
	mkdir -p "$HOME/Public/Garbage" "$HOME/Public/Lib" "$HOME/Public/Code" "$HOME/Public/Apps" "$HOME/Downloads" "$HOME/Documents" "$HOME/Pictures" "$HOME/Lodge"

	cat > "$HOME/.config/user-dirs.dirs" <<'EOF'
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_MUSIC_DIR="$HOME/Public/Garbage"
XDG_VIDEOS_DIR="$HOME/Public/Garbage"
XDG_TEMPLATES_DIR="$HOME/Public/Garbage"
XDG_DESKTOP_DIR="$HOME/Public/Garbage"
EOF

	xdg-user-dirs-update

	log_info "Configuring Git..."
	git config --global user.email "$EMAIL"
	git config --global user.name "$NAME"
	git config --global init.defaultBranch main
	git config --global pull.rebase false
	git config --global core.editor "${EDITOR:-vim}"
	git config --global color.ui auto
	log_info "Git configured for $NAME <$EMAIL>"

	
	log_info "Done."
}

main "$@"
