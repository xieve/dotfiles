{ config, lib, ... }:

let
  inherit (lib) filterAttrs mapAttrs optionalString;
  inherit (builtins) head match toString;
in
{
  services.nginx = {
    enable = true;
    commonHttpConfig = ''
      map $http_user_agent $limit_bots {
        default 0;
        ~*(bot|crawler|google|bing|yandex|altavista|slurp|blackwidow|chinaclaw|custo|disco) 1;
        ~*(download|demon|ecatch|eirgrabber|emailsiphon|emailwolf|superhttp|webwhacker|express) 1;
        ~*(webpictures|extractorpro|eyenetie|flashget|getright|getweb!|go!zilla|go-ahead-got-it) 1;
        ~*(grabnet|grafula|hmview|go!zilla|go-ahead-got-it|rafula|hmview|httrack|stripper|sucker) 1;
        ~*(indy|interget|ninja|jetcar|spider|larbin|leechftp|downloader|tool|navroad|nearsite) 1;
        ~*(netants|takeout|wwwoffle|grabnet|netspider|vampire|netzip|octopus|offline|pagegrabber) 1;
        ~*(foto|pavuk|pcbrowser|realdownload|reget|sitesnagger|smartdownload|webspider|teleport) 1;
        ~*(voideye|collector|webauto|webcopier|webfetch|webgo|webleacher|webreaper|websauger) 1;
        ~*(extractor|quester|webstripper|webzip|wget|widow|zeus|htmlparser|libwww|python|perl) 1;
        ~*(urllib|scan|curl|email|pycurl|pyth|pyq|webcollector|webcopy) 1;
      }

      # TODO: This is not great. I should probably do separate server blocks instead.
      map $server_addr $dest_local {
        default 0;
        fd00::acab 1;
        192.168.0.2 1;
      }
    '';
    # Partly reimplementing the nixpkgs nginx module here because it does not allow to prepend
    # config inside a server block before the locations, but we need that
    virtualHosts =
      mapAttrs
        (
          name:
          cfg@{
            proxyPass,
            proxyWebsockets ? false,
            localOnly ? false,
            serverAliases ? [ ],
          }:
          {
            inherit serverAliases;
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              if ($limit_bots = 1) {
                return 403;
              }
              ${optionalString localOnly ''
                allow 192.168../24;
                allow 100.104../32;
                allow ::/0;
                deny all;
                if ($dest_local = 0) {
                  return 403;
                }
              ''}
              add_header X-Robots-Tag noindex;

              location / {
                proxy_pass ${proxyPass};
                ${optionalString proxyWebsockets ''
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection $connection_upgrade;
                ''}
              }
            '';
          }
        )
        {
          "search.xieve.net" = {
            serverAliases = [ "xieve.net" ];
            proxyPass = "http://${config.services.searx.uwsgiConfig.http}";
          };
          "jellyfin.xieve.net" = {
            proxyPass = "http://localhost:8096";
            localOnly = true;
          };
          # "arm.xieve.net" = {
          #   proxyPass = "http://${head (match "(.*):.*?" (head config.virtualisation.oci-containers.containers.arm.ports))}";
          #   localOnly = true;
          # };
          "home.xieve.net" =
            let
              cfg = config.services.home-assistant.config.http;
            in
            {
              proxyPass = "http://[::1]:${toString cfg.server_port}";
              localOnly = true;
              proxyWebsockets = true;
            };
          "cockring.xieve.net" = {
            proxyPass = "http://192.168.178.84:30000";
            proxyWebsockets = true;
          };
        };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
