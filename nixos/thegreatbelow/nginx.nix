{ config, lib, ... }:

let
  inherit (lib) filterAttrs mapAttrs optionalString;
  inherit (builtins) head match;
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
    '';
    virtualHosts =
      mapAttrs
        (
          name: paramCfg:
          let
            cfg = {
              localOnly = false;
            } // paramCfg;
          in
          {
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              ${optionalString cfg.localOnly ''
                allow 192.168../24;
                allow 100.104../32;
                allow fe80::/10;
                deny all;
              ''}
              if ($limit_bots = 1) {
                return 403;
              }
              add_header X-Robots-Tag noindex;

              location / {
                proxy_pass ${cfg.proxyPass};
              }
            '';
          }
          // (filterAttrs (name: _: name != "proxyPass" && name != "localOnly") cfg)
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
          "arm.xieve.net" = {
            proxyPass = "http://${head (match "(.*):.*?" (head config.virtualisation.oci-containers.containers.arm.ports))}";
            localOnly = true;
          };
          "cockring.xieve.net" = {
            proxyPass = "http://192.168.178.84:30000";
          };
        };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
