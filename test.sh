#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HOSTNAME="rnoba"
TIMEZONE="America/Sao_Paulo"
LOCALE="en_US.UTF-8"
KEYMAP="us"
TARGET_DISK="/dev/nvme0n1"
EFI_SIZE="500MiB"
VOID_REPO="https://repo-default.voidlinux.org/current"
ARCH="x86_64"

USER_NAME="$HOSTNAME"
USER_PASSWORD="123"

EFI_UUID=""
ROOT_UUID=""

PACKAGES=(
	grub grub-x86_64-efi efibootmgr dosfstools
	NetworkManager network-manager-applet dhcpcd
	dbus elogind nftables
	pipewire pulseaudio
	p7zip unzip
	alacritty zsh tmux i3 dmenu firefox mpv neovim flameshot
	base-devel gcc clang git curl direnv
	noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji nerd-fonts
	vulkan-loader ripgrep xclip
	xorg xorg-server
	xtools sudo
)

log_info()  { printf "%b[INFO]%b %s\n"  "$GREEN" "$NC" "$1"; }
log_warn()  { printf "%b[WARN]%b %s\n"  "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED"   "$NC" "$1" >&2; exit 1; }

check_root() { 
	[[ $EUID -eq 0 ]] || log_error "This script must be run as root"
}

check_uefi() { 
	[[ -d /sys/firmware/efi ]] || log_error "UEFI mode required. Please boot in UEFI mode."
}

check_network() {
	log_info "Checking network connectivity..."

	if ! ping -c 1 -W 2 voidlinux.org &>/dev/null; then
		log_warn "Network connectivity check failed."
		log_error "Installation cancelled"
	fi
}

get_part() {
	local disk="$1" num="$2"
	if [[ $disk =~ nvme || $disk =~ mmcblk ]]; then 
		echo "${disk}p${num}"
	else 
		echo "${disk}${num}"
	fi
}

confirm_disk() {
	log_warn "╔════════════════════════════════════════════════════════════╗"
	log_warn "║  WARNING: This will DESTROY ALL DATA on $TARGET_DISK       "
	log_warn "╚════════════════════════════════════════════════════════════╝"
	echo
	lsblk -f "$TARGET_DISK" 2>/dev/null || log_error "Disk $TARGET_DISK not found"
	echo
	read -p "Type 'YES' in capital letters to continue: " confirm
	[[ "$confirm" == "YES" ]] || log_error "Installation cancelled by user"
}

partition_disk() {
	log_info "Partitioning $TARGET_DISK..."

	wipefs -af "$TARGET_DISK" || log_error "Failed to wipe partition table"

	parted -s "$TARGET_DISK" mklabel gpt || log_error "Failed to create GPT label"

	parted -s "$TARGET_DISK" mkpart primary fat32 1MiB "$EFI_SIZE" || log_error "Failed to create EFI partition"
	parted -s "$TARGET_DISK" set 1 esp on || log_error "Failed to set ESP flag"

	parted -s "$TARGET_DISK" mkpart primary ext4 "$EFI_SIZE" 100% || log_error "Failed to create root partition"

	sleep 2
	partprobe "$TARGET_DISK" 2>/dev/null || true
	sleep 2

	log_info "Partitioning completed successfully"
}

format_partitions() {
	local efi_part=$(get_part "$TARGET_DISK" 1)
	local root_part=$(get_part "$TARGET_DISK" 2)

	log_info "Formatting partitions..."

	mkfs.vfat -F32 "$efi_part" || log_error "Failed to format EFI partition"

	mkfs.ext4 -F "$root_part" || log_error "Failed to format root partition"

	EFI_UUID=$(blkid -s UUID -o value "$efi_part")
	ROOT_UUID=$(blkid -s UUID -o value "$root_part")

	[[ -n "$EFI_UUID" ]] || log_error "Failed to get EFI UUID"
	[[ -n "$ROOT_UUID" ]] || log_error "Failed to get ROOT UUID"

	log_info "Formatting completed (EFI: $EFI_UUID | Root: $ROOT_UUID)"
}

mount_partitions() {
	local efi_part=$(get_part "$TARGET_DISK" 1)
	local root_part=$(get_part "$TARGET_DISK" 2)

	log_info "Mounting partitions..."

	mount "$root_part" /mnt || log_error "Failed to mount root partition"

	mkdir -p /mnt/boot || log_error "Failed to create /boot directory"
	mount "$efi_part" /mnt/boot || log_error "Failed to mount EFI partition"

	log_info "Partitions mounted successfully"
}

generate_fstab() {
	log_info "Generating /etc/fstab using xgenfstab..."
	xgenfstab -U /mnt > /mnt/etc/fstab || log_error "Failed to generate fstab"
	log_info "fstab generated successfully"
	cat /mnt/etc/fstab
}

install_base_system() {
	log_info "Bootstrapping base-system..."

	mkdir -p /mnt/var/db/xbps/keys
	cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/ 2>/dev/null || true

	XBPS_ARCH="$ARCH" xbps-install -Sy -r /mnt -R "$VOID_REPO" base-system || \
		log_error "Failed to install base-system"

	log_info "base-system installed successfully"
}

update_xbps_and_system() {
	log_info "Updating xbps and system packages..."

	xbps-install -r /mnt -Su xbps || log_error "Failed to update xbps"
	xbps-install -r /mnt -Su || log_error "Failed to update system"

	log_info "System updated successfully"
}

install_additional_packages() {
	log_info "Installing additional packages..."

	xbps-install -Sy -r /mnt -R "$VOID_REPO" "${PACKAGES[@]}" || \
		log_error "Failed to install additional packages"

	log_info "Additional packages installed successfully"
}

configure_system() {
	log_info "Configuring system..."

	echo "$HOSTNAME" > /mnt/etc/hostname

	cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

echo "$LOCALE UTF-8" > /mnt/etc/default/libc-locales
echo "LANG=$LOCALE" > /mnt/etc/locale.conf

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

echo "KEYMAP=$KEYMAP" > /mnt/etc/rc.conf

log_info "System configuration completed"
}

configure_dracut() {
	log_info "Configuring dracut..."

	mkdir -p /mnt/etc/dracut.conf.d
	cat > /mnt/etc/dracut.conf.d/10-hostonly.conf <<EOF
hostonly=yes
hostonly_cmdline=yes
EOF

log_info "Dracut configured"
}

configure_dns() {
	log_info "Configuring DNS resolution..."

	cat > /mnt/etc/resolv.conf <<EOF
# Generated during installation
# NetworkManager will manage this file after first boot
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

mkdir -p /mnt/etc/NetworkManager/conf.d
cat > /mnt/etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=default
rc-manager=resolvconf
EOF

log_info "DNS configuration completed"
}

chroot_reconfigure() {
	log_info "Reconfiguring packages using xchroot..."

	xchroot /mnt /bin/bash <<'CHROOT_END'
set -e

echo "Generating locales..."
xbps-reconfigure -f glibc-locales

echo "Reconfiguring all packages..."
xbps-reconfigure -fa
CHROOT_END

[[ $? -eq 0 ]] || log_error "Chroot reconfiguration failed"
log_info "Package reconfiguration completed"
}

install_bootloader() {
	log_info "Installing GRUB bootloader..."

	xchroot /mnt /bin/bash <<'CHROOT_END'
set -e

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Void --recheck

grub-mkconfig -o /boot/grub/grub.cfg
CHROOT_END

[[ $? -eq 0 ]] || log_error "GRUB installation failed"
log_info "GRUB installed successfully"
}

enable_services() {
	log_info "Enabling essential services..."

	for svc in NetworkManager dbus elogind; do
		if [[ -d /mnt/etc/sv/"$svc" ]]; then
			ln -sf /etc/sv/"$svc" /mnt/etc/runit/runsvdir/default/ || \
				log_warn "Failed to enable service: $svc"
		else
			log_warn "Service directory not found: $svc"
		fi
	done

	log_info "Services enabled"
}

configure_zram() {
	log_info "Setting up zram (50% of RAM)..."

	cat > /mnt/etc/rc.local <<'EOF'
#!/bin/sh
modprobe zram

echo zstd > /sys/block/zram0/comp_algorithm
echo $(awk '/MemTotal/ {printf "%.0f", $2 * 0.5 * 1024}' /proc/meminfo) > /sys/block/zram0/disksize

mkswap /dev/zram0
swapon /dev/zram0 -p 100
EOF

chmod +x /mnt/etc/rc.local
log_info "zram configured"
}

set_root_password() {
	log_info "Setting root password..."

	xchroot /mnt /bin/bash <<'CHROOT_END'
set -e

if [[ ! -f /etc/shadow ]]; then
		echo "ERROR: /etc/shadow does not exist!"
		exit 1
fi

echo -e "root\nroot" | passwd root

if ! grep -q '^root:[^!*]' /etc/shadow; then
		echo "ERROR: Root password not set correctly!"
		exit 1
fi

echo "Root password successfully set"
CHROOT_END

[[ $? -eq 0 ]] || log_error "Failed to set root password"
log_info "Root password set to: root"
}

create_user() {
	log_info "Creating user '$USER_NAME'..."

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

useradd -m -G wheel,audio,video,input,storage,optical -s /bin/bash "$USER_NAME"

echo -e "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"

if ! grep -q "^$USER_NAME:[^!*]" /etc/shadow; then
		echo "ERROR: User password not set correctly!"
		exit 1
fi

if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
		echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

echo "User '$USER_NAME' successfully created and configured"
CHROOT_END

[[ $? -eq 0 ]] || log_error "Failed to create user"
log_info "User '$USER_NAME' created with password: $USER_PASSWORD"
}

cleanup() {
	log_info "Cleaning up mounts..."
	umount -R /mnt/boot 2>/dev/null || true
	umount -R /mnt 2>/dev/null || true
	log_info "Cleanup completed"
}

show_summary() {
	echo
	echo "════════════════════════════════════════════════════════════════"
	log_info "Installation Summary"
	echo "════════════════════════════════════════════════════════════════"
	echo "Disk:          $TARGET_DISK"
	echo "EFI partition: $(get_part "$TARGET_DISK" 1) (UUID: $EFI_UUID)"
	echo "Root partition: $(get_part "$TARGET_DISK" 2) (UUID: $ROOT_UUID)"
	echo "Hostname:      $HOSTNAME"
	echo "Timezone:      $TIMEZONE"
	echo "Locale:        $LOCALE"
	echo "Keymap:        $KEYMAP"
	echo
	echo "Credentials:"
	echo "  Root password:     root"
	echo "  User:              $USER_NAME"
	echo "  User password:     $USER_PASSWORD"
	echo
	echo "DNS Configuration:"
	echo "  - Fallback DNS servers configured (1.1.1.1, 8.8.8.8)"
	echo "  - NetworkManager will manage DNS after first boot"
	echo "════════════════════════════════════════════════════════════════"
	echo
}

main() {
	log_info "Void Linux Production Installer Starting..."
	echo

	check_root
	check_uefi
	check_network

	confirm_disk
	partition_disk
	format_partitions
	mount_partitions

	install_base_system
	update_xbps_and_system
	install_additional_packages

	configure_system
	generate_fstab
	configure_dracut
	configure_dns
	enable_services
	configure_zram

	chroot_reconfigure

	set_root_password
	create_user

	install_bootloader

	cleanup
	show_summary

	log_info "Installation completed successfully!"
	echo
	echo "You can now reboot into your new Void Linux system."
	echo
	read -p "Reboot now? (y/N): " ans
	[[ "$ans" =~ ^[Yy]$ ]] && reboot || log_info "Remember to reboot before using the system!"
}

trap 'log_error "Installation failed at line $LINENO"' ERR

main "$@"
