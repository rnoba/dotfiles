#!/usr/bin/env bash

MODULE_NAME="bootloader"
MODULE_DESCRIPTION="Install and configure GRUB bootloader"
MODULE_DEPENDS=("base")

bootloader_run() {
	log_info "=== BOOTLOADER INSTALLATION ==="

	bootloader_grub_cfg
	bootloader_install
}

bootloader_grub_cfg() {
	log_info "Configuring GRUB..."
	
	cat > /mnt/etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4"
GRUB_DISABLE_OS_PROBER=false
EOF
	
	log_info "GRUB config created"
}

bootloader_install() {
	log_info "Installing GRUB..."
	
	chroot_exec "
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Void --recheck
		grub-mkconfig -o /boot/grub/grub.cfg
	"
	
	log_info "GRUB installed successfully"
}
