{ config, lib, ... }:
let
  inherit (config.virtualisation.oci-containers.containers.yacy) serviceName;
in
{
  virtualisation.oci-containers.containers.yacy = {
    image = "yacy/yacy_search_server";
    ports = [
      "35640:8090"
    ];
    volumes = [
      "yacy_search_server_data:/opt/yacy_search_server/DATA"
    ];
    extraOptions = [
      "--userns=auto"
    ];
  };

  systemd.services.${serviceName}.serviceConfig.Restart = lib.mkForce "always";

  xieve.nginx = {
    virtualHosts."yacy.xieve.net" = {
      proxyPass = "http://127.0.0.1:35640";
      extraConfig = ''
        listen 8443 ssl;
      '';
      headers = {
        X-Frame-Options = "sameorigin";
      };
    };
    commonHttpConfig = ''
      server {
        listen 8090;
        location / {
          proxy_http_version 1.1;
          include ${../modules/nginx/proxy.conf};
          proxy_pass http://127.0.0.1:35640;
        }
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    8090
    8443
  ];
}
