#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1"; }

readonly LIB_DIR=$HOME/Public/Lib
readonly BIN_DIR=$HOME/.local/bin

if [ ! -d "$LIB_DIR" ]; then log_error "No Lib directory ($LIB_DIR)."; exit 1; fi
if [ ! -d "$BIN_DIR" ]; then log_error "Bin directory ($BIN_DIR) does not exist."; exit 1; fi

pushd "$HOME/Public/Lib/"
	if [ ! -d ./SpotifyAdBlock ]; then
		log_error "SpotifyAdBlock must be cloned & builded manually (https://github.com/abba23/spotify-adblock as of 02/03/2026)"
		log_info "git clone https://github.com/abba23/spotify-adblock.git SpotifyAdBlock"
		exit 1
	fi

	if [ ! -e ./config.toml ]; then log_error "Could not find config.toml"; exit 1; fi
	if [ ! -e ./target/release/libspotifyadblock.so ]; then log_error "Could not find libspotifyadblock.so"; exit 1; fi
	if ! command -v nix >/dev/null 2>&1; then log_error "Nix not installed"; exit 1; fi

	cat > "./setup.nix" <<'EOF'
{ pkgs ? import <nixpkgs> {} }:

let
  adblock = pkgs.stdenv.mkDerivation {
    pname = "spotify-adblock";
    version = "local";
		srcLib    = ./target/release/libspotifyadblock.so;
		srcConfig = ./config.toml;
    dontUnpack = true;
    dontBuild  = true;
    installPhase = ''
      mkdir -p $out/lib
      cp $srcLib    $out/lib/spotify-adblock.so
      cp $srcConfig $out/lib/config.toml
    '';
  };
in

pkgs.writeShellScriptBin "spotify" ''
  #!/usr/bin/env bash
  set -euo pipefail
  AD_BLOCK_LIB="${adblock}/lib"
  export LD_PRELOAD="$AD_BLOCK_LIB/spotify-adblock.so"
  pushd "$AD_BLOCK_LIB" >/dev/null || {
    echo "Cannot pushd to $AD_BLOCK_LIB"
    exit 1
  }
  exec ${pkgs.spotify}/bin/spotify "$@" || exec ${pkgs.spotify}/bin/.spotify-wrapped "$@"
  popd >/dev/null
''
EOF

	if [ -e ./setup.nix ]; then
		nix-build ./setup.nix && ln -sf "$(realpath result)/bin/spotify" "$BIN_DIR/spotify"
	fi

popd
