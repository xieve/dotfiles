{ config, ... }:
let
  inherit (builtins) head;
  cfg = config.thegreatbelow;
in
{
  networking.firewall.allowedTCPPorts = [ (head config.services.mosquitto.listeners).port ];

  services.mosquitto = {
    enable = true;
    listeners =
      map
        (address: {
          # TODO: SSL, auth
          inherit address;
          acl = [ "pattern readwrite #" ];
          omitPasswordAuth = true;
          settings.allow_anonymous = true;
        })
        [
          cfg.ipAddress.v4
          cfg.ipAddress.v6
          "::1"
        ];
  };
}
