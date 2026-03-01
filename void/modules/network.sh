#!/usr/bin/env bash

MODULE_NAME="network"
MODULE_DESCRIPTION="Configure networking and DNS"
MODULE_DEPENDS=("base")

network_run() {
  log_info "=== NETWORK CONFIGURATION ==="
  network_dns
  network_nm_config
  network_enable_services
}

network_dns() {
  log_info "Configuring DNS..."
  
  cat > /mnt/etc/resolv.conf <<'EOF'
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
  
  mkdir -p /mnt/etc/NetworkManager/conf.d
  cat > /mnt/etc/NetworkManager/conf.d/dns.conf <<'EOF'
[main]
dns=default
rc-manager=resolvconf
EOF
  
  log_info "DNS configured"
}

network_nm_config() {
  log_info "NetworkManager configured"
}

network_enable_services() {
  log_info "Enabling network services..."
  enable_service "NetworkManager"
  enable_service "dbus"
  log_info "Network services enabled"
}
