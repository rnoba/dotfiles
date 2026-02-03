#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'
readonly BIN_DIR="$HOME/.local/bin"

log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2; }  # Added >&2
log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }

if ! command -v nix >/dev/null 2>&1; then 
	log_error "Nix not installed"
	exit 1
fi

if [ ! -d "$BIN_DIR" ]; then 
	log_error "Bin directory ($BIN_DIR) does not exist."
	exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

pushd "$TEMP_DIR" >/dev/null

cat > "./setup.nix" <<'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.writeShellScriptBin "discord" ''
#!/usr/bin/env bash
set -euo pipefail
if [ -x "${pkgs.discord}/bin/.discord-wrapped" ]; then
		exec ${pkgs.discord}/bin/.discord-wrapped "$@"
	elif [ -x "${pkgs.discord}/bin/discord" ]; then
		exec ${pkgs.discord}/bin/discord "$@"
	elif [ -x "${pkgs.discord}/bin/Discord" ]; then
		exec ${pkgs.discord}/bin/Discord "$@"
	else
		echo "Error: Discord binary not found in ${pkgs.discord}/bin/" >&2
		exit 1
fi
''
EOF

log_info "Building Discord wrapper with Nix..."
nix-build ./setup.nix

log_info "Installing to $BIN_DIR/discord..."
ln -sf "$(realpath result)/bin/discord" "$BIN_DIR/discord"

popd >/dev/null

log_info "Discord wrapper installed successfully!"
