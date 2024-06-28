# GENERATED 
HISTSIZE=1000
SAVEHIST=1000
HISTFILE="$HOME/.config/zsh/history"
setopt extendedglob nomatch notify
unsetopt autocd
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit
# GENERATED 

# ENV
export ARCHFLAGS="-arch x86-64"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=vim
export VIMRC="$HOME/.config/vim/vimrc"
export VIMINIT="source $VIMRC"
# ENV


# ZSH
PROMPT="[%F{magenta}%n%f %F{green}%~%f] "
# ZSH

ZDOTDIR=$HOME/.config/zsh

# ALIASES
alias zshedit="$EDITOR $HOME/.zshrc"
#alias ls=exa
# ALIASES

#BINDS
#bindkey '^R' history-incremental-search-backward
bindkey "^R" history-incremental-pattern-search-backward
#BINDS

# PLUGINS
source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# PLUGINS
