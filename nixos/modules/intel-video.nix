{
  lib,
  config,
  pkgs,
  ...
}:

{
  options.xieve.hardware.enableIntelVideo = lib.mkEnableOption "Intel Video Acceleration (Skylake and above)";

  config = lib.mkIf config.xieve.hardware.enableIntelVideo {
    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vpl-gpu-rt # QuickSync (VPL)
        #intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    hardware.enableRedistributableFirmware = true;

    # Force intel-media-driver
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
