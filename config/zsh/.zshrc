export HISTSIZE=100000
export SAVEHIST=100000
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

bindkey -v

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
autoload -Uz compinit && compinit

alias nix-shell='nix-shell --run zsh'
alias nix-develop='nix develop -c zsh'
alias ls='exa --icons --group-directories-first --sort type'

setopt prompt_subst
PROMPT='%F{magenta}%n in %F{purple}%~%f '
[[ -v TMUX ]] && PROMPT="%F{cyan}[T]$PROMPT"
[[ -v IN_NIX_SHELL ]] && PROMPT="%F{magenta}[N]$PROMPT"

bindkey "^R" history-incremental-pattern-search-backward
bindkey "^L" forward-word
bindkey "^H" backward-word
bindkey "^[[H" beginning-of-line
[[ -v TMUX ]] && { bindkey "^B" beginning-of-line; bindkey "^E" end-of-line; }

function tmux_sessionizer() { tmux-sessionizer; zle redisplay; }
zle -N tmux_sessionizer
bindkey '^f' tmux_sessionizer

source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=magenta,bold,underline"

eval "$(direnv hook zsh)"
