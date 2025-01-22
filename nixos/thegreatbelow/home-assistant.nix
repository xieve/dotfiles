{ ... }:
{
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "motionblinds_ble"
    ];
    config = {

    };
  };
}
