{
  self,
  ...
}:
{
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "motionblinds_ble"
    ];
    customComponents = [
      # TODO: having to specify the arch like this is super ugly. probably should use an overlay
      self.packages.${pkgs.system}.homeassistant-localtuya
    ];
    config = {
      http = {
        server_host = "::1";
      };
    };
  };
}
