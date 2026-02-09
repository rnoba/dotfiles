#!/usr/bin/env bash

log_error() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  log_error "QEMU not installed (qemu-system-x86_64 not found)"
}

command -v qemu-img >/dev/null 2>&1 || {
  log_error "qemu-img not found — please install qemu-img / qemu-utils"
}

ISO="$1"
DISK_IMAGE="$2"
DISK_SIZE="${3:-50G}"
RAM="${4:-4G}"
CPUS="${5:-4}"

if [ -z "$ISO" ] || [ -z "$DISK_IMAGE" ]; then
  log_error "Usage: $0 <iso-file> <qcow2-image> [disk-size] [ram] [cpus]"
fi

[ -f "$ISO" ] || {
  log_error "ISO file not found: $ISO"
}

if [ ! -f "$DISK_IMAGE" ]; then
  echo "Creating new qcow2 disk: $DISK_IMAGE ($DISK_SIZE)"
  qemu-img create -f qcow2 "$DISK_IMAGE.qcow2" "$DISK_SIZE" || {
    log_error "Failed to create disk image"
  }
fi

echo "Starting...:"
echo "ISO: $ISO"
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
  -cdrom "$ISO" \
  -boot d \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -device qemu-xhci \
  -device ich9-intel-hda \
  -device hda-output \
  -device usb-tablet \
  -device virtio-vga-gl \
  -display sdl,gl=on
