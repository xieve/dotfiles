{ config, lib, ... }:

let
  inherit (lib) filterAttrs mapAttrs optionalString;
  inherit (builtins) head match toString;
  cfg = config.thegreatbelow;
in
{
  xieve.nginx = {
    enable = true;
    localAddresses = [
      cfg.ipAddress.v4
      cfg.ipAddress.v6
      cfg.ipAddress.tailscale.v4
      cfg.ipAddress.tailscale.v6
    ];
    commonHttpConfig = ''
      map $host $log_less_for_host {
        default 1;
        search.xieve.net 0;
      }
      map "$log_less_for_host$status" $log {
        default 1;
        1200 0;
      }
    '';
    commonServerConfig = ''
      access_log /var/log/nginx/access.log verbose if=$log;
    '';
    wildcardSSLDomain = "xieve.net";
    autheliaURL = "http://unix:${config.thegreatbelow.authelia.socket}:";
    virtualHosts = {
      "lldap.xieve.net" = {
        proxyPass = "http://[::1]:${toString config.services.lldap.settings.http_port}";
        localOnly = true;
      };
      "search.xieve.net" = {
        # serverAliases = [ "xieve.net" ];
        proxyPass = "http://${config.services.searx.uwsgiConfig.http}";
      };
      "jellyfin.xieve.net" = {
        proxyPass = "http://localhost:8096";
        auth = true;
        # The default ones didn't work with the WebOS Client
        headers = {
          X-Frame-Options = "";
          Content-Security-Policy = "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";
          Cross-Origin-Resource-Policy = "";
          Cross-Origin-Embedder-Policy = "";
          Cross-Origin-Opener-Policy = "";
        };
      };
      "arm.xieve.net" =
        let
          cfg = config.services.automatic-ripping-machine.settings;
        in
        {
          proxyPass = "http://${cfg.WEBSERVER_IP}:${toString cfg.WEBSERVER_PORT}";
          auth = true;
        };
      "home.xieve.net" =
        let
          cfg = config.services.home-assistant.config.http;
        in
        {
          proxyPass = "http://[::1]:${toString cfg.server_port}";
          localOnly = true;
          proxyWebsockets = true;
        };
      "nodered.xieve.net" = {
        localOnly = true;
        proxyWebsockets = true;
        auth = true;
        proxyPass = "http://localhost:${toString config.services.node-red.port}";
      };
      "cockring.xieve.net" = {
        proxyPass = "http://192.168.178.84:30000";
        proxyWebsockets = true;
      };
      "atuin.xieve.net" =
        let
          cfg = config.services.atuin;
        in
        {
          proxyPass = "http://${cfg.host}:${toString cfg.port}";
        };
      "molly.xieve.net" =
        let
          cfg = config.services.mollysocket.settings;
        in
        {
          proxyPass = "http://${cfg.host}:${toString cfg.port}";
          proxyWebsockets = true;
        };
      "hydrusapi.xieve.net" = {
        proxyPass = "http://localhost:45869";
        localOnly = true;
      };
      "hydrui.xieve.net" =
        let
          cfg = config.services.hydrui;
        in
        {
          proxyPass = "http://localhost:${toString cfg.port}";
          localOnly = true;
        };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
