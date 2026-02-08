#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'
readonly BIN_DIR="$HOME/.local/bin"

log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2; }
log_info()  { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }

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
pkgs.writeShellScriptBin "nixd" ''
#!/usr/bin/env bash

set -euo pipefail
if [ -x "${pkgs.nixd}/bin/.nixd-wrapped" ]; then
		exec ${pkgs.nixd}/bin/.nixd-wrapped "$@"
	elif [ -x "${pkgs.nixd}/bin/nixd" ]; then
		exec ${pkgs.nixd}/bin/nixd "$@"
	else
		echo "Error: Binary not found in ${pkgs.nixd}/bin/" >&2
		exit 1
fi
''
EOF

log_info "Building wrapper with Nix..."
nix-build ./setup.nix

log_info "Installing to $BIN_DIR/nixd..."
ln -sf "$(realpath result)/bin/nixd" "$BIN_DIR/nixd"

popd >/dev/null

log_info "Wrapper installed successfully!"
