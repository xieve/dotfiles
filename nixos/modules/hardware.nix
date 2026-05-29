{ lib, config, ... }:
let
  cfg = config.xieve.hardware;
in
{
  options.xieve.hardware = with lib.types; {
    enable = lib.mkEnableOption "Xieve's common hardware options";
    swapDevice = lib.mkOption {
      type = path;
    };
  };
  config = lib.mkIf cfg.enable {
    # Bootloader
    boot.loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };

    # Swap
    boot.zswap = {
      enable = true;
      maxPoolPercent = 80;
    };
    swapDevices = [
      {
        device = cfg.swapDevice;
        randomEncryption.enable = true;
      }
    ];

    # Mount /tmp as tmpfs
    boot.tmp = {
      useTmpfs = true;
      tmpfsHugeMemoryPages = "within_size";
    };
  };
}
