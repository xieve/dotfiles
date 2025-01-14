# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = lib.mkMerge (
    [
      {
        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "megaraid_sas"
          "usb_storage"
          "sd_mod"
          "sr_mod"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/650ca6ce-7a65-4278-a1d3-12c6170441b9";
          fsType = "ext4";
          options = [
            "noatime"
            "discard"
          ];
        };

        boot.initrd.luks.devices."nixos".device = "/dev/disk/by-uuid/a2d6a018-51a9-46fc-9875-1f6a014609da";

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/3CB3-5E84";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
        # (the default) this is the recommended approach. When using systemd-networkd it's
        # still possible to use this option, but it's recommended to use it in conjunction
        # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
        networking.useDHCP = lib.mkDefault true;
        # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
        # networking.interfaces.eno2.useDHCP = lib.mkDefault true;

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      }
    ]
    ++
      map
        (dataset: {
          fileSystems."/mnt/frail${dataset}" = {
            device = "frail${dataset}";
            fsType = "zfs";
            options = [
              "noatime"
              "nodev"
              "noexec"
              "nosuid"
            ];
          };
        })
        [
          ""
          "/srv"
          "/kopia"
        ]
  );
}
