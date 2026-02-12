#!/usr/bin/env bash

HOSTNAME="rnoba"
TIMEZONE="America/Sao_Paulo"
LOCALE="en_US.UTF-8"
KEYMAP="us"
TARGET_DISK="/dev/nvme0n1"
EFI_SIZE="1GiB"
ARCH="x86_64"
# - https://repo-default.voidlinux.org/current
# - https://repo-fi.voidlinux.org/current
# - https://mirrors.servercentral.com/voidlinux/current
VOID_REPO="https://repo-fastly.voidlinux.org/current"

# Partition labels (used by parted)
EFI_PARTLABEL="EFI"
ROOT_PARTLABEL="ROOT"
# Filesystem labels (used for mounting)
EFI_FSLABEL="EFI"
ROOT_FSLABEL="ROOT"

# Username for the primary user (change on 1st boot)
USER_NAME="$HOSTNAME"
USER_PASSWORD="123"
# Default root password (change on 1st boot)
ROOT_PASSWORD="123"
# %wheel ALL=(ALL:ALL) NOPASSWD: ALL
SUDO_NOPASSWD="true"

USER_SHELL="/usr/bin/zsh"
USER_GROUPS="wheel,audio,video,input,storage,optical,kvm"

DOTFILES_REPO="https://github.com/rnoba/dotfiles"
