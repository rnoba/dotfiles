#PURE shell config
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
# change the path color
# zstyle :prompt:pure:path color white
# change the color for both `prompt:success` and `prompt:error`
# zstyle ':prompt:pure:prompt:*' color cyan
# turn on git stash status
# zstyle :prompt:pure:git:stash show yes
# zstyle :prompt:pure:environment:nix-shell show
prompt fade magenta 
# End of pure shell config 
