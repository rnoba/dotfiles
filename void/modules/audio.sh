#!/usr/bin/env bash

MODULE_NAME="audio"
MODULE_DESCRIPTION="Install and configure PipeWire audio"
MODULE_DEPENDS=("base")

readonly AUDIO_PACKAGES=(
  pipewire
  wireplumber
  pavucontrol
  speech-dispatcher
)

audio_run() {
  log_info "=== AUDIO CONFIGURATION ==="
  audio_install
  audio_configure
}

audio_install() {
  log_info "Installing audio packages..."
  install_packages "${AUDIO_PACKAGES[@]}"
}

audio_configure() {
  log_info "Configuring PipeWire..."

  mkdir -p /mnt/etc/pipewire/pipewire.conf.d

  ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf \
    /mnt/etc/pipewire/pipewire.conf.d/10-wireplumber.conf

  ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf \
    /mnt/etc/pipewire/pipewire.conf.d/20-pipewire-pulse.conf

  log_info "PipeWire configured"
}
