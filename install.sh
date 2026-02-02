#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
FIREFOX_CONFIG="$CONFIG_DIR/mozilla"
EMAIL="rnoba.iwb@gmail.com"
NAME="rnoba (Rafael Barros)"

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

setup_nix() {
	mkdir -p "$HOME/.local/share/nix"
	sudo xbps-install -Sy nix
	sudo ln -s /etc/sv /var/service
	sudo cp ./nix.sh /etc/profile.d/nix.sh

	nix-channel --add http://nixos.org/channels/nixpkgs-unstable
	nix-channel --update
}

main() {
	log_info "Starting Arch Linux post-installation setup..."
	
	mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$FIREFOX_CONFIG"
	
	log_info "Copying dotfiles..."
	safe_copy "./.zshenv" "$HOME/.zshenv"
	if [[ -e "$HOME/.zshenv" ]]; then
		source "$HOME/.zshenv"
	fi

	safe_copy "./zsh" "$CONFIG_DIR/zsh"
	safe_copy "./alacritty" "$CONFIG_DIR/alacritty"
	safe_copy "./nvim" "$CONFIG_DIR/nvim"
	safe_copy "./tmux" "$CONFIG_DIR/tmux"
	safe_copy "./i3" "$CONFIG_DIR/i3"
	safe_copy "./i3blocks" "$CONFIG_DIR/i3blocks"
	
	log_info "Configuring Firefox..."
	if [[ -d "$HOME/.mozilla" && ! -e "$FIREFOX_CONFIG" ]]; then
		log_warn "Existing ~/.mozilla found, moving to XDG config"
		mv "$HOME/.mozilla" "$FIREFOX_CONFIG"
	fi
	if [[ -d "$FIREFOX_CONFIG" ]]; then
		safe_link "$FIREFOX_CONFIG" "$HOME/.mozilla"
	else
		log_warn "Firefox config not found; skipping"
	fi
	
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
