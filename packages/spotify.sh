#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2; }

readonly LIB_DIR="$HOME/Public/Lib"
readonly BIN_DIR="$HOME/.local/bin"
readonly ADBLOCK_DIR="$LIB_DIR/SpotifyAdBlock"

if ! command -v nix >/dev/null 2>&1; then 
    log_error "Nix not installed"
    exit 1
fi

if [ ! -d "$LIB_DIR" ]; then 
    log_error "No Lib directory ($LIB_DIR)"
    exit 1
fi

if [ ! -d "$BIN_DIR" ]; then 
    log_error "Bin directory ($BIN_DIR) does not exist"
    exit 1
fi

if [ ! -d "$ADBLOCK_DIR" ]; then
    log_error "SpotifyAdBlock must be cloned & built manually"
    log_info "Repository: https://github.com/abba23/spotify-adblock (as of 02/03/2026)"
    log_info ""
    log_info "Setup commands:"
    log_info "  cd $LIB_DIR"
    log_info "  git clone https://github.com/abba23/spotify-adblock.git SpotifyAdBlock"
    log_info "  cd SpotifyAdBlock"
    log_info "  make"
    exit 1
fi

if [ ! -e "$ADBLOCK_DIR/config.toml" ]; then 
    log_error "Could not find config.toml in $ADBLOCK_DIR"
    exit 1
fi

if [ ! -e "$ADBLOCK_DIR/target/release/libspotifyadblock.so" ]; then 
    log_error "Could not find libspotifyadblock.so"
    log_error "Did you run 'make' in the SpotifyAdBlock directory?"
    exit 1
fi

pushd "$ADBLOCK_DIR" >/dev/null

log_info "Creating Nix expression for Spotify with ad-blocking..."

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
  set -euo pipefail
  
  AD_BLOCK_LIB="${adblock}/lib"
  export LD_PRELOAD="$AD_BLOCK_LIB/spotify-adblock.so"
  
  # Change to ad-block lib directory (config.toml must be in CWD)
  cd "$AD_BLOCK_LIB" || {
    echo "Error: Cannot cd to $AD_BLOCK_LIB" >&2
    exit 1
  }
  
  # Try different possible Spotify binary locations
  if [ -x "${pkgs.spotify}/bin/.spotify-wrapped" ]; then
      exec ${pkgs.spotify}/bin/.spotify-wrapped "$@"
  elif [ -x "${pkgs.spotify}/bin/spotify" ]; then
      exec ${pkgs.spotify}/bin/spotify "$@"
  else
      echo "Error: Spotify binary not found in ${pkgs.spotify}/bin/" >&2
      exit 1
  fi
''
EOF

log_info "Building Spotify wrapper with Nix..."
nix-build ./setup.nix

log_info "Installing to $BIN_DIR/spotify..."
ln -sf "$(realpath result)/bin/spotify" "$BIN_DIR/spotify"

popd >/dev/null

log_info "Spotify wrapper with ad-blocking installed successfully!"
log_info "Run: spotify"
