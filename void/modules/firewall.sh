#!/usr/bin/env bash

MODULE_NAME="firewall"
MODULE_DESCRIPTION="Install & configure nftables firewall"
MODULE_DEPENDS=("base")

readonly FIREWALL_PACKAGES=(
  nftables
)

firewall_run() {
  log_info "=== FIREWALL CONFIGURATION ==="

  firewall_install_packages
  firewall_config
  firewall_enable
}

firewall_install_packages() {
  log_info "Installing firewall packages (${#FIREWALL_PACKAGES[@]})..."

  xbps-install -Sy -r /mnt -R "$VOID_REPO" "${FIREWALL_PACKAGES[@]}" || {
    log_error "Failed to install firewall packages"
    exit 1
  }

  log_info "Firewall packages installed"
}

firewall_config() {
  log_info "Configuring nftables..."
  
  cat > /mnt/etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority filter; policy drop;
    
    iif lo accept
    ct state established,related accept
    ct state invalid drop
    
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
    
    ip protocol icmp icmp type echo-request accept
    ip protocol udp udp sport 67 udp dport 68 accept
  }
  
  chain output {
    type filter hook output priority filter; policy accept;
  }
  
  chain forward {
    type filter hook forward priority filter; policy drop;
  }
}
EOF
  
  chmod +x /mnt/etc/nftables.conf
  log_info "nftables configured"
}

firewall_enable() {
  enable_service "nftables"

  log_info "nftables enabled"
}
