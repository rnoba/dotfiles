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

export EZA_COLORS="\
uu=38;5;180:\
gu=38;5;180:\
sn=38;5;246:\
sb=38;5;246:\
da=38;5;102:\
ur=38;5;180:\
uw=38;5;180:\
ux=38;5;180:\
ue=38;5;180:\
gr=38;5;180:\
gw=38;5;180:\
gx=38;5;180:\
tr=38;5;180:\
tw=38;5;180:\
tx=38;5;180:\
fi=38;5;180:\
di=38;5;172:\
ex=38;5;208:\
*.png=38;5;135:\
*.jpg=38;5;135:\
*.jpeg=38;5;135:\
*.gif=38;5;135:\
*.mp4=38;5;135:\
*.mkv=38;5;135:\
*.webm=38;5;135:\
ln=38;5;141:\
or=38;5;196:\
mi=38;5;196:\
bd=38;5;208:\
cd=38;5;208:\
so=38;5;135:\
pi=38;5;135:\
su=38;5;196:\
sg=38;5;196:\
tw=38;5;172:\
ow=38;5;172:\
st=38;5;172"

export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct

# . "/home/rnoba/.local/share/rust/env"
