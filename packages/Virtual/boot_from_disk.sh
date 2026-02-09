#!/usr/bin/env bash

log_error() {
  echo "ERROR: $*" >&2
  exit 1
}

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then 
  log_error "QEMU not installed"
  exit 1
fi

DISK_IMAGE="$1"

[ -f "$DISK_IMAGE" ] || { echo "ERROR: IMAGE file '$DISK_IMAGE' not found"; exit 1; }

echo "Starting...:"
echo "Disk: $DISK_IMAGE"
echo "RAM: $RAM"
echo "CPUsc: $CPUS"
echo ""

qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -cpu host \
  -smp "$CPUS" \
  -drive file="$DISK_IMAGE",format=qcow2,if=virtio \
  -boot c \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -device qemu-xhci \
  -device ich9-intel-hda \
  -device hda-output \
  -device usb-tablet \
  -device virtio-vga-gl \
  -display sdl,gl=on
