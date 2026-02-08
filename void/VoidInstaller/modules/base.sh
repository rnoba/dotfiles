#!/usr/bin/env bash

MODULE_NAME="base"
MODULE_DESCRIPTION="Install base system and core packages"
MODULE_DEPENDS=("disk")

readonly BASE_PACKAGES=(
	base-system
	void-repo-nonfree
	void-repo-multilib
	grub
	grub-x86_64-efi
	efibootmgr
	dosfstools
	NetworkManager
	network-manager-applet
	dhcpcd
	openresolv
	dbus
	elogind
	polkit
	xtools
	sudo
	bash
)

base_run() {
	log_info "=== BASE SYSTEM INSTALLATION ==="

	base_install_system
	base_update
	base_install_packages
	base_configure
	base_fstab
	base_dracut
}

base_install_system() {
	log_info "Installing base-system..."
	
	mkdir -p /mnt/var/db/xbps/keys
	[[ -d /var/db/xbps/keys ]] && cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/ 2>/dev/null || true
	
	XBPS_ARCH="$ARCH" xbps-install -Sy -r /mnt -R "$VOID_REPO" base-system void-repo-nonfree void-repo-multilib || {
		log_error "Failed to install base-system"
		exit 1
	}
	
	log_info "base-system installed"
}

base_update() {
	log_info "Updating XBPS and system packages..."
	xbps-install -r /mnt -Su xbps || { log_error "Failed to update XBPS"; exit 1; }
	xbps-install -r /mnt -Su || { log_error "Failed to update system"; exit 1; }
	log_info "System updated"
}

base_install_packages() {
	log_info "Installing base packages (${#BASE_PACKAGES[@]})..."

	xbps-install -Sy -r /mnt -R "$VOID_REPO" "${BASE_PACKAGES[@]}" || {
		log_error "Failed to install base packages"
		exit 1
	}

	log_info "Base packages installed"
}

base_configure() {
	log_info "Configuring base system..."
	
	echo "$HOSTNAME" > /mnt/etc/hostname
	
	cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
	
	echo "$LOCALE UTF-8" > /mnt/etc/default/libc-locales
	echo "LANG=$LOCALE" > /mnt/etc/locale.conf
	ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
	
	cat > /mnt/etc/rc.conf <<EOF
HARDWARECLOCK="UTC"
KEYMAP="$KEYMAP"
EOF
	
	log_info "Base configuration completed"
}

base_fstab() {
	log_info "Generating fstab..."
	
	if ! command -v xgenfstab &>/dev/null; then
		log_error "xgenfstab not found. Is xtools installed?"
		exit 1
	fi
	
	xgenfstab -L /mnt > /mnt/etc/fstab || { log_error "Failed to generate fstab"; exit 1; }
	log_info "fstab generated"
}

base_dracut() {
	log_info "Configuring dracut..."
	mkdir -p /mnt/etc/dracut.conf.d
	cat > /mnt/etc/dracut.conf.d/10-hostonly.conf <<'EOF'
hostonly=yes
hostonly_cmdline=yes
EOF
	log_info "Dracut configured"
}

base_chroot() {
	log_info "Reconfiguring packages in chroot..."
	chroot_exec "xbps-reconfigure -f glibc-locales && xbps-reconfigure -fa"
	log_info "Package reconfiguration completed"
}
