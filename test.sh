#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HOSTNAME="rnoba"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
KEYMAP="us"
BOOTLOADER="grub"
TARGET_DISK="/dev/nvme0n1"
BOOT_SIZE="1G"

VOID_REPO="https://repo-default.voidlinux.org/current"
ARCH="x86_64"
XBPS_ARCH="$ARCH"

PACKAGES=(
    base-system
    grub
    grub-x86_64-efi
    efibootmgr
    
    NetworkManager
    network-manager-applet
    
    pipewire
    pipewire-pulse
    
    p7zip
    unzip
    
    alacritty
    zsh
    tmux
    
    i3
    dmenu
    
    firefox
    mpv
    neovim
    flameshot
    
    base-devel
    gcc
    clang
    git
    curl
    direnv
    
    noto-fonts-ttf
    noto-fonts-cjk
    noto-fonts-emoji
    nerd-fonts
    
    nvidia
    nvidia-libs-32bit
    vulkan-loader
    vulkan-tools
    
    ripgrep
    xclip
    
    xorg
    xorg-server
)

log_info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1"; exit 1; }

check_root() {
    [[ $EUID -eq 0 ]] || log_error "This script must be run as root"
}

check_uefi() {
    [[ -d /sys/firmware/efi ]] || log_error "This script requires UEFI boot mode"
}

confirm_disk() {
    log_warn "This will WIPE all data on $TARGET_DISK"
    lsblk "$TARGET_DISK"
    echo
    read -p "Continue? (type 'YES' to confirm): " confirm
    [[ "$confirm" == "YES" ]] || log_error "Installation cancelled"
}

partition_disk() {
    log_info "Partitioning $TARGET_DISK..."
    
    wipefs -af "$TARGET_DISK"
    sgdisk -Z "$TARGET_DISK"
    
    parted -s "$TARGET_DISK" mklabel gpt
    
    parted -s "$TARGET_DISK" mkpart primary fat32 1MiB "$BOOT_SIZE"
    parted -s "$TARGET_DISK" set 1 esp on
    
    parted -s "$TARGET_DISK" mkpart primary ext4 "$BOOT_SIZE" 100%
    
    sleep 2
    partprobe "$TARGET_DISK"
    sleep 2
    
    log_info "Partitioning complete"
}

format_partitions() {
    log_info "Formatting partitions..."
    
    mkfs.vfat -F32 "${TARGET_DISK}p1"
    
    mkfs.ext4 -F "${TARGET_DISK}p2"
    
    log_info "Formatting complete"
}

mount_partitions() {
    log_info "Mounting partitions..."
    
    mount "${TARGET_DISK}p2" /mnt
    mkdir -p /mnt/boot
    mount "${TARGET_DISK}p1" /mnt/boot
    
    log_info "Partitions mounted"
}

install_base_system() {
    log_info "Installing Void Linux base system..."
    
    export XBPS_ARCH="$ARCH"
    
    XBPS_ARCH="$ARCH" xbps-install -Sy -R "$VOID_REPO" -r /mnt base-system
    
    log_info "Base system installed"
}

install_packages() {
    log_info "Installing additional packages..."
    
    mkdir -p /mnt/var/db/xbps/keys
    cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
    
    XBPS_ARCH="$ARCH" xbps-install -Sy -R "$VOID_REPO" -r /mnt "${PACKAGES[@]}"
    
    log_info "Package installation complete"
}

configure_system() {
    log_info "Configuring system..."
    
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    cat > /mnt/etc/hosts <<-EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
    
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    echo "$LOCALE UTF-8" >> /mnt/etc/default/libc-locales
    
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    
    cat > /mnt/etc/fstab <<-EOF
# <file system> <dir> <type> <options> <dump> <pass>
${TARGET_DISK}p2  /       ext4    defaults              0 1
${TARGET_DISK}p1  /boot   vfat    defaults              0 2
tmpfs             /tmp    tmpfs   defaults,nosuid,nodev 0 0
EOF
    
    log_info "System configuration complete"
}

configure_dracut() {
    log_info "Configuring dracut..."
    
    mkdir -p /mnt/etc/dracut.conf.d
    
    cat > /mnt/etc/dracut.conf.d/10-hostonly.conf <<-EOF
hostonly=yes
hostonly_cmdline=yes
EOF
    
    log_info "Dracut configured"
}

setup_chroot() {
    log_info "Preparing chroot environment..."
    
    mount -t proc proc /mnt/proc
    mount -t sysfs sys /mnt/sys
    mount -o bind /dev /mnt/dev
    mount -t devpts pts /mnt/dev/pts
    
    cp /etc/resolv.conf /mnt/etc/
    
    log_info "Chroot environment ready"
}

chroot_commands() {
    log_info "Executing chroot commands..."
    
    chroot /mnt /bin/bash <<-'CHROOTCMD'
        # Generate locales
        xbps-reconfigure -f glibc-locales
        
        # Update initramfs
        xbps-reconfigure -fa
CHROOTCMD
    
    log_info "Chroot commands executed"
}

install_bootloader() {
    log_info "Installing GRUB bootloader..."
    
    chroot /mnt /bin/bash <<-CHROOTCMD
        # Install GRUB for UEFI
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=void --recheck
        
        # Generate GRUB config
        grub-mkconfig -o /boot/grub/grub.cfg
CHROOTCMD
    
    log_info "Bootloader installed"
}

configure_services() {
    log_info "Enabling services..."
    
    chroot /mnt /bin/bash <<-'CHROOTCMD'
        # Enable NetworkManager
        ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
        
        # Enable D-Bus
        ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
        
        # Enable elogind (session management)
        ln -sf /etc/sv/elogind /etc/runit/runsvdir/default/
CHROOTCMD
    
    log_info "Services enabled"
}

configure_zram() {
    log_info "Configuring zram swap..."
    
    cat > /mnt/etc/rc.local <<-'EOF'
#!/bin/sh
# Load zram module
modprobe zram

# Set zram size (half of RAM)
echo $(awk '/MemTotal/ {print int($2*1024*0.5)}' /proc/meminfo) > /sys/block/zram0/disksize

# Set compression algorithm
echo zstd > /sys/block/zram0/comp_algorithm

# Format and enable swap
mkswap /dev/zram0
swapon /dev/zram0 -p 100
EOF
    
    chmod +x /mnt/etc/rc.local
    
    log_info "Zram configured"
}

set_root_password() {
    log_info "Set root password..."
    echo "Enter root password:"
    chroot /mnt passwd root
}

cleanup() {
    log_info "Cleaning up..."
    
    umount -l /mnt/dev/pts
    umount -l /mnt/dev
    umount -l /mnt/sys
    umount -l /mnt/proc
    
    umount -R /mnt
    
    log_info "Cleanup complete"
}

main() {
    log_info "Starting Void Linux installation..."
    
    check_root
    check_uefi
    confirm_disk
    
    partition_disk
    format_partitions
    mount_partitions
    install_base_system
    install_packages
    configure_system
    # configure_dracut
    setup_chroot
    chroot_commands
    install_bootloader
    configure_services
    configure_zram
    set_root_password
    
    log_info "Installation complete!"
    echo
    echo "Next steps:"
    echo "  1. Reboot into your new Void Linux system"
    echo "  2. Login as root with the password you set"
    echo "  3. Create your user account:"
    echo "     ${GREEN}useradd -m -G wheel,audio,video,input -s /bin/zsh yourusername${NC}"
    echo "     ${GREEN}passwd yourusername${NC}"
    echo "  4. Enable sudo for wheel group:"
    echo "     ${GREEN}visudo${NC} (uncomment %wheel ALL=(ALL:ALL) ALL)"
    echo "  5. Login as your user and run your post-install script"
    echo
    read -p "Reboot now? (y/n): " reboot
    
    cleanup
    
    if [[ "$reboot" == "y" || "$reboot" == "Y" ]]; then
        reboot
    fi
}

main "$@"
