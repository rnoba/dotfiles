#!/usr/bin/env bash

MODULE_NAME="dotfiles"
MODULE_DESCRIPTION="Clone and setup dotfiles"
MODULE_DEPENDS=("user")

: "${DOTFILES_REPO:="https://github.com/rnoba/dotfiles"}"

dotfiles_run() {
  log_info "=== DOTFILES SETUP ==="

  dotfiles_clone
  dotfiles_install
}

dotfiles_clone() {
  log_info "Cloning dotfiles..."
  
  chroot_exec "
    mkdir -p /home/$USER_NAME/Public
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/Public
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config 2>/dev/null || true
  "
  
  chroot_exec "
    cd /home/$USER_NAME/Public
    sudo -u $USER_NAME git clone '$DOTFILES_REPO' Dotfiles
  "
  
  log_info "Dotfiles cloned"
}

dotfiles_install() {
  log_info "Running dotfiles setup..."
  
  chroot_exec "
    cd /home/$USER_NAME/Public/Dotfiles
    sudo -u $USER_NAME bash ./setup.sh
  "
  
  log_info "Dotfiles setup completed"
}
