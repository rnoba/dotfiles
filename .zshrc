# Powerlevel10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# DEFAULTS
export LANG=en_US.UTF-8
export EDITOR="nvim"
export ARCHFLAGS="-arch x86-64"
# END

ZSH="$HOME/.config/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    archlinux
    zsh-navigation-tools
    golang
    common-aliases
    colored-man-pages
    aliases
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

#ALIASES
alias ls="exa --icons --group-directories-first"
alias vim="nvim"
alias ll="exa --tree --icons --git-ignore --git --list-dirs"
alias cat="bat --style=plain --theme='gruvbox-dark'"
# END
#
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias francinette=/home/rnoba/francinette/tester.sh
alias paco=/home/rnoba/francinette/tester.sh
