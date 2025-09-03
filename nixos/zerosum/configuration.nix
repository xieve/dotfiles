{ config, pkgs, ... }:

let
  home = config.users.users.xieve.home;
in
{
  imports = [
    ./hardware.nix
    ../common.nix
  ];

  networking = {
    hostName = "zerosum";
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      # Enable A2DP sink
      settings.General.Enable = "Source,Sink,Media,Socket";
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

  boot.kernelParams = [
    "pci=hpiosize=0"
  ];

  boot.extraModprobeConfig = ''
    softdep soc_button_array pre: pinctrl_tigerlake
  '';

  boot.initrd.kernelModules = [
    "surface_hid"
    "pinctrl_tigerlake"
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  }; # Force intel-media-driver

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
    Touchscreen.DisableOnPalm = true;
    Touchscreen.DisableOnStylus = true;
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

    # Smartcard daemon (yubikey)
    pcscd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bespokesynth
    dolphin-emu
    flavours
    jetbrains-toolbox
    moonlight-qt
    prismlauncher
    rnote
    syncthingtray
    wezterm
    wineWowPackages.stagingFull
    xournalpp
    yabridge
    yabridgectl
  ];

  services.udev.packages = with pkgs; [
    # Dolphin emu udev rules (allow direct bluetooth access)
    dolphin-emu
    android-udev-rules
    # Allow raw access to all usb storage devices
    (writeTextFile {
      name = "usb-storage-udev-rules";
      text = ''SUBSYSTEM=="usb", ATTRS{removable}=="removable", MODE="0660", TAG+="uaccess"'';
      destination = "/etc/udev/rules.d/70-usb-storage.rules";
    })
    # Lattice FPGAs
    (writeTextFile {
      name = "lattice-fpga-udev-rules";
      text = ''
        SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", TAG+="uaccess", SYMLINK+="ftdi-$number", RUN+="/bin/sh -c 'echo $kernel > /sys/bus/usb/drivers/ftdi_sio/unbind'"
      '';
      destination = "/etc/udev/rules.d/51-lattice.rules";
    })
    # led badge
    (writeTextFile {
      name = "badgemagic-udev-rules";
      text = ''
        SUBSYSTEM=="usb",  ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5020", MODE="0660", TAG+="uaccess"
        KERNEL=="hidraw*", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5020", ATTRS{busnum}=="1", MODE="0660", TAG+="uaccess"
      '';
    })
  ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  systemd.user =
    let
      autostartWantedBy = [ "graphical-session.target" ];
    in
    {
      # Autostart applications are delayed by 3 seconds to wait for XWayland to start
      # up properly. If we don't do this then scaling and theming are all fucked up
      timers.autostart = {
        enable = true;
        wantedBy = autostartWantedBy;
        bindsTo = autostartWantedBy;
        # xdg-desktop-portal is the last component of gnome that starts up
        after = autostartWantedBy ++ [ "xdg-desktop-portal.service" ];
        timerConfig = {
          OnActiveSec = 3;
          AccuracySec = "100ms";
          Unit = "autostart.target";
        };
      };
      targets.autostart = {
        bindsTo = autostartWantedBy;
      };
      services =
        builtins.mapAttrs
          (
            name: unit:
            let
              wantedBy = [ "autostart.target" ];
            in
            {
              inherit wantedBy;
              enable = true;
              bindsTo = wantedBy;
              after = wantedBy;
              path = [ pkgs.${name} ];
            }
            // unit
          )
          {
            trayscale = {
              script = "trayscale --hide-window";
            };
            syncthingtray = {
              script = "QT_QPA_PLATFORM=xcb syncthingtray --wait";
            };
            keepassxc.script = "keepassxc $@";
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
        "com.github.flxzt.rnote.desktop"
      ];
    }
  ];

  # temp workaround until obsidian gets their shit together
  nixpkgs.config.permittedInsecurePackages = pkgs.lib.optional (
    pkgs.obsidian.version == "1.5.3"
  ) "electron-25.9.0";

  virtualisation.docker.enable = true;
}
