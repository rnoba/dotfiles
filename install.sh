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

PACKAGES=(
	exa
	speech-dispatcher
)

log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1"; }

backup_path() { mv "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"; }

install_nix() {
	if command -v nix &>/dev/null; then
		log_warn "Nix already installed, skipping"
		return 0
	fi
	
	log_info "Installing Nix package manager..."
	sh <(curl -L https://nixos.org/nix/install) --daemon --yes
	
	if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	fi
	
	log_info "Nix installed successfully"
	log_info "Enabling flakes and nix-command..."
	mkdir -p "$CONFIG_DIR/nix"
	cat > "$CONFIG_DIR/nix/nix.conf" <<-EOF
		experimental-features = nix-command flakes
	EOF
	log_info "Nix configured with flakes support"
}

install_packages() {
	local packages=("$@")
	log_info "Installing packages (${#packages[@]})..."
	sudo pacman -Sy --needed --noconfirm "${packages[@]}"
	log_info "Package installation complete"
}

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
	log_info "Starting Arch Linux post-installation setup..."
	
	mkdir -p "$CONFIG_DIR" "$DATA_DIR"
	
	log_info "Copying dotfiles..."
	safe_copy "./.zshenv" "$HOME/.zshenv"
	safe_copy "./zsh" "$CONFIG_DIR/zsh"
	safe_copy "./alacritty" "$CONFIG_DIR/alacritty"
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
		ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519"
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
	
	install_packages "${PACKAGES[@]}"
	install_nix
	
	if command -v zsh &>/dev/null && [[ "$SHELL" != "$(command -v zsh)" ]]; then
		log_info "Setting zsh as default shell..."
		chsh -s "$(command -v zsh)"
		log_info "Default shell changed to zsh (requires logout)"
	fi
	
	log_info "done..."
	log_info "Setup complete!"
	echo
	echo "Next steps:"
	echo "  1. Review backups (*.backup.*)"
	echo "  2. Add your SSH key to GitHub/GitLab:"
	echo "     ${GREEN}$(cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || echo "SSH key not generated")${NC}"
	echo "  3. Logout and login again to use zsh"
	echo "  4. Install AUR helper (yay/paru): git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
	echo "  5. Customize your configs in $CONFIG_DIR"
}

main "$@"
