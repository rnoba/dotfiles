#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

readonly HOSTNAME="rnoba"
readonly TIMEZONE="America/Sao_Paulo"
readonly LOCALE="en_US.UTF-8"
readonly KEYMAP="us"
readonly TARGET_DISK="/dev/nvme0n1"
readonly EFI_SIZE="1GiB"
readonly VOID_REPO="https://repo-fastly.voidlinux.org/current"
readonly ARCH="x86_64"

readonly EFI_PARTLABEL="Efi"
readonly ROOT_PARTLABEL="Root"

readonly EFI_FSLABEL="Efi"
readonly ROOT_FSLABEL="Root"

readonly USER_NAME="$HOSTNAME"
readonly USER_PASSWORD="123"

readonly PACKAGES=(
	# Boot and system essentials
	grub grub-x86_64-efi efibootmgr dosfstools

	# Networking
	NetworkManager network-manager-applet dhcpcd openresolv

	# System services - elogind provides XDG_RUNTIME_DIR and device access
	dbus elogind nftables polkit

	# Audio - PipeWire with WirePlumber session manager
	pipewire wireplumber

	# Compression
	p7zip unzip

	# User applications
	exa nix xdg-user-dirs speech-dispatcher pavucontrol alacritty zsh tmux i3 i3blocks dmenu firefox mpv neovim flameshot

	# Development tools
	base-devel gcc clang git curl direnv

	# Fonts
	noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji nerd-fonts

	# Graphics and utilities
	nvidia vulkan-loader ripgrep xclip

	# Xorg
	xorg xorg-server

	# System tools
	xtools sudo
)

log_info()  { printf "%b[INFO]%b %s\n"  "$GREEN" "$NC" "$*"; }
log_warn()  { printf "%b[WARN]%b %s\n"  "$YELLOW" "$NC" "$*"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED"   "$NC" "$*" >&2; }
log_debug() { printf "%b[DEBUG]%b %s\n" "$BLUE"  "$NC" "$*"; }

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
		log_error "Please configure network before running installation"
		exit 1
	fi

	log_info "Network connectivity verified"
}

check_existing_mounts() {
	log_info "Checking for existing mounts on /mnt..."

	if mountpoint -q /mnt 2>/dev/null; then
		log_warn "/mnt is currently mounted"
		log_info "Attempting to unmount..."

		umount -R /mnt 2>/dev/null || {
			log_error "Failed to unmount /mnt. Please unmount manually."
					exit 1
				}
	fi

	log_info "Mount point /mnt is clear"
}

check_disk_exists() {
	log_info "Verifying target disk exists: $TARGET_DISK"

	if [[ ! -b "$TARGET_DISK" ]]; then
		log_error "Disk $TARGET_DISK not found"
		lsblk
		exit 1
	fi

	log_info "Target disk verified: $TARGET_DISK"
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

partition_disk() {
	log_info "Partitioning $TARGET_DISK..."

	log_debug "Wiping filesystem signatures..."
	wipefs -af "$TARGET_DISK" || {
		log_error "Failed to wipe partition table"
			exit 1
		}

	log_debug "Creating GPT partition table..."
	parted -s "$TARGET_DISK" mklabel gpt || {
		log_error "Failed to create GPT label"
			exit 1
		}

	log_debug "Creating EFI partition with label: $EFI_PARTLABEL"
	parted -s "$TARGET_DISK" mkpart "$EFI_PARTLABEL" fat32 1MiB "$EFI_SIZE" || {
		log_error "Failed to create EFI partition"
			exit 1
		}

	parted -s "$TARGET_DISK" set 1 esp on || {
		log_error "Failed to set ESP flag"
			exit 1
		}

	log_debug "Creating root partition with label: $ROOT_PARTLABEL"
	parted -s "$TARGET_DISK" mkpart "$ROOT_PARTLABEL" ext4 "$EFI_SIZE" 100% || {
		log_error "Failed to create root partition"
			exit 1
		}

	log_debug "Informing kernel of partition changes..."
	partprobe "$TARGET_DISK" 2>/dev/null || true

	log_debug "Waiting for udev to settle..."
	udevadm settle --timeout=10 || log_warn "udevadm settle timed out"

	sleep 2

	log_info "Partitioning completed successfully"
	log_info "Partition labels: EFI='$EFI_PARTLABEL', Root='$ROOT_PARTLABEL'"
}

format_partitions() {
	log_info "Formatting partitions using partition labels..."

	log_debug "Locating EFI partition: PARTLABEL=$EFI_PARTLABEL"
	local efi_part
	efi_part=$(findfs PARTLABEL="$EFI_PARTLABEL" 2>/dev/null) || {
		log_error "Failed to find EFI partition by PARTLABEL=$EFI_PARTLABEL"
			log_error "Available partitions:"
			lsblk -o NAME,PARTLABEL,FSTYPE "$TARGET_DISK"
			exit 1
		}
	log_debug "Found EFI partition: $efi_part"

	log_debug "Locating root partition: PARTLABEL=$ROOT_PARTLABEL"
	local root_part
	root_part=$(findfs PARTLABEL="$ROOT_PARTLABEL" 2>/dev/null) || {
		log_error "Failed to find root partition by PARTLABEL=$ROOT_PARTLABEL"
			log_error "Available partitions:"
			lsblk -o NAME,PARTLABEL,FSTYPE "$TARGET_DISK"
			exit 1
		}
	log_debug "Found root partition: $root_part"

	log_debug "Formatting EFI partition as FAT32 with label: $EFI_FSLABEL"
	mkfs.vfat -F32 -n "$EFI_FSLABEL" "$efi_part" || {
		log_error "Failed to format EFI partition"
			exit 1
		}

	log_debug "Formatting root partition as ext4 with label: $ROOT_FSLABEL"
	mkfs.ext4 -F -L "$ROOT_FSLABEL" "$root_part" || {
		log_error "Failed to format root partition"
			exit 1
		}

	log_debug "Verifying filesystem labels..."
	local efi_label
	efi_label=$(blkid -s LABEL -o value "$efi_part" 2>/dev/null) || efi_label=""
	local root_label
	root_label=$(blkid -s LABEL -o value "$root_part" 2>/dev/null) || root_label=""

	if [[ "$efi_label" != "$EFI_FSLABEL" ]]; then
		log_error "EFI filesystem label mismatch: expected '$EFI_FSLABEL', got '$efi_label'"
		exit 1
	fi

	if [[ "$root_label" != "$ROOT_FSLABEL" ]]; then
		log_error "Root filesystem label mismatch: expected '$ROOT_FSLABEL', got '$root_label'"
		exit 1
	fi

	log_info "Formatting completed and verified"
	log_info "  EFI:  $efi_part  (LABEL=$EFI_FSLABEL)"
	log_info "  Root: $root_part (LABEL=$ROOT_FSLABEL)"
}

mount_partitions() {
	log_info "Mounting partitions using filesystem labels..."

	log_debug "Mounting root: LABEL=$ROOT_FSLABEL → /mnt"
	mount LABEL="$ROOT_FSLABEL" /mnt || {
		log_error "Failed to mount root partition"
			exit 1
		}

	mkdir -p /mnt/boot || {
		log_error "Failed to create /boot directory"
			exit 1
		}

	log_debug "Mounting EFI: LABEL=$EFI_FSLABEL → /mnt/boot"

	mount LABEL="$EFI_FSLABEL" /mnt/boot || {
		log_error "Failed to mount EFI partition"
			exit 1
		}

	log_info "Partitions mounted successfully"

	log_debug "Mount verification:"
	findmnt /mnt
	findmnt /mnt/boot
}

install_base_system() {
	log_info "Installing base-system to /mnt..."

	mkdir -p /mnt/var/db/xbps/keys

	if [[ -d /var/db/xbps/keys ]]; then
		cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/ 2>/dev/null || true
	fi

	log_debug "Running xbps-install for base-system..."

	XBPS_ARCH="$ARCH" xbps-install -Sy -r /mnt -R "$VOID_REPO" base-system void-repo-nonfree void-repo-multilib || {
		log_error "Failed to install base-system"
			log_error "Check network connectivity and repository URL"
			exit 1
		}

	log_info "base-system installed successfully"
}

update_xbps_and_system() {
	log_info "Updating XBPS and system packages..."

	log_debug "Updating XBPS package manager..."

	xbps-install -r /mnt -Su xbps || {
		log_error "Failed to update XBPS"
			exit 1
		}

	log_debug "Updating all system packages..."

	xbps-install -r /mnt -Su || {
		log_error "Failed to update system packages"
			exit 1
		}

	log_info "System updated successfully"
}

install_additional_packages() {
	log_info "Installing additional packages (${#PACKAGES[@]} packages)..."

		xbps-install -Sy -r /mnt -R "$VOID_REPO" "${PACKAGES[@]}" || {
			log_error "Failed to install additional packages"
					log_error "Check package names and repository availability"
					exit 1
				}

			log_info "Additional packages installed successfully"
		}

	generate_fstab() {
		log_info "Generating /etc/fstab with filesystem labels..."

		log_debug "Running xgenfstab -L /mnt..."
		xgenfstab -L /mnt > /mnt/etc/fstab || {
			log_error "Failed to generate fstab"
					exit 1
				}

			if [[ ! -s /mnt/etc/fstab ]]; then
				log_error "Generated fstab is empty"
				exit 1
			fi

			if ! grep -q "LABEL=$ROOT_FSLABEL" /mnt/etc/fstab; then
				log_warn "fstab does not contain expected root label"
				log_warn "fstab may be using UUIDs instead of labels"
			fi

			log_info "fstab generated successfully:"
			cat /mnt/etc/fstab | grep -v '^#' | grep -v '^$' || true
		}

	configure_system() {
		log_info "Configuring system..."

		log_debug "Setting hostname: $HOSTNAME"
		echo "$HOSTNAME" > /mnt/etc/hostname

		log_debug "Configuring /etc/hosts"
		cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

log_debug "Setting locale: $LOCALE"
echo "$LOCALE UTF-8" > /mnt/etc/default/libc-locales
echo "LANG=$LOCALE" > /mnt/etc/locale.conf

log_debug "Setting timezone: $TIMEZONE"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

log_debug "Configuring rc.conf"
cat > /mnt/etc/rc.conf <<EOF
# /etc/rc.conf - system configuration for void

# Set the host name.
# NOTE: it's preferred to declare the hostname in /etc/hostname instead
#HOSTNAME="$HOSTNAME"

# Set RTC to UTC or localtime.
HARDWARECLOCK="UTC"

# Set timezone, availables timezones at /usr/share/zoneinfo.
# NOTE: it's preferred to set the timezone in /etc/localtime instead
#TIMEZONE="$TIMEZONE"

# Keymap to load, see loadkeys(8).
KEYMAP="$KEYMAP"

# Console font to load, see setfont(8).
#FONT="lat9w-16"

# Console map to load, see setfont(8).
#FONT_MAP=

# Font unimap to load, see setfont(8).
#FONT_UNIMAP=

# Kernel modules to load, delimited by blanks.
#MODULES=""
EOF

log_info "System configuration completed"
}

configure_dracut() {
	log_info "Configuring dracut for hostonly initramfs..."

	mkdir -p /mnt/etc/dracut.conf.d

	cat > /mnt/etc/dracut.conf.d/10-hostonly.conf <<EOF
# Hostonly mode - only include drivers needed for this system
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

configure_nftables() {
	log_info "Configuring nftables firewall..."
	
	cat > /mnt/etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f

# Clear any existing rules
flush ruleset

# Main filter table (handles both IPv4 and IPv6)
table inet filter {
	# Input chain - incoming traffic
	chain input {
		type filter hook input priority filter; policy drop;
		
		# Accept loopback traffic (localhost)
		iif lo accept
		
		# Accept established/related connections (stateful)
		# This allows responses to YOUR outgoing connections (web browsing, etc.)
		ct state established,related accept
		
		# Drop invalid packets
		ct state invalid drop
		
		# Accept ICMPv6 (required for IPv6 to function)
		ip6 nexthdr icmpv6 icmpv6 type {
			destination-unreachable,
			packet-too-big,
			time-exceeded,
			parameter-problem,
			echo-request,
			echo-reply,
			nd-router-advert,
			nd-neighbor-solicit,
			nd-neighbor-advert
		} accept
		
		# Accept ICMP ping (so you can ping your own PC from other devices)
		ip protocol icmp icmp type echo-request accept
		
		# Allow DHCP client responses from local network
		ip protocol udp udp sport 67 udp dport 68 accept
		
		# Optional: Allow local network access (uncomment if needed)
		# Useful for file sharing, SSH from other home devices, etc.
		# ip saddr 192.168.0.0/16 accept
		# ip saddr 10.0.0.0/8 accept
	}
	
	# Output chain - outgoing traffic
	chain output {
		type filter hook output priority filter; policy accept;
		
		# Allow all outgoing traffic (web browsing, gaming, downloads, etc.)
	}
	
	chain forward {
		type filter hook forward priority filter; policy drop;
	}
}
EOF
	
	log_info "nftables configuration created at /etc/nftables.conf"
}

enable_services() {
	log_info "Enabling system services..."

	local services=(NetworkManager dbus elogind nftables)

	for svc in "${services[@]}"; do
		if [[ -d /mnt/etc/sv/"$svc" ]]; then
			log_debug "Enabling service: $svc"

			ln -sf /etc/sv/"$svc" /mnt/etc/runit/runsvdir/default/ || {
				log_warn "Failed to enable service: $svc"
			}
	else
		log_warn "Service directory not found: $svc"
		fi
	done

	log_info "Services enabled"
}

configure_pipewire() {
	log_info "Configuring PipeWire audio system..."

	mkdir -p /mnt/etc/pipewire/pipewire.conf.d

	log_debug "Enabling WirePlumber session manager..."
	ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf \
		/mnt/etc/pipewire/pipewire.conf.d/10-wireplumber.conf

	log_debug "Enabling PulseAudio interface..."
	ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf \
		/mnt/etc/pipewire/pipewire.conf.d/20-pipewire-pulse.conf

	log_info "PipeWire configuration completed"
}

configure_zram() {
	log_info "Configuring zram swap (50% of RAM with zstd compression)..."

	cat > /mnt/etc/rc.local <<EOF
#!/bin/sh
# zram swap configuration
# Creates compressed swap in RAM (50% of total RAM)

modprobe zram

echo zstd > /sys/block/zram0/comp_algorithm

echo $(awk '/MemTotal/ {printf "%.0f", $2 * 0.5 * 1024}' /proc/meminfo) > /sys/block/zram0/disksize

mkswap /dev/zram0
swapon /dev/zram0 -p 100
EOF

chmod +x /mnt/etc/rc.local

log_info "zram configuration completed"
}

chroot_reconfigure() {
	log_info "Reconfiguring packages in chroot..."

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

echo "Generating locales..."
xbps-reconfigure -f glibc-locales

echo "Reconfiguring all packages..."
xbps-reconfigure -fa

echo "Package reconfiguration completed"
CHROOT_END

if [[ $? -ne 0 ]]; then
	log_error "Chroot reconfiguration failed"
	exit 1
fi

log_info "Package reconfiguration completed"
}

set_root_password() {
	log_info "Setting root password..."

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

if [[ ! -f /etc/shadow ]]; then
	echo "ERROR: /etc/shadow does not exist"
	exit 1
fi

echo -e "root\nroot" | passwd root

if ! grep -q '^root:[^!*]' /etc/shadow; then
	echo "ERROR: Root password was not set correctly"
	exit 1
fi

echo "Root password set successfully"
CHROOT_END

if [[ $? -ne 0 ]]; then
	log_error "Failed to set root password"
	exit 1
fi

log_info "Root password set to: root"
}

create_user() {
	log_info "Creating user: $USER_NAME"

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

useradd -m -G wheel,audio,video,input,storage,optical -s "$(command -v zsh || echo /bin/zsh)" "$USER_NAME"
echo -e "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"

if ! grep -q "^$USER_NAME:[^!*]" /etc/shadow; then
	echo "ERROR: User password was not set correctly"
	exit 1
fi

if ! grep -q "^%wheel ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers; then
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

echo "User created successfully"
CHROOT_END

if [[ $? -ne 0 ]]; then
	log_error "Failed to create user"
	exit 1
fi

log_info "User '$USER_NAME' created with password: $USER_PASSWORD"
}

install_bootloader() {
	log_info "Installing GRUB bootloader..."

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

echo "Installing GRUB to EFI..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Void --recheck

echo "Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "GRUB installation completed"
CHROOT_END

if [[ $? -ne 0 ]]; then
	log_error "GRUB installation failed"
	exit 1
fi

log_info "GRUB installed successfully"
}

setup_dotfiles() {
	log_info "Setting up dotfiles..."

	xchroot /mnt /bin/bash <<CHROOT_END
set -e

REPO=https://github.com/rnoba/dotfiles
DEST_DIR=/home/$USER_NAME/Public

mkdir -p /home/$USER_NAME/.config
mkdir -p "\$DEST_DIR"
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config
chown -R $USER_NAME:$USER_NAME "\$DEST_DIR"

pushd "\$DEST_DIR"
sudo -u $USER_NAME git clone "\$REPO" Dotfiles
pushd ./Dotfiles
sudo -u $USER_NAME bash ./setup.sh
popd
popd

echo "Dotfiles setup completed"
CHROOT_END

if [[ $? -ne 0 ]]; then
	log_error "Dotfiles setup failed"
	exit 1
fi

log_info "Dotfiles installed successfully"
}

cleanup() {
	log_info "Cleaning up..."

	log_debug "Unmounting /mnt/boot..."
	umount -R /mnt/boot 2>/dev/null || true

	log_debug "Unmounting /mnt..."
	umount -R /mnt 2>/dev/null || true

	log_info "Cleanup completed"
}

setup_nix() {
	log_info "Setting up Nix..."
	
	if [ -d "/mnt/home/$USER_NAME/Public/Dotfiles" ]; then
		cat > /mnt/etc/nix/nix.conf <<EOF
build-users-group = nixbld
build-use-sandbox = true
use-xdg-base-directories = true
connect-timeout = 60000
experimental-features = nix-command flakes
EOF

		[ -e "/mnt/etc/nix/nix.conf" ] && cat /mnt/etc/nix/nix.conf

		if [ -e "/mnt/home/$USER_NAME/Public/Dotfiles/void/nix.sh" ]; then
			cp "/mnt/home/$USER_NAME/Public/Dotfiles/void/nix.sh" /mnt/etc/profile.d/nix.sh
		else
			log_warn "nix.sh not found in dotfiles"
		fi

		if [[ -d /mnt/etc/sv/nix-daemon ]]; then
			log_debug "Enabling service: nix-daemon"
			ln -sf /etc/sv/nix-daemon /mnt/etc/runit/runsvdir/default/ || {
				log_warn "Failed to enable service: nix-daemon"
			}
		else
			log_warn "Service directory not found: nix-daemon"
		fi
	else
		log_warn "Dotfiles directory not found, skipping Nix setup"
	fi
}

setup_xorg_conf() {
	if [ -d "/mnt/home/$USER_NAME/Public/Dotfiles" ]; then
		if [ -e "/mnt/home/$USER_NAME/Public/Dotfiles/xorg.conf" ]; then
			cp "/mnt/home/$USER_NAME/Public/Dotfiles/xorg.conf" /mnt/etc/X11/xorg.conf
			log_info "Xorg configuration copied"
		else
			log_warn "xorg.conf not found in dotfiles"
		fi
	else
		log_warn "Dotfiles directory not found, skipping xorg.conf"
	fi
}

show_summary() {
	echo
	echo "════════════════════════════════════════════════════════════════"
	log_info "INSTALLATION COMPLETED SUCCESSFULLY"
	echo "════════════════════════════════════════════════════════════════"
	echo
	echo "Disk Configuration:"
	echo "  Target disk:    $TARGET_DISK"
	echo "  Partition type: GPT"
	echo
	echo "Partitions:"
	echo "  EFI System:"
	echo "    - PARTLABEL:  $EFI_PARTLABEL"
	echo "    - LABEL:      $EFI_FSLABEL"
	echo "    - Type:       FAT32"
	echo "    - Size:       $EFI_SIZE"
	echo "    - Mount:      /boot"
	echo
	echo "  Root Filesystem:"
	echo "    - PARTLABEL:  $ROOT_PARTLABEL"
	echo "    - LABEL:      $ROOT_FSLABEL"
	echo "    - Type:       ext4"
	echo "    - Mount:      /"
	echo
	echo "System Configuration:"
	echo "  Hostname:       $HOSTNAME"
	echo "  Timezone:       $TIMEZONE"
	echo "  Locale:         $LOCALE"
	echo "  Keymap:         $KEYMAP"
	echo
	echo "Credentials:"
	echo "  Root password:  root"
	echo "  User:           $USER_NAME"
	echo "  User password:  $USER_PASSWORD"
	echo "  User shell:     /bin/zsh"
	echo
	echo "Post-Installation Commands:"
	echo "  # Verify partition labels"
	echo "  lsblk -o NAME,PARTLABEL,LABEL,FSTYPE,SIZE,MOUNTPOINT"
	echo
	echo "  # Find partitions by label"
	echo "  findfs LABEL=$ROOT_FSLABEL"
	echo "  findfs LABEL=$EFI_FSLABEL"
	echo
	echo
	echo "════════════════════════════════════════════════════════════════"
	echo
}

main() {
	log_info "Void Linux Production Installation Script"
	log_info "Label-based installation with comprehensive error handling"
	echo

	log_info "=== PRE-FLIGHT CHECKS ==="
	check_root
	check_uefi
	check_network
	check_disk_exists
	check_existing_mounts
	echo

	log_info "=== USER CONFIRMATION ==="
	confirm_disk
	echo

	log_info "=== DISK OPERATIONS ==="
	partition_disk
	format_partitions
	mount_partitions
	echo

	log_info "=== SYSTEM INSTALLATION ==="
	install_base_system
	update_xbps_and_system
	install_additional_packages
	echo

	log_info "=== SYSTEM CONFIGURATION ==="
	configure_system
	generate_fstab
	configure_dracut
	configure_dns
	configure_nftables
	enable_services
	configure_pipewire
	configure_zram
	echo

	log_info "=== CHROOT OPERATIONS ==="
	chroot_reconfigure
	set_root_password
	create_user
	install_bootloader
	echo

	log_info "=== DOTFILES ==="
	setup_dotfiles
	echo

	log_info "=== NIX ==="
	setup_nix

	log_info "=== COPYING XORG CONFIG FILE ==="
	setup_xorg_conf
	echo

	log_info "=== CLEANUP ==="
	cleanup
	echo

	show_summary

	log_info "Installation completed successfully!"
	echo
	echo "You can now reboot into your new Void Linux system."
	echo "Remove the installation media before rebooting."
	echo
	read -rp "Reboot now? (y/N): " answer

	if [[ "$answer" =~ ^[Yy]$ ]]; then
		log_info "Rebooting..."
		reboot
	else
		log_info "Remember to reboot before using the system!"
	fi
}

main "$@"
