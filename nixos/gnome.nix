{ config, pkgs, ... }:

let
	home = config.users.users.xieve.home;
in {
	users.users.xieve.packages = (with pkgs; [
		(nerdfonts.override { fonts = [ "FiraCode" ]; })
		fira-code
		firefox
		keepassxc
		obsidian
		vscodium
		xclip  # clipboard support for term apps (neovim, ssh) (works on gnome, while wl-clipboard does not)
	]) ++ (with pkgs.gnomeExtensions; [
		appindicator
		blur-my-shell
		burn-my-windows
		just-perfection
		pop-shell
		steal-my-focus-window
	]);


	networking.networkmanager.enable = true;


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


	services = {
		xserver = {
			enable = true;
			desktopManager.gnome.enable = true;
			displayManager.gdm.enable = true;
		};

		# Enable CUPS
		printing.enable = true;
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
	};


	# Force Firefox to use Wayland
	environment.variables = {
		MOZ_ENABLE_WAYLAND = 1;
	};


	programs.dconf = pkgs.lib.mkIf config.services.xserver.desktopManager.gnome.enable {
		enable = true;
		profiles.user.databases = [{
			settings = let
				background = "file://${home}/Syncthing/Bilder/IMG_20200401_203137_972.jpg";
			in {
				# Enable fractional scaling
				"org/gnome/mutter".experimental-features = [ "scale-monitor-framebuffer" ];
				"org/gnome/shell" = {
					disabled-user-extensions = false;
					enabled-extensions = [
						"appindicatorsupport@rgcjonas.gmail.com"
						"blur-my-shell@aunetx"
						"burn-my-windows@schneegans.github.com"
						"just-perfection-desktop@just-perfection"
						"pop-shell@system76.com"
						#"steal-my-focus-window@steal-my-focus-window"
						"windowsNavigator@gnome-shell-extensions.gcampax.github.com"
					];
				};
				"org/gnome/desktop/background" = {
					picture-uri = background;
					picture-uri-dark = background;
				};
				"org/gnome/desktop/screensaver".picture-uri = background;
				"org/gnome/desktop/interface" = {
					font-antialiasing = "rgba";
					monospace-font-name = "FiraCode Nerd Font weight=450 10";
				};
				"org/gnome/desktop/wm/preferences" = {
					focus-mode = "sloppy";
					auto-raise = "false";
				};
				"org/gnome/shell/extensions/burn-my-windows".active-profile = "${home}/.config/burn-my-windows/profiles/close.conf";
				"org/gnome/shell/extensions/blur-my-shell/applications" = {
					blur = true;
					dynamic-opacity = false;
					whitelist = [ "org.wezfurlong.wezterm" ];
					opacity = pkgs.lib.gvariant.mkInt32 255;
				};
				"org/gnome/settings-daemon/plugins/power".ambient-enabled = false;
			};
		}];
	};

	environment.gnome.excludePackages = (with pkgs; [
		gnome-tour
	]) ++ (with pkgs.gnome; [
		epiphany  # browser
		geary  # email
	]);
}
