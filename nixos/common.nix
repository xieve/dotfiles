{ config, lib, pkgs, ... }:

with lib;
let
  getNixFiles = dir:
    (filter
      (file: hasSuffix ".nix" file)
      (lib.filesystem.listFilesRecursive dir)
    );
in {
  imports = getNixFiles ./services;


  # Enable flakes
  nix = {
    package = pkgs.nixFlakes;
    settings.experimental-features = "nix-command flakes";
  };


  # Bootloader
  boot.loader = mkIf (!((config ? wsl) && config.wsl.enable)) {
    systemd-boot.enable = lib.mkDefault true;
    efi.canTouchEfiVariables = lib.mkDefault true;
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

  services.xserver.xkb.layout = "us";


  # Default user
  users.users.xieve = {
    isNormalUser = true;
    description = "xieve";
    extraGroups = [ "wheel" "dialout" ];
    # User pkgs
    packages = with pkgs; [
      p7zip
      black
      dnsutils
      fd
      git-crypt
      neofetch
      ripgrep
      tree
    ];
  };

  # If NM is enabled, allow default user to manage it
  users.groups.networkmanager.members = lib.mkIf config.networking.networkmanager.enable [ "xieve" ];
  # Workaround for https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];


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
    smartmontools
    tmux
    unzip
    usbutils
    zsh
  ];


  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
