export ZDOTDIR="$HOME/.config/zsh/"
export HISTFILE="$HOME/.local/share/histfile"
export PYTHON_HISTORY="$HOME/.local/share/python/history"

# export SSLKEYLOGFILE="$HOME/ssl-key.log"
export EDITOR=nvim
export ARCH=x86_64
export ARCHFLAGS="-arch $ARCH"
export XCURSOR_PATH="${XCURSOR_PATH}:$HOME/.local/share/icons"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export JUNK_PATH="$HOME/.local/share"

export PATH="$HOME/.local/bin:$PATH"

# export ANDROID_HOME="$HOME/Android/Sdk"
# export PATH="$PATH:$ANDROID_HOME/emulator"
# export PATH="$PATH:$ANDROID_HOME/platform-tools"

export RUSTUP_HOME="$JUNK_PATH/rust"
export CARGO_HOME="$JUNK_PATH/rust"

export BUN_INSTALL="$JUNK_PATH/bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export GOPATH="$JUNK_PATH/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

export GNUPGHOME="$JUNK_PATH/gnupg"

export PNPM_HOME="$JUNK_PATH/pnpm"
export PATH="$PNPM_HOME:$PATH"

export N_PREFIX="$JUNK_PATH/N_node"

export __GL_SHADER_DISK_CACHE_PATH="$JUNK_PATH"

export NIXPKGS_ALLOW_UNFREE=1
