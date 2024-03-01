{ config, lib, pkgs, ... }:

with lib;
let
	# https://github.com/evanjs/nixos_cfg/blob/4bb5b0b84a221b25cf50853c12b9f66f0cad3ea4/config/new-modules/default.nix
	# Recursively constructs an attrset of a given folder, recursing on directories, value of attrs is the filetype
	getDir = dir: mapAttrs
		(file: type:
			if type == "directory" then getDir "${dir}/${file}" else type
		)
		(builtins.readDir dir);

	# Collects all files of a directory as a list of strings of paths
	getFiles = dir: collect isString (mapAttrsRecursive (path: type: concatStringsSep "/" path) (getDir dir));

	# Filters out directories that don't end with .nix, also makes the strings absolute
	getNixFiles = dir: map
		(file: dir + "/${file}")
		(filter (file: hasSuffix ".nix" file) (getFiles dir));
in {
	imports = getNixFiles ./services;


	# Enable flakes
	nix = {
		package = pkgs.nixFlakes;
		extraOptions = ''
			experimental-features = nix-command flakes
		'';
	};


	# Bootloader
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;


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

	services.xserver.xkb.layout = "us";


	# Default user
	users.users.xieve = {
		isNormalUser = true;
		description = "xieve";
		extraGroups = [ "wheel" ];
		# User pkgs
		packages = with pkgs; [
			dnsutils
			git-crypt
			mosh
		];
	};

	# If NM is enabled, allow default user to manage it
	users.groups.networkmanager.members = lib.mkIf config.networking.networkmanager.enable [ "xieve" ];


	# zsh & direnv
	environment.shells = with pkgs; [
		bashInteractive
		zsh
	];
	programs.zsh.enable = true;
	programs.direnv.enable = true;
	users.defaultUserShell = pkgs.zsh;


	# allow unfree pkgs
	nixpkgs.config.allowUnfree = true;


	# system pkgs
	environment.systemPackages = with pkgs; [
		git
		htop
		killall
		python3
		tmux
		unzip
		zsh
	];


	programs.neovim = {
		enable = true;
		defaultEditor = true;
	};
}
