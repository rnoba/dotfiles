#!/usr/bin/env bash

MODULE_NAME="zram"
MODULE_DESCRIPTION="Configure zram swap"
MODULE_DEPENDS=("base")

zram_run() {
  log_info "=== ZRAM CONFIGURATION ==="
  zram_configure
}

zram_configure() {
  log_info "Configuring zram swap (50% of RAM with zstd)..."
  
  cat > /mnt/etc/rc.local <<'EOF'
#!/bin/sh
# zram swap configuration

modprobe zram
echo zstd > /sys/block/zram0/comp_algorithm
echo $(awk '/MemTotal/ {printf "%.0f", $2 * 0.5 * 1024}' /proc/meminfo) > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0 -p 100
EOF
  
  chmod +x /mnt/etc/rc.local
  log_info "zram configured"
}
