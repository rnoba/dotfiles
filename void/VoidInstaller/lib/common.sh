#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

: "${HOSTNAME:=rnoba}"
: "${TIMEZONE:=America/Sao_Paulo}"
: "${LOCALE:=en_US.UTF-8}"
: "${KEYMAP:=us}"
: "${TARGET_DISK:=/dev/nvme0n1}"
: "${EFI_SIZE:=1GiB}"
: "${VOID_REPO:=https://repo-fastly.voidlinux.org/current}"
: "${ARCH:=x86_64}"
: "${EFI_PARTLABEL:=EFI}"
: "${ROOT_PARTLABEL:=ROOT}"
: "${EFI_FSLABEL:=EFI}"
: "${ROOT_FSLABEL:=ROOT}"
: "${USER_NAME:=$HOSTNAME}"
: "${USER_PASSWORD:=123}"
: "${ROOT_PASSWORD:=123}"
: "${USER_SHELL:=/bin/zsh}" 
: "${USER_GROUPS:=wheel,audio,video,input,storage,optical}"

declare -g MODULE_NAME=""
declare -g MODULE_DESCRIPTION=""
declare -g MODULE_DEPENDS=()

log_info()   { printf "%b[INFO]%b %s\n"  "$GREEN" "$NC" "$*"; }
log_warn()   { printf "%b[WARN]%b %s\n"  "$YELLOW" "$NC" "$*"; }
log_error()  { printf "%b[ERROR]%b %s\n" "$RED"   "$NC" "$*" >&2; }
log_debug()  { printf "%b[DEBUG]%b %s\n" "$BLUE"  "$NC" "$*"; }
log_module() { printf "%b[MODULE]%b %s\n" "$CYAN" "$NC" "$*"; }

cleanup_on_error() {
	log_error "Installation failed at line $1"

	log_info "Attempting cleanup..."
	umount -R /mnt/boot 2>/dev/null || true
	umount -R /mnt 2>/dev/null || true
	log_info "Cleanup completed"
	exit 1
}

trap 'cleanup_on_error $LINENO' ERR

check_root() {
	if [[ $EUID -ne 0 ]]; then
		log_error "This script must be run as root"
		exit 1
	fi

	log_info "Root check passed"
}

check_uefi() {
	if [[ ! -d /sys/firmware/efi ]]; then
		log_error "UEFI mode required. Please boot in UEFI mode."
		exit 1
	fi

	log_info "UEFI mode detected"
}

check_network() {
	log_info "Checking network connectivity..."

	if ! ping -c 1 -W 5 voidlinux.org &>/dev/null; then
		log_error "Network connectivity check failed"
		exit 1
	fi

	log_info "Network connectivity verified"
}

check_disk_exists() {
	log_info "Verifying target disk: $TARGET_DISK"

	if [[ ! -b "$TARGET_DISK" ]]; then
		log_error "Disk $TARGET_DISK not found"
		lsblk
		exit 1
	fi

	log_info "Target disk verified: $TARGET_DISK"
}

check_existing_mounts() {
	log_info "Checking for existing mounts on /mnt..."

	if mountpoint -q /mnt 2>/dev/null; then
		log_warn "/mnt is currently mounted"
		umount -R /mnt 2>/dev/null || {
			log_error "Failed to unmount /mnt. Please unmount manually."
					exit 1
				}
	fi

	log_info "Mount point /mnt is clear"
}

confirm_disk() {
	echo
	log_warn "╔════════════════════════════════════════════════════════════╗"
	log_warn "║  WARNING: This will DESTROY ALL DATA on $TARGET_DISK"
	log_warn "╚════════════════════════════════════════════════════════════╝"
	echo

	log_info "Current disk information:"

	lsblk -f "$TARGET_DISK" 2>/dev/null || true
	echo
	read -rp "Type 'YES' in capital letters to continue: " confirm
	if [[ "$confirm" != "YES" ]]; then
		log_info "Installation cancelled by user"
		exit 0
	fi

	log_info "User confirmed disk wipe"
}

install_packages() {
	local pkgs=("$@")

	log_info "Installing packages (${#pkgs[@]} packages)..."
	xbps-install -Sy -r /mnt -R "$VOID_REPO" "${pkgs[@]}" || {
		log_error "Failed to install packages"
				exit 1
			}

	log_info "Packages installed successfully"
}

chroot_exec() {
	if ! command -v xchroot &>/dev/null; then
		log_error "xchroot not found. Is xtools installed?"
		exit 1
	fi

	xchroot /mnt /bin/bash -c "$*"
}

enable_service() {
	local svc="$1"

	if [[ -d /mnt/etc/sv/"$svc" ]]; then
		log_debug "Enabling service: $svc"
		ln -sf /etc/sv/"$svc" /mnt/etc/runit/runsvdir/default/ 2>/dev/null || \
			log_warn "Failed to enable service: $svc"
	else
		log_warn "Service directory not found: $svc"
	fi
}

declare -gA LOADED_MODULES=()
declare -gA MODULE_PATHS=()

register_module() {
	local name="$1"
	local path="$2"
	MODULE_PATHS["$name"]="$path"
}

load_module() {
	local name="$1"
	if [[ -n "${LOADED_MODULES[$name]:-}" ]]; then
		return 0
	fi

	local path="${MODULE_PATHS[$name]:-}"
	if [[ -z "$path" ]] || [[ ! -f "$path" ]]; then
		log_error "Module not found: $name"
		return 1
	fi

	MODULE_NAME=""
	MODULE_DESCRIPTION=""
	MODULE_DEPENDS=()

	source "$path"

	for dep in "${MODULE_DEPENDS[@]}"; do
		load_module "$dep" || return 1
	done

	LOADED_MODULES["$name"]=1
	log_module "Loaded: $name${MODULE_DESCRIPTION:+ - $MODULE_DESCRIPTION}"
}

run_module() {
	local name="$1"
	local phase="${2:-run}"

	load_module "$name" || return 1

	local func="${name}_${phase}"

	if declare -f "$func" > /dev/null; then
		log_module "Running: $name ($phase)"
		"$func"
	fi
}

cleanup() {
	log_info "Cleaning up..."
	umount -R /mnt/boot 2>/dev/null || true
	umount -R /mnt 2>/dev/null || true
	log_info "Cleanup completed"
}
