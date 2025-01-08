{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  imports = lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") ./modules);

  # Enable flakes
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # Optimise system nix store and collect garbage on every rebuild
  system.userActivationScripts.optimise-storage = ''
    nix-store --optimise
    nix-collect-garbage --delete-older-than 30d
  '';

  # Bootloader
  boot.loader = mkIf (!((config ? wsl) && config.wsl.enable)) {
    systemd-boot.enable = mkDefault true;
    efi.canTouchEfiVariables = mkDefault true;
  };

  # When RAM fills up, compress it before swapping to disk
  zramSwap.enable = mkDefault true;

  # Recommended by docs, default enabled only for backwards compat
  boot.zfs.forceImportRoot = false;

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
    extraGroups = [
      "wheel"
      "dialout"
    ];
    # User pkgs
    packages = with pkgs; [
      black
      dnsutils
      fastfetch
      fd
      git-crypt
      p7zip
      ripgrep
      tree
    ];
  };

  # If NM is enabled, allow default user to manage it
  users.groups.networkmanager.members = mkIf config.networking.networkmanager.enable [ "xieve" ];
  # Workaround for https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [
    ""
    "${pkgs.networkmanager}/bin/nm-online -q"
  ];

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
    nixfmt-rfc-style
    python3
    smartmontools
    tmux
    unzip
    usbutils
    wget
    zsh
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      # Workaround for https://github.com/NixOS/nixpkgs/issues/177375
      customRC = ''
        source ~/.config/nvim/init.lua
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        opt = [
          nvim-autopairs
          nvim-treesitter.withAllGrammars
          nvim-ts-autotag
          vim-matchup
          which-key-nvim
        ];
      };
    };
  };

  # This way, we can run the tailscale CLI as user (if the service is enabled for the host)
  services.tailscale.extraUpFlags = [ "--operator=xieve" ];

  # This will break nixos-rebuild on system which don't have my dotfiles cloned
  # to this location, but you can always resort to specifying the config
  # location manually.
  environment.etc."nixos/flake.nix".source = "/home/xieve/.dotfiles/nixos/flake.nix";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
