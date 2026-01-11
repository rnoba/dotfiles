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
TARGET_DISK="/dev/nvme0n1"           # ← change as needed
EFI_SIZE="512M"                      # ← more reasonable size
VOID_REPO="https://repo-default.voidlinux.org/current"
ARCH="x86_64"

PACKAGES=(
    base-system grub grub-x86_64-efi efibootmgr dosfstools
    NetworkManager network-manager-applet
    pipewire pipewire-pulse
    p7zip unzip
    alacritty zsh tmux
    i3 dmenu
    firefox mpv neovim flameshot
    base-devel gcc clang git curl direnv
    noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji nerd-fonts
    nvidia nvidia-libs-32bit vulkan-loader vulkan-tools
    ripgrep xclip
    xorg xorg-server
)

log_info()  { printf "%b[INFO]%b %s\n"  "$GREEN" "$NC" "$1"; }
log_warn()  { printf "%b[WARN]%b %s\n"  "$YELLOW" "$NC" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "$RED"   "$NC" "$1"; exit 1; }

check_root()  { [[ $EUID -eq 0 ]] || log_error "Must run as root"; }
check_uefi()  { [[ -d /sys/firmware/efi ]] || log_error "UEFI mode required"; }

get_part() {
    local disk="$1" num="$2"
    if [[ $disk =~ nvme || $disk =~ mmcblk ]]; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

confirm_disk() {
    log_warn "This will **WIPE ALL DATA** on $TARGET_DISK !"
    lsblk -f "$TARGET_DISK"
    echo
    read -p "Type YES to continue: " ans
    [[ $ans == "YES" ]] || log_error "Aborted."
}

partition_disk() {
    log_info "Partitioning $TARGET_DISK..."
    wipefs -af "$TARGET_DISK"
    sgdisk -Z "$TARGET_DISK"
    parted -s "$TARGET_DISK" mklabel gpt
    parted -s "$TARGET_DISK" mkpart ESP     fat32  1MiB      "$EFI_SIZE"
    parted -s "$TARGET_DISK" set 1 esp on
    parted -s "$TARGET_DISK" mkpart primary ext4  "$EFI_SIZE" 100%
    sleep 2; partprobe "$TARGET_DISK"; sleep 2
    log_info "Partitioning done."
}

format_partitions() {
    log_info "Formatting..."
    local efi_part=$(get_part "$TARGET_DISK" 1)
    local root_part=$(get_part "$TARGET_DISK" 2)

    mkfs.vfat -F32 "$efi_part"
    mkfs.ext4 -F "$root_part"

    EFI_UUID=$(blkid -s UUID -o value "$efi_part")
    ROOT_UUID=$(blkid -s UUID -o value "$root_part")

    log_info "UUIDs → EFI: $EFI_UUID   Root: $ROOT_UUID"
}

mount_partitions() {
    log_info "Mounting..."
    mount "$TARGET_DISK"p2 /mnt   # or use UUID if you prefer
    mkdir -p /mnt/boot/efi
    mount "$TARGET_DISK"p1 /mnt/boot/efi
    log_info "Mounted."
}

# ... (install_base_system, install_packages, configure_system stay similar)

configure_system() {
    log_info "Configuring system..."

    echo "$HOSTNAME" > /mnt/etc/hostname

    cat > /mnt/etc/hosts <<-EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    echo "$LOCALE UTF-8" >> /mnt/etc/default/libc-locales
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

    cat > /mnt/etc/fstab <<-EOF
# <file system>                        <dir>       <type>  <options>              <dump> <pass>
UUID=$ROOT_UUID  /               ext4    defaults,noatime       0      1
UUID=$EFI_UUID   /boot/efi       vfat    defaults,noatime,umask=0077 0      2
tmpfs            /tmp            tmpfs   defaults,nosuid,nodev  0      0
EOF

    log_info "System configured (using UUIDs — recommended)."
}

install_bootloader() {
    log_info "Installing GRUB..."
    chroot /mnt /bin/bash <<-CHROOTCMD
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void --recheck
        grub-mkconfig -o /boot/grub/grub.cfg
CHROOTCMD
    log_info "Bootloader done."
}

# ... rest of the functions (dracut, services, zram, password, cleanup) remain good

main() {
    check_root
    check_uefi
    confirm_disk
    partition_disk
    format_partitions
    mount_partitions
    install_base_system
    install_packages
    configure_system
    configure_dracut
    setup_chroot
    chroot_commands
    install_bootloader
    configure_services
    configure_zram
    set_root_password

    log_info "Installation FINISHED!"
    echo "Reboot? (y/N)"
    read -r ans
    cleanup
    [[ $ans =~ ^[Yy]$ ]] && reboot
}

main "$@"
