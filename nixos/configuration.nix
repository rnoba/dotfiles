{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  powerManagement.powertop.enable = true;

  networking.hostName = "rnoba";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
  	font = "sun12x22";
  	useXkbConfig = true;
  };

  services.xserver = {
	enable = true;
	displayManager = {
		defaultSession = "none+i3";
	};
	windowManager.i3 = {
		enable = true;
		extraPackages = with pkgs; [
			dmenu
			i3blocks
		];
	};

  };
  hardware.opengl =  {
	enable = true;
	extraPackages = with pkgs; [
		intel-media-driver
	];
	driSupport32Bit = true;
 };
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.libinput.enable = true;

  users.users.rnoba = {
  	isNormalUser = true;
	createHome = true;
  	extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  	packages = with pkgs; [
  		tree
		github-cli
  	];
  };
  environment.systemPackages = with pkgs; [
  	vim
  	firefox
	alacritty
  	wget
	git
	xclip
	intel-media-driver
  ];
  environment.variables.EDITOR = "${pkgs.vim}/bin/vim";
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
	roboto
	julia-mono
	font-awesome
	source-code-pro
  ];
  services.openssh.enable = true;
  system.stateVersion = "23.11"; # Did you read the comment?
}

