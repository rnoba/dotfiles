#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly EMAIL="130116482+rnoba@users.noreply.github.com"
readonly NAME="rnoba (Rafael)"
readonly DOTFILES_DIR="./config"

readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Some old/lazy programs ignore XDG and hardcode ~/.pki
# (old Chromium/Electron): https://chromium.googlesource.com/chromium/src/base/+/535b6a8e45ea7b23343488f2abd8068c1cc7548b/nss_init.cc
readonly PKI_HOME="$DATA_HOME/pki"

log_info()  { printf "%b[INFO]%b %s\n"  "$GREEN"  "$NC" "$1"; }
log_warn()  { printf "%b[WARN]%b %s\n"  "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED"    "$NC" "$1" >&2; }
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

try_run() {
	local desc="$1"; shift

	if ! command -v "$1" &>/dev/null; then
		log_warn "$desc skipped: '$1' not found"
		return 0
	fi

	if "$@"; then
		log_info "$desc"
	else
		log_warn "$desc failed (continuing)"
	fi
}

main() {
	log_info "Starting..."

	safe_copy "./.zshenv" "$HOME/.zshenv"
	[[ -e "$HOME/.zshenv" ]] && source "$HOME/.zshenv"

	mkdir -p "$CONFIG_HOME" "$DATA_HOME" "$STATE_HOME" "$HOME/.local/bin"
	mkdir -p "$STATE_HOME/history"
	mkdir -p "$PKI_HOME"

	log_info "Copying dotfiles..."
	safe_copy "./.Xsession" "$HOME/.Xsession"

	local -a copy_map=(
		"$DOTFILES_DIR/zsh:$CONFIG_HOME/zsh"
		"$DOTFILES_DIR/alacritty:$CONFIG_HOME/alacritty"
		"$DOTFILES_DIR/nvim:$CONFIG_HOME/nvim"
		"$DOTFILES_DIR/tmux:$CONFIG_HOME/tmux"
		"$DOTFILES_DIR/i3:$CONFIG_HOME/i3"
		"$DOTFILES_DIR/i3blocks:$CONFIG_HOME/i3blocks"
		"$DOTFILES_DIR/mozilla:$CONFIG_HOME/mozilla"
		"$DOTFILES_DIR/tmux-sessionizer:$CONFIG_HOME/tmux-sessionizer"
		"$DOTFILES_DIR/X11:$CONFIG_HOME/X11"
	)
	local pair src dst
	for pair in "${copy_map[@]}"; do
		src="${pair%%:*}"
		dst="${pair#*:}"
		safe_copy "$src" "$dst"
	done

	if [[ -d "$HOME/.pki" && ! -e "$PKI_HOME" ]]; then
		log_warn "Existing ~/.pki found, moving to XDG_DATA_HOME"
		mv "$HOME/.pki" "$PKI_HOME"
	fi

	safe_link "$PKI_HOME" "$HOME/.pki"

	local -a user_dirs=(
		"$HOME/Public/Garbage" "$HOME/Public/Lib" "$HOME/Public/Code"    "$HOME/Public/Apps"
		"$HOME/Downloads"      "$HOME/Documents"  "$HOME/Media/Pictures" "$HOME/Media/Videos"
    "$HOME/Lodge"
	)
	mkdir -p "${user_dirs[@]}"

	cat > "$CONFIG_HOME/user-dirs.dirs" <<'EOF'
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_PICTURES_DIR="$HOME/Media/Pictures"
XDG_VIDEOS_DIR="$HOME/Media/Videos"
XDG_MUSIC_DIR="$HOME/Public/Garbage"
XDG_TEMPLATES_DIR="$HOME/Public/Garbage"
XDG_DESKTOP_DIR="$HOME/Public/Garbage"
EOF

	try_run "Updated XDG user dirs" xdg-user-dirs-update
	try_run "Set Firefox as default browser" xdg-settings set default-web-browser firefox.desktop

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
