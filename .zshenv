export ZDOTDIR="$HOME/.config/zsh"

# export SSLKEYLOGFILE="$HOME/ssl-key.log"
export EDITOR=nvim
export ARCH=x86_64
export ARCHFLAGS="-arch $ARCH"
export XCURSOR_PATH="${XCURSOR_PATH:-$HOME/.local/share/icons}"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export HISTFILE="$XDG_STATE_HOME/history/zsh"
export PYTHON_HISTORY="$XDG_STATE_HOME/history/python"
export LESSHISTFILE="$XDG_STATE_HOME/history/less"
export SQLITE_HISTORY="$XDG_STATE_HOME/history/sqlite"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/history/node_repl"
export MYSQL_HISTFILE="$XDG_STATE_HOME/history/mysql"
export PSQL_HISTORY="$XDG_STATE_HOME/history/psql"

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

export EXA_COLORS="\
uu=38;5;246:\
gu=38;5;246:\
sn=38;5;246:\
sb=38;5;246:\
da=38;5;240:\
ur=38;5;246:\
uw=38;5;246:\
ux=38;5;246:\
ue=38;5;246:\
gr=38;5;246:\
gw=38;5;246:\
gx=38;5;246:\
tr=38;5;246:\
tw=38;5;246:\
tx=38;5;246:\
fi=38;5;249:\
di=38;5;147:\
ex=38;5;212:\
*.png=38;5;177:\
*.jpg=38;5;177:\
*.gif=38;5;177:\
*.mp4=38;5;177:\
*.mkv=38;5;177:\
ln=38;5;141:\
or=38;5;196"

export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct

# . "/home/rnoba/.local/share/rust/env"
