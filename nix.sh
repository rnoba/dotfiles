#sync with https://github.com/NixOS/nix/blob/3be58fe1bc781fd39649f616c8ba4e5be672d505/scripts/nix-profile-daemon.sh.in

NIX_JUNK_PATH="$HOME/.local/share/nix"

NIX_PROFILE="$NIX_JUNK_PATH/profile"
NIX_CHANNELS="$NIX_JUNK_PATH/channels"
NIX_DEFEXPR="$NIX_JUNK_PATH/defexpr"

export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
export NIX_PROFILES="/nix/var/nix/profiles/default $NIX_PROFILE"

# Set up the per-user profile.
mkdir -m 0755 -p $NIX_USER_PROFILE_DIR
if ! test -O "$NIX_USER_PROFILE_DIR"; then
	echo "WARNING: bad ownership on $NIX_USER_PROFILE_DIR" >&2
fi

if test -w $HOME; then
	if ! test -L "$NIX_PROFILE"; then
		if test "$USER" != root; then
			ln -s $NIX_USER_PROFILE_DIR/profile "$NIX_PROFILE"
		else
			ln -s /nix/var/nix/profiles/default "$NIX_PROFILE"
		fi
	fi

	# Subscribe the root user to the NixOS channel by default.
	if [ "$USER" = root -a ! -e "$NIX_CHANNELS" ]; then
		echo "https://nixos.org/channels/nixpkgs-unstable nixpkgs" > "$NIX_CHANNELS"
	fi

	# Create the per-user garbage collector roots directory.
	NIX_USER_GCROOTS_DIR=/nix/var/nix/gcroots/per-user/$USER
	mkdir -m 0755 -p $NIX_USER_GCROOTS_DIR
	if ! test -O "$NIX_USER_GCROOTS_DIR"; then
		echo "WARNING: bad ownership on $NIX_USER_GCROOTS_DIR" >&2
	fi

	# Set up a default Nix expression from which to install stuff.
	if [ ! -e "$NIX_DEFEXPR" -o -L "$NIX_DEFEXPR" ]; then
		rm -f "$NIX_DEFEXPR"
	
		mkdir -p "$NIX_DEFEXPR"
		if [ "$USER" != root ]; then
			ln -s /nix/var/nix/profiles/per-user/root/channels "$NIX_DEFEXPR/channels_root"
		fi
	fi
fi

# Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
if [ ! -z "${NIX_SSL_CERT_FILE:-}" ]; then
    : # Allow users to override the NIX_SSL_CERT_FILE
elif [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
elif [ -e /etc/ssl/ca-bundle.pem ]; then # openSUSE Tumbleweed
    export NIX_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem
elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
    export NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
elif [ -e "$NIX_USER_PROFILE_DIR/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in the user's Nix profile
    export NIX_SSL_CERT_FILE=$NIX_USER_PROFILE_DIR/etc/ssl/certs/ca-bundle.crt
elif [ -e "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in the default Nix profile
    export NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt
fi

export PATH=/nix/var/nix/profiles/default/bin:$PATH
export PATH="$NIX_PROFILE/bin:$PATH"
export NIX_PATH="nixpkgs=/nix/profiles/per-user/root/channels/nixpkgs"
#export NIX_PATH="$NIX_DEFEXPR/channels"
