{ config, pkgs, ... }:

let
  home = config.users.users.xieve.home;
in {
  imports = [
    ./hardware.nix
    ../common.nix
    ../gnome.nix
  ];


  networking = {
    hostName = "despacito3";
  };


  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable screen rotation
    sensor.iio.enable = true;
  };

  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver


  services = {
    syncthing = {
      enable = true;
      user = "xieve";
      dataDir = home;
      openDefaultPorts = true;
      configDir = "${home}/.config/syncthing";
    };


    tailscale = {
      enable = true;
      extraUpFlags = [
        "--operator=xieve"
      ];
      useRoutingFeatures = "client";
    };
  };


  # User pkgs
  users.users.xieve.packages = with pkgs; [
    bespokesynth
    dolphin-emu
    flavours
    jetbrains.clion
    moonlight-qt
    syncthingtray
    wezterm
    wineWowPackages.stagingFull
    yabridge
    yabridgectl
  ];


  services.udev.packages = [
    # Dolphin emu udev rules (allow direct bluetooth access)
    pkgs.dolphinEmu
    # Allow raw access to all usb storage devices
    (pkgs.writeTextFile {
      name = "usb-storage-udev-rules";
      text = ''SUBSYSTEM=="usb", ATTRS{removable}=="removable", MODE="0660", TAG+="uaccess"'';
      destination = "/etc/udev/rules.d/70-usb-storage.rules";
    })
  ];


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
