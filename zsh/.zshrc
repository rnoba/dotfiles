# Lines configured by zsh-newuser-install
export HISTFILE=~/.histfile
export HISTSIZE=100000
export SAVEHIST=100000
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt extendedglob nomatch notify
setopt EXTENDED_HISTORY
setopt BANG_HIST
bindkey -v
zstyle :compinstall filename '/home/rnoba/.zshrc'
autoload -Uz compinit
compinit
# End of lines added by compinstall

export EDITOR=nvim
export ARCH=x86_64
export ARCHFLAGS="-arch $ARCH"

alias config_zsh="$EDITOR $HOME/.zshrc"
alias config_sway="$EDITOR $HOME/.config/sway/config"
alias config_alacritty="$EDITOR $HOME/.config/alacritty/alacritty.toml"
alias nix-shell='nix-shell --run zsh'

setopt PROMPT_SUBST
INITIAL_PROMPT="%F{magenta}%n%f %F{magenta}in %F{purple}%~%f"
TMUX_LOADED=false
NIX_LOADED=false

function git_plugin()
{
	if [ -d "$PWD/.git" ]; then
		git status 1>/dev/null 2>/dev/null || return;
		D=""
		[[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && D="*"
		S="$(git status --porcelain 2>/dev/null| grep "^??" | wc -l)"
		C="%F{red}[$(git branch | cut -d ' ' -f 2)$D $S]"
	else
		C=""
	fi
}

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

	PROMPT="[$A$B$C${INITIAL_PROMPT}] "
}

function chpwd() {
    emulate -L zsh
		git_plugin
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_prompt 

bindkey "^R" history-incremental-pattern-search-backward
bindkey "^L" forward-word
bindkey "^H" backward-word

if [[ -v TMUX ]]; then
	bindkey "^[[1~" beginning-of-line
else
	bindkey "^[[H" beginning-of-line
fi

zstyle ':completion:*' hosts off
source "$HOME/.config/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
eval "$(direnv hook zsh)"
