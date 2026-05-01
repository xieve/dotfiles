{ config, ... }:
let
  cfg = config.services.deluge;
in
{
  services.deluge = {
    enable = true;
    web = {
      enable = true;
      port = 38328;
    };
  };

  xieve.nginx.virtualHosts."deluge.xieve.net" = {
    proxyPass = "localhost:${cfg.web.port}";
  };
}
