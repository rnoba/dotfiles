#!/usr/bin/env bash

MODULE_NAME="polkit"
MODULE_DESCRIPTION="Configure polkit for wheel group"
MODULE_DEPENDS=("base")

polkit_run() {
	log_info "=== POLKIT CONFIGURATION ==="
	polkit_udisks
}

polkit_udisks() {
	log_info "Configuring polkit udisks rules..."
	
	mkdir -p /mnt/etc/polkit-1/rules.d
	
	cat > /mnt/etc/polkit-1/rules.d/10-udisks2-wheel.rules <<'EOF'
// Allow members of the wheel group to perform udisks2 actions without authentication
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" ||
        action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
        action.id == "org.freedesktop.udisks2.filesystem-unmount" ||
        action.id == "org.freedesktop.udisks2.eject-media" ||
        action.id == "org.freedesktop.udisks2.power-off-drive") {
        if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    }
});
EOF
	
	log_info "Polkit rules configured"
}
