#!/usr/bin/env bash

MODULE_NAME="user"
MODULE_DESCRIPTION="Create user and set passwords"
MODULE_DEPENDS=("base")

readonly USER_PACKAGES=(
  zsh
  firefox
  flameshot
  Thunar
  alacritty
  mpv
  exa
  neovim
  zathura
  zathura-pdf-mupdf
  network-manager-applet
  feh
  # ntfs-3g
  # thunar-volman
  # gvfs
)

user_run() {
  log_info "=== USER CONFIGURATION ==="

  user_install_packages
  user_root_password
  user_create
}

user_install_packages() {
  log_info "Installing user packages (${#USER_PACKAGES[@]})..."
  install_packages "${USER_PACKAGES[@]}"
}

user_root_password() {
  log_info "Setting root password..."
  
  chroot_exec "echo -e '${ROOT_PASSWORD}\n${ROOT_PASSWORD}' | passwd root"
  
  if ! chroot_exec "grep -q '^root:[^!*]' /etc/shadow"; then
    log_error "Root password was not set correctly"
    exit 1
  fi
  
  log_info "Root password set to: $ROOT_PASSWORD"
}

user_create() {
  log_info "Creating user: $USER_NAME"
  
  chroot_exec "
    useradd -m -G ${USER_GROUPS} -s ${USER_SHELL} '${USER_NAME}'
    echo -e '${USER_PASSWORD}\n${USER_PASSWORD}' | passwd '${USER_NAME}'
  "
  
  if ! chroot_exec "grep -q '^${USER_NAME}:[^!*]' /etc/shadow"; then
    log_error "User password was not set correctly"
    exit 1
  fi
  
  if [[ "${SUDO_NOPASSWD:-false}" == "true" ]]; then
    log_warn "Enabling passwordless sudo for wheel group"
    chroot_exec "
      if ! grep -q '^%wheel ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers; then
        echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
      fi
    "
  else
    log_info "Configuring sudo to require password"
    chroot_exec "
      if ! grep -q '^%wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
        echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
      fi
    "
  fi
  
  log_info "User '${USER_NAME}' created with password: $USER_PASSWORD"
  log_info "Default shell: ${USER_SHELL}"
  log_info "Groups: ${USER_GROUPS}"
}
