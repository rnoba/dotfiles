#!/usr/bin/env bash

PROFILE_NAME="desktop"
PROFILE_DESCRIPTION="Full desktop with xorg, i3, NVIDIA, and development tools"

PROFILE_MODULES=(
	disk
	base
	network
	firewall
	audio
	xorg
	i3
	nvidia
	fonts
	dev
	firefox
	zram
	user
	bootloader
	dotfiles
	nix
	polkit
)
