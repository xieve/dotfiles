{
  config,
  pkgs,
  lib,
  fasttext-lid,
  ...
}:

{
  imports = [
    ./vscode.nix
  ];

  environment.systemPackages =
    (with pkgs; [
      adw-gtk3
      adwaita-icon-theme-legacy
      firefox
      gnome-tweaks
      keepassxc
      mpv
      obsidian
      piper
      xclip # clipboard support for term apps (neovim, ssh) (works on gnome, while wl-clipboard does not)
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      blur-my-shell
      burn-my-windows
      gjs-osk
      just-perfection
      pop-shell
      removable-drive-menu
      steal-my-focus-window
    ])
    ++ (with pkgs.kdePackages; [
      breeze
      ocean-sound-theme
      qtstyleplugin-kvantum
    ]);

  fonts.packages = with pkgs; [
    fira-code
    inter
    nerd-fonts.fira-code
    newcomputermodern
  ];

  # TODO: this should be in like, desktop.nix or something...
  # TODO: look at TODOs xd
  networking.networkmanager.enable = true;

  boot = {
    plymouth = {
      enable = true;
      themePackages = [
        pkgs.adi1090x-plymouth-themes
      ];
      theme = "sphere";
    };
    # Display Plymouth via UEFI framebuffer ("flicker-free boot")
    kernelParams = [
      "plymouth.use-simpledrm"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;

    # Backlight control driver for external monitors via DDC/CI
    extraModulePackages = with config.boot.kernelPackages; [
      ddcci-driver
    ];
    kernelModules = [ "ddcci" ];
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

    # Logitech devices daemon (for piper)
    ratbagd.enable = true;
  };

  # Enable sound with pipewire.
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

  programs.dconf = {
    enable = true;
    profiles.user.databases = [ { settings = import ./dconf.nix { inherit lib config; }; } ];
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
