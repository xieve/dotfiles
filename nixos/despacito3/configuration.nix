{ config, pkgs, ... }:

{
	imports = [
		./hardware.nix
		../common.nix
	];


	networking = {
		hostName = "despacito3";
		networkmanager.enable = true;
	};


	hardware.bluetooth = {
		enable = true;
		powerOnBoot = false;
	};


	# Hardware decoding
	nixpkgs.config.packageOverrides = pkgs: {
		intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
	};

	hardware.opengl = {
		enable = true;
		extraPackages = with pkgs; [
			intel-media-driver # LIBVA_DRIVER_NAME=iHD
			#intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
			vaapiVdpau
			libvdpau-va-gl
		];
	};

	environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver


	# nix-ld, needed this for a cursed risc v gcc binary at gpn22
	programs.nix-ld.enable = true;


	services = {
		# Desktop stuff
		xserver = {
			enable = true;
			desktopManager.plasma5.enable = true;
		};

		displayManager = {
			sddm.enable = true;
			defaultSession = "plasmawayland";
		};

		# Enable CUPS
		printing.enable = true;


		syncthing = {
			enable = true;
			user = "xieve";
			dataDir = "/home/xieve";
			openDefaultPorts = true;
			configDir = "/home/xieve/.config/syncthing";
		};


		tailscale = {
			enable = true;
			extraUpFlags = [
				"--operator=xieve"
			];
			useRoutingFeatures = "client";
		};
	};


	# Enable sound with pipewire.
	sound.enable = true;
	hardware.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		# If you want to use JACK applications, uncomment this
		#jack.enable = true;

		# use the example session manager (no others are packaged yet so this is enabled by default,
		# no need to redefine it in your config for now)
		#media-session.enable = true;
	};


	# User pkgs
	users.users.xieve = {
		packages = with pkgs; [
			(nerdfonts.override { fonts = [ "FiraCode" "NerdFontsSymbolsOnly" ]; })
			bespokesynth
			dolphin-emu
			fira-code
			firefox
			flavours
			kate
			keepassxc
			maliit-keyboard
			moonlight-qt
			obsidian
			syncthingtray
			vscodium
			wezterm
			wineWowPackages.stagingFull
			yabridge
			yabridgectl
		];
	};


	# Dolphin emu udev rules (allow direct bluetooth access)
	services.udev.packages = [ pkgs.dolphinEmu ];


	# Steam
	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true;
	};


	systemd.user.services.trayscale = {
		script = "sleep 5; trayscale --hide-window";
		wantedBy = [ "xdg-desktop-autostart.target" ];
		path = [ pkgs.trayscale ];
	};


	# temp workaround until obsidian gets their shit together
	nixpkgs.config.permittedInsecurePackages = pkgs.lib.optional (pkgs.obsidian.version == "1.5.3") "electron-25.9.0";
}
