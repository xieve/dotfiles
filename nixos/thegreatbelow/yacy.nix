{ config, lib, ... }:
let
  inherit (config.virtualisation.oci-containers.containers.yacy) serviceName;
in
{
  virtualisation.oci-containers.containers.yacy = {
    image = "docker.io/yacy/yacy_search_server:latest-alpine";
    ports = [
      "35640:8090"
    ];
    volumes = [
      "yacy_search_server_data:/opt/yacy_search_server/DATA"
    ];
    extraOptions = [
      "--userns=auto"
      ''--health-cmd=["wget", "--spider", "http://localhost:8090/Status.html"]''
      "--health-start-period=3m"
      "--health-on-failure=stop"
      "--label=io.containers.autoupdate=registry"
    ];
    podman.sdnotify = "healthy";
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
