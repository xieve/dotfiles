{ config, ... }:
{
  services.nginx = {
    enable = true;
    validateConfigFile = false;
    virtualHosts.${config.networking.hostName} = {
      # We're abusing the fallback self-signed cert here
      enableACME = true;
      # forceSSL = true;
      addSSL = true;
      extraConfig = ''
        proxy_buffering off;
      '';
      locations = {
        "/" = {
          proxyWebsockets = true;
          extraConfig = ''
            # https://serverfault.com/questions/586586/nginx-redirect-via-proxy-rewrite-and-preserve-url
            # unifi doesn't support running behind a reverse proxy but we're obviously gonna do it anyway
            # by using the Referer header we can infer the "proxied" URL from the wrong one
            add_header Vary Referer;

            if ($http_referer ~ ://[^/]*/(unifi)) {
              return 302 /$1$request_uri;
            }
            proxy_pass http://[::1]:8123;
          '';
        };
        "/evcc/" = {
          proxyWebsockets = true;
          proxyPass = "http://[::1]:7070/";
        };
        "/unifi/" = {
          proxyWebsockets = true;
          proxyPass = "https://[::1]:8443/";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
