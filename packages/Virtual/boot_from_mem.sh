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
RAM="${2:-4G}"
CPUS="${3:-4}"

if [ -z "$ISO" ]; then
  log_error "Usage: $0 <iso-file> [ram] [cpus]"
fi

[ -f "$ISO" ] || {
  log_error "ISO file not found: $ISO"
}

echo "Starting...:"
echo "ISO: $ISO"
echo "RAM: $RAM"
echo "CPUs: $CPUS"
echo ""

qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -cpu host \
  -smp "$CPUS" \
  -cdrom "$ISO" \
  -boot d \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -device qemu-xhci \
  -audiodev pa,id=snd0 \
  -device ich9-intel-hda \
  -device hda-output,audiodev=snd0 \
  -device usb-tablet \
  -display sdl,gl=on
