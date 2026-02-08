#!/usr/bin/env bash

MODULE_NAME="disk"
MODULE_DESCRIPTION="Partition and format target disk"
MODULE_DEPENDS=()

disk_run() {
  log_info "=== DISK OPERATIONS ==="
  disk_partition
  disk_partition_format
  disk_partition_mount
}

disk_partition() {
  log_info "Partitioning $TARGET_DISK..."
  
  log_debug "Wiping filesystem signatures..."
  wipefs -af "$TARGET_DISK" || { log_error "Failed to wipe partition table"; exit 1; }
  
  log_debug "Creating GPT partition table..."
  parted -s "$TARGET_DISK" mklabel gpt || { log_error "Failed to create GPT label"; exit 1; }
  
  log_debug "Creating EFI partition: $EFI_PARTLABEL"
  parted -s "$TARGET_DISK" mkpart "$EFI_PARTLABEL" fat32 1MiB "$EFI_SIZE" || { log_error "Failed to create EFI partition"; exit 1; }
  parted -s "$TARGET_DISK" set 1 esp on || { log_error "Failed to set ESP flag"; exit 1; }
  
  log_debug "Creating root partition: $ROOT_PARTLABEL"
  parted -s "$TARGET_DISK" mkpart "$ROOT_PARTLABEL" ext4 "$EFI_SIZE" 100% || { log_error "Failed to create root partition"; exit 1; }
  
  partprobe "$TARGET_DISK" 2>/dev/null || true
  sleep 1

  udevadm settle --timeout=10 || log_warn "udevadm settle timed out"
  sleep 3
  
  log_info "Partitioning completed"
}

disk_partition_format() {
  log_info "Formatting partitions..."
  
  local efi_part root_part
  
  log_debug "Waiting for EFI partition..."
  for i in {1..10}; do
    efi_part=$(findfs PARTLABEL="$EFI_PARTLABEL" 2>/dev/null) && break
    log_debug "Waiting for EFI partition... attempt $i/10"
    sleep 1
  done
  
  if [[ -z "$efi_part" ]]; then
    log_error "EFI partition not found after 10 retries"
    log_error "Available partitions:"
    lsblk "$TARGET_DISK"
    exit 1
  fi
  
  log_debug "Waiting for root partition..."
  for i in {1..10}; do
    root_part=$(findfs PARTLABEL="$ROOT_PARTLABEL" 2>/dev/null) && break
    log_debug "Waiting for root partition... attempt $i/10"
    sleep 1
  done
  
  if [[ -z "$root_part" ]]; then
    log_error "Root partition not found after 10 retries"
    log_error "Available partitions:"
    lsblk "$TARGET_DISK"
    exit 1
  fi
  
  log_info "Found partitions: EFI=$efi_part, Root=$root_part"
  
  log_debug "Formatting EFI as FAT32: $EFI_FSLABEL"
  mkfs.vfat -F32 -n "$EFI_FSLABEL" "$efi_part" || { log_error "Failed to format EFI"; exit 1; }
  
  log_debug "Formatting root as ext4: $ROOT_FSLABEL"
  mkfs.ext4 -F -L "$ROOT_FSLABEL" "$root_part" || { log_error "Failed to format root"; exit 1; }
  
  log_info "Formatting completed"
}

disk_partition_mount() {
  log_info "Mounting partitions..."
  
  mount LABEL="$ROOT_FSLABEL" /mnt || { log_error "Failed to mount root"; exit 1; }
  mkdir -p /mnt/boot || { log_error "Failed to create /boot"; exit 1; }
  mount LABEL="$EFI_FSLABEL" /mnt/boot || { log_error "Failed to mount EFI"; exit 1; }
  
  log_info "Partitions mounted successfully"
}

disk_cleanup() {
  log_info "Unmounting partitions..."
  umount -R /mnt/boot 2>/dev/null || true
  umount -R /mnt 2>/dev/null || true
}
