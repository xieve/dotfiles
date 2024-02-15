{ config, lib, pkgs, ... }:

{
	config = {
		nix = {
			package = pkgs.nixFlakes;
			extraOptions = ''
				experimental-features = nix-command flakes
			'';
		};

		# TZ & Locale
		time.timeZone = "Europe/Berlin";

		i18n.defaultLocale = "en_US.UTF-8";

		i18n.extraLocaleSettings = {
			LC_ADDRESS = "de_DE.UTF-8";
			LC_IDENTIFICATION = "de_DE.UTF-8";
			LC_MEASUREMENT = "de_DE.UTF-8";
			LC_MONETARY = "de_DE.UTF-8";
			LC_NAME = "de_DE.UTF-8";
			LC_NUMERIC = "de_DE.UTF-8";
			LC_PAPER = "de_DE.UTF-8";
			LC_TELEPHONE = "de_DE.UTF-8";
			LC_TIME = "de_DE.UTF-8";
		};

		# Default user
		users.users.xieve = {
			isNormalUser = true;
			description = "xieve";
			extraGroups = [ "wheel" ];
			# User pkgs
			packages = with pkgs; [
				dnsutils
				mosh
			];
		};

		# zsh & direnv
		environment.shells = with pkgs; [
			bashInteractive
			zsh
		];
		programs = {
			zsh.enable = true;
			direnv.enable = true;
		};
		users.defaultUserShell = pkgs.zsh;

		# allow unfree pkgs
		nixpkgs.config.allowUnfree = true;

		# system pkgs
		environment.systemPackages = with pkgs; [
			git
			htop
			killall
			neovim
			python3
			tmux
			unzip
			zsh
		];
	};
	
	# If NM is enabled, allow default user to manage it
	config.users.groups.networkmanager.members = lib.mkIf config.networking.networkmanager.enable [ "xieve" ];
}
