#!/usr/bin/env bash
# User configuration for Void Linux Modular Installer
# Copy this to config.sh and customize, or set env vars

# ============================================================================
# SYSTEM SETTINGS
# ============================================================================

# Hostname for the system
# HOSTNAME="rnoba"

# Timezone (use 'timedatectl list-timezones' to see available options)
# TIMEZONE="America/Sao_Paulo"

# Locale (use 'locale -a' to see available locales)
# LOCALE="en_US.UTF-8"

# Keyboard layout (us, dvorak, uk, de, fr, etc.)
# KEYMAP="us"

# ============================================================================
# DISK SETTINGS
# ============================================================================

# Target disk for installation (BE CAREFUL - THIS WILL BE WIPED!)
# Examples: /dev/sda, /dev/nvme0n1, /dev/vda
# TARGET_DISK="/dev/nvme0n1"

# Size of EFI partition (minimum 512MiB, recommended 1GiB)
# EFI_SIZE="1GiB"

# ============================================================================
# REPOSITORY SETTINGS
# ============================================================================

# Void Linux repository mirror
# Default: https://repo-fastly.voidlinux.org/current
# Alternative mirrors:
#   - https://repo-default.voidlinux.org/current
#   - https://repo-fi.voidlinux.org/current
#   - https://mirrors.servercentral.com/voidlinux/current
# VOID_REPO="https://repo-fastly.voidlinux.org/current"

# System architecture
# ARCH="x86_64"

# ============================================================================
# PARTITION LABELS
# ============================================================================

# Partition labels (used by parted)
# EFI_PARTLABEL="Efi"
# ROOT_PARTLABEL="Root"

# Filesystem labels (used for mounting)
# EFI_FSLABEL="Efi"
# ROOT_FSLABEL="Root"

# ============================================================================
# USER SETTINGS
# ============================================================================

# Username for the primary user
# USER_NAME="$HOSTNAME"
# Password for the primary user (CHANGE THIS!)
# Consider prompting for password during installation instead
# USER_PASSWORD="123"

# ============================================================================
# NEW: ADDITIONAL USER SETTINGS
# ============================================================================

# Default shell for the user (/bin/bash, /bin/zsh, /bin/fish, etc.)
# Note: zsh and bash are installed by default, other shells need to be added
# USER_SHELL="/bin/bash"

# User groups (comma-separated, no spaces)
# Default groups provide access to audio, video, storage, sudo, etc.
# USER_GROUPS="wheel,audio,video,input,storage,optical"

# ============================================================================
# NEW: SECURITY SETTINGS
# ============================================================================

# Root password (CHANGE THIS!)
# ROOT_PASSWORD="root"

# Sudo configuration
# Set to "true" to allow passwordless sudo for wheel group (LESS SECURE)
# Set to "false" to require password for sudo (RECOMMENDED)
# SUDO_NOPASSWD="false"

# ============================================================================
# DOTFILES REPOSITORY
# ============================================================================

# Git repository containing your dotfiles
# The dotfiles module will clone this repo to /home/$USER_NAME/Public/Dotfiles
# and run the setup.sh script if it exists
# DOTFILES_REPO="https://github.com/rnoba/dotfiles"

# ============================================================================
# ADVANCED SETTINGS (Usually don't need to change these)
# ============================================================================

# DNS servers (space-separated)
# Default uses Cloudflare (1.1.1.1) and Google (8.8.8.8)
# DNS_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4"

# GRUB timeout in seconds
# GRUB_TIMEOUT=5

# GRUB kernel command line parameters
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4"

# ============================================================================
# EXAMPLE CONFIGURATIONS
# ============================================================================

# Example 1: Basic desktop user
# HOSTNAME="mydesktop"
# USER_NAME="john"
# USER_PASSWORD="securepassword123"
# ROOT_PASSWORD="rootpassword456"
# USER_SHELL="/bin/zsh"
# SUDO_NOPASSWD="false"

# Example 2: Development workstation
# HOSTNAME="devbox"
# USER_NAME="developer"
# USER_SHELL="/bin/zsh"
# DOTFILES_REPO="https://github.com/yourusername/dotfiles"
# SUDO_NOPASSWD="true"  # Convenient but less secure

# Example 3: Minimal server
# HOSTNAME="server"
# USER_NAME="admin"
# USER_SHELL="/bin/bash"
# SUDO_NOPASSWD="false"
# TARGET_DISK="/dev/sda"

# ============================================================================
# NOTES
# ============================================================================
#
# - All settings can also be set as environment variables before running install
# - Environment variables take precedence over this config file
# - Run './install --list' to see available modules
# - Run './install --list-profiles' to see available profiles
# - Use hooks/pre-install.sh and hooks/post-install.sh for custom setup
#
