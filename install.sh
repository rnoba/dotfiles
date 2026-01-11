#!/bin/bash

FIREFOX_HOME=${XDG_CONFIG_HOME/firefox:-$HOME/.config/firefox}
JUNK_PATH=${JUNK_PATH:-$HOME/.local/share}
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}

# cp ./.zshenv $HOME/

# cp -r ./zsh "$CONFIG_DIR/zsh"
# cp -r ./alacritty "$CONFIG_DIR/alacritty"
# cp -r ./tmux/ "$CONFIG_DIR/tmux"
# cp -r ./i3/ "$CONFIG_DIR/i3"
# cp -r ./i3blocks/ "$CONFIG_DIR/i3blocks

ln -s "$CONFIG_DIR/firefox/" "$HOME/.mozilla"
ln -s "$JUNK_PATH/pki/" "$HOME/.pki"
