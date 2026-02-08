#!/usr/bin/env bash

MODULE_NAME="nvidia"
MODULE_DESCRIPTION="Install NVIDIA proprietary drivers and configure hardware"
MODULE_DEPENDS=("base")

readonly NVIDIA_PACKAGES=(
	nvidia
	nvidia-vaapi-driver
	libva
	libva-utils
	mesa-vaapi
	vulkan-loader
	Vulkan-Tools
)

nvidia_run() {
	log_info "=== NVIDIA CONFIGURATION ==="

	nvidia_install
	nvidia_configure_kernel
	nvidia_configure_modprobe
}

nvidia_install() {
	log_info "Installing NVIDIA packages..."
	install_packages "${NVIDIA_PACKAGES[@]}"
}

nvidia_configure_kernel() {
	log_info "Configuring NVIDIA kernel modules..."
	
	mkdir -p /mnt/etc/modprobe.d
	
	cat > /mnt/etc/modprobe.d/blacklist-nouveau.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
	
	cat > /mnt/etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia-drm modeset=1
EOF
	
	log_info "NVIDIA kernel modules configured"
}

nvidia_configure_modprobe() {
	log_info "NVIDIA modprobe configured"
}
