{ config, pkgs, ... }:

let
  home = config.users.users.xieve.home;
in
{
  imports = [
    ./hardware.nix
    ../common.nix
    ../gnome.nix
  ];

  networking = {
    hostName = "zerosum";
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable screen rotation
    sensor.iio.enable = true;
  };

  # These prevent booting. https://github.com/linux-surface/linux-surface/issues/1516
  # AFAIK they're responsible for the camera, which wouldn't work anyway according to
  # the linux-surface wiki.
  boot.blacklistedKernelModules = [
    "intel-ipu6"
    "intel-ipu6-isys"
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  }; # Force intel-media-driver

  services.logind = {
    lidSwitch = "lock";
    lidSwitchExternalPower = "lock";
  };

  # Touchscreen calibration values measured by iptsd-calibrate
  services.iptsd.config = {
    Contacts = {
      SizeMin = 0.5;
      SizeMax = 2.25;
      AspectMin = 1;
      AspectMax = 2.1;
      /*
      ActivationThreshold = 40;
      DeactivationThreshold = 36;
      OrientationThresholdMax = 15;
      */
    };
    # Once https://github.com/NixOS/nixpkgs/pull/344036 has been merged, this option should
    # be renamed to "Touchscreen"
    Touch.DisableOnPalm = true;
    Touch.DisableOnStylus = true;
  };

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
      useRoutingFeatures = "client";
    };
  };

  environment.systemPackages = with pkgs; [
    bespokesynth
    dolphin-emu
    flavours
    jetbrains.clion
    moonlight-qt
    rnote
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

  systemd.user.services =
    builtins.mapAttrs
      (
        name: unit:
        let
          wantedBy = [ "graphical-session.target" ];
        in
        {
          inherit wantedBy;
          bindsTo = wantedBy;
          after = wantedBy;
          enable = true;
          path = [ pkgs.${name} ];
        }
        // unit
      )
      {
        trayscale = {
          script = "sleep 5; trayscale --hide-window";
        };
        syncthingtray = {
          script = "syncthingtray --wait";
        };
      };

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/shell".favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.wezfurlong.wezterm.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "obsidian.desktop"
        "codium.desktop"
        "BespokeSynth.desktop"
      ];
    }
  ];

  # temp workaround until obsidian gets their shit together
  nixpkgs.config.permittedInsecurePackages = pkgs.lib.optional (
    pkgs.obsidian.version == "1.5.3"
  ) "electron-25.9.0";
}
