{ config, pkgs, fasttext-lid, ... }:

let
  home = config.users.users.xieve.home;
in
{
  imports = [
    ./vscode.nix
  ];

  environment.systemPackages =
    (with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      adwaita-icon-theme-legacy
      fira-code
      firefox
      gnome-tweaks
      keepassxc
      obsidian
      xclip # clipboard support for term apps (neovim, ssh) (works on gnome, while wl-clipboard does not)
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      blur-my-shell
      burn-my-windows
      just-perfection
      pop-shell
      steal-my-focus-window
    ])
    ++ (with pkgs.kdePackages; [
      breeze
      ocean-sound-theme
      qtstyleplugin-kvantum
    ]);

  fonts.packages = with pkgs; [
    newcomputermodern
  ];


  # TODO: this should be in like, desktop.nix or something...
  # TODO: look at TODOs xd
  networking.networkmanager.enable = true;

  boot.plymouth = {
    enable = true;
    themePackages = [
      pkgs.adi1090x-plymouth-themes
    ];
    theme = "sphere";
  };

  # Hardware decoding
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };

  hardware.graphics = {
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

    languagetool = {
      enable = true;
      port = 1337;
      settings = {
        fasttextBinary = "${pkgs.fasttext}/bin/fasttext";
        fasttextModel = fasttext-lid;
      };
    };

    # Enable CUPS
    #printing.enable = true;
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Qt Theme
  qt = {
    enable = true;
    style = "kvantum";
  };

  environment.variables = {
    # Force Firefox to use Wayland
    MOZ_ENABLE_WAYLAND = 1;
    # Force electron apps to use Wayland
    # Disabled since chromium and thus electron do not support styli on Wayland
    #ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  programs.dconf = pkgs.lib.mkIf config.services.xserver.desktopManager.gnome.enable {
    enable = true;
    profiles.user.databases = [
      {
        settings =
          let
            background = "file://${home}/Syncthing/Bilder/IMG_20200401_203137_972.jpg";
          in
          {
            # Compose Key
            "org/gnome/desktop/input-sources".xkb-options = [ "compose:ralt" ];
            # Fractional scaling
            "org/gnome/mutter".experimental-features = [
              "scale-monitor-framebuffer"
              "variable-refresh-rate"
              "xwayland-native-scaling"
            ];
            # Disable automatic backlight adjustments
            "org/gnome/settings-daemon/plugins/power".ambient-enabled = false;

            # Behaviour
            "org/gnome/desktop/wm/preferences" = {
              # Focus windows on hover
              focus-mode = "sloppy";
              # Don't raise windows when focused
              auto-raise = "false";
            };

            # Styling
            "org/gnome/desktop/background" = {
              picture-uri = background;
              picture-uri-dark = background;
            };
            "org/gnome/desktop/screensaver".picture-uri = background;
            "org/gnome/desktop/interface" = {
              font-antialiasing = "rgba";
              monospace-font-name = "FiraCode Nerd Font weight=450 10";
              cursor-theme = "breeze_cursors";
            };
            "org/gnome/desktop/sound".theme-name = "ocean";

            # Extensions
            "org/gnome/shell" = {
              disabled-user-extensions = false;
              enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
                "blur-my-shell@aunetx"
                "burn-my-windows@schneegans.github.com"
                "gsconnect@andyholmes.github.io"
                "just-perfection-desktop@just-perfection"
                "pop-shell@system76.com"
                "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
              ];
            };
            # Burn My Windows (window open & close effects)
            "org/gnome/shell/extensions/burn-my-windows".active-profile = "${home}/.config/burn-my-windows/profiles/close.conf";
            # Blur My Shell
            "org/gnome/shell/extensions/blur-my-shell/applications" = {
              blur = true;
              dynamic-opacity = false;
              whitelist = [
                "org.wezfurlong.wezterm"
                "firefox"
              ];
              opacity = pkgs.lib.gvariant.mkInt32 255;
            };
          };
      }
    ];
  };

  environment.gnome.excludePackages = (
    with pkgs;
    [
      gnome-tour
      epiphany # browser
      geary # email
    ]
  );
}
