{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    optionalString
    getExe
    ;
  inherit (builtins) head match toString;
  cfg = config.thegreatbelow;
in
{
  services.networkd-dispatcher = {
    enable = true;
    extraArgs = ["--run-startup-triggers"];
    # Because our IPv6 prefix changes over time, this always provides nginx
    # with an includeable and up-to-date `listen $my_global_ipv6` directive
    rules.nginx-update-address = {
      onState = [ "configured" "no-carrier" "off" ];
      script = ''${getExe pkgs.python3} ${pkgs.writeScript "nginx-update-address.py" ''
        import os
        import re
        import subprocess
        import json
        import ipaddress

        eventData = json.loads(os.environ["json"])

        if "${cfg.exposedInterface}" in [eventData["InterfaceName"], *eventData["Alternative Names"]]:
          result = subprocess.run(
            ["networkctl", "status", eventData["InterfaceName"], "--json=short"],
            capture_output=True,
            text=True,
            check=True,
          )
          data = json.loads(result.stdout)

          if eventData["OperationalState"] == "routable":
            for ip_addr in data["Addresses"]:
              if ip_addr.get("Family") != 10:
                continue
              formatted_addr = ipaddress.IPv6Address(bytes(ip_addr["Address"])).compressed
              if re.match(r"^(?!fd00).*${cfg.ipAddress.exposed.v6Suffix}$", formatted_addr):
                break
            else:  # no break
              print(os.environ["json"])
              raise Exception("Could not find matching IPv6 address")

            with open("/run/nginx_listen_insecure.conf", "w") as f:
              f.write(f"listen [{formatted_addr}]:80;")
            with open("/run/nginx_listen_ssl.conf", "w") as f:
              f.write(f"listen [{formatted_addr}]:443 ssl;")
          else:
            # Nginx fails if it tries to listen on an address that is not configured
            # But if the files don't exist it simply ignores that
            os.remove("/run/nginx_listen_insecure.conf", "/run/nginx_listen_ssl.conf")

          subprocess.run(["systemctl", "reload-or-restart", "nginx"])
      ''}'';
    };
  };

  xieve.nginx = {
    enable = true;
    localAddresses = [
      cfg.ipAddress.v4
      cfg.ipAddress.v6
      cfg.ipAddress.tailscale.v4
      cfg.ipAddress.tailscale.v6
    ];
    exposedV4Address = cfg.ipAddress.exposed.v4;
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
