{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:

{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "warmplace";

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree.enable = true;
  };

  boot = {
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
      ''root="LABEL=nixos"''
    ];
    # Override common.nix
    loader.systemd-boot.enable = false;
  };

  services = {
    openssh.enable = true;
    tailscale.enable = true;
  };
}
