# GENERATED 
HISTFILE=~/.config/zsh/histfile
HISTSIZE=1000
SAVEHIST=1000
setopt extendedglob nomatch notify
unsetopt autocd
zstyle :compinstall filename '/home/rnoba/.config/zshrc'
autoload -Uz compinit
compinit
# GENERATED 

# ENV
export ARCHFLAGS="-arch x86-64"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=vim
export VIMRC='$HOME/.config/vim/vimrc'
export VIMINIT='source $VIMRC'
# ENV


# ZSH
PROMPT='[%F{magenta}%n%f %F{green}%~%f] '
autoload -Uz add-zsh-hook

function reset_broken_terminal () {
		printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
	}

	add-zsh-hook -Uz precmd reset_broken_terminal
# ZSH

# ALIASES
alias zshedit="$EDITOR $ZDOTDIR/.zshrc"
# ALIASES

#BINDS
bindkey '^R' history-incremental-search-backward
#BINDS

# PLUGINS
source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# PLUGINS
