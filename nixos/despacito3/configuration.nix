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


	services = {
		# Desktop stuff
		xserver = {
			enable = true;

			displayManager = {
				sddm.enable = true;
				defaultSession = "plasmawayland";
			};
			desktopManager.plasma5.enable = true;
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
			fira-code
			firefox
			kate
			keepassxc
			kitty
			obsidian
			syncthingtray
			vscodium
		];
	};


	systemd.user.services.trayscale = {
		script = "sleep 5; trayscale --hide-window";
		wantedBy = [ "xdg-desktop-autostart.target" ];
		path = [ pkgs.trayscale ];
	};


	# temp workaround until obsidian gets their shit together
	nixpkgs.config.permittedInsecurePackages = pkgs.lib.optional (pkgs.obsidian.version == "1.5.3") "electron-25.9.0";
}
