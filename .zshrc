# Lines configured by zsh-newuser-install
export HISTSIZE=100000
export SAVEHIST=100000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS 
setopt INC_APPEND_HISTORY_TIME
setopt EXTENDED_HISTORY
bindkey -v
zstyle ':completion:*' hosts off
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle :compinstall filename "$ZDOTDIR/.zshrc"
autoload -Uz compinit
compinit
# End of lines added by compinstall


alias config_zsh="$EDITOR $ZDOTDIR/.zshrc"
alias config_i3="$EDITOR $HOME/.config/i3/config"

alias nix-shell='nix-shell --run zsh'
alias nix-develop='nix develop -c zsh'
alias ls='exa --icons --group-directories-first --sort type'

setopt prompt_subst
INITIAL_PROMPT="%F{magenta}%n%f %F{magenta}in %F{purple}%~%f"
TMUX_LOADED=false
NIX_LOADED=false
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=magenta,bold,underline"
function update_prompt()
{
	if [[ -v TMUX ]]; then
		if ! $TMUX_LOADED; then
			TMUX_LOADED=true
			A="%F{cyan}[T]"
		fi
	else
		TMUX_LOADED=false
		A=""
	fi

	if [[ -v IN_NIX_SHELL ]]; then
		if ! $NIX_LOADED; then
			NIX_LOADED=true
			B="%F{magenta}[N]"
		fi
	else
		B=""
		NIX_LOADED=false
	fi

	PROMPT="[$A$B$C${INITIAL_PROMPT}${vcs_info_msg_0_}] "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_prompt

function tmux_sessionizer() { tmux-sessionizer; zle redisplay; }
zle -N tmux_sessionizer 
bindkey '^f' tmux_sessionizer

bindkey "^R" history-incremental-pattern-search-backward
bindkey "^L" forward-word
bindkey "^H" backward-word

if [[ -v TMUX ]]; then
	bindkey "^B" beginning-of-line
	bindkey "^E" end-of-line
else
	bindkey "^[[H" beginning-of-line
fi

source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
[ -s "/home/rnoba/.local/share/bun/_bun" ] && source "/home/rnoba/.local/share/bun/_bun"

eval "$(direnv hook zsh)"
