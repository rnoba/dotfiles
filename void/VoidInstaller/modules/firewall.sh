#!/usr/bin/env bash

MODULE_NAME="firewall"
MODULE_DESCRIPTION="Configure nftables firewall"
MODULE_DEPENDS=("base")

firewall_run() {
	log_info "=== FIREWALL CONFIGURATION ==="

	firewall_config
	firewall_enable
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

	log_inf "nftables enabled"
}
