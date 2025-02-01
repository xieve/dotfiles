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
        ~*(google|bing|yandex|msnbot|AltaVista|Googlebot|Slurp|BlackWidow|Bot|ChinaClaw|Custo) 1;
        ~*(DISCo|Download|Demon|eCatch|EirGrabber|EmailSiphon|EmailWolf|SuperHTTP|Surfbot) 1;
        ~*(WebWhacker|Express|WebPictures|ExtractorPro|EyeNetIE|FlashGet|GetRight|GetWeb!) 1;
        ~*(Go!Zilla|Go-Ahead-Got-It|GrabNet|Grafula|HMView|Go!Zilla|Go-Ahead-Got-It|rafula) 1;
        ~*(HMView|HTTrack|Stripper|Sucker|Indy|InterGET|Ninja|JetCar|Spider|larbin|LeechFTP) 1;
        ~*(Downloader|tool|Navroad|NearSite|NetAnts|tAkeOut|WWWOFFLE|GrabNet|NetSpider|Vampire) 1;
        ~*(NetZIP|Octopus|Offline|PageGrabber|Foto|pavuk|pcBrowser|RealDownload|ReGet) 1;
        ~*(SiteSnagger|SmartDownload|SuperBot|WebSpider|Teleport|VoidEYE|Collector|WebAuto) 1;
        ~*(WebCopier|WebFetch|WebGo|WebLeacher|WebReaper|WebSauger|eXtractor|Quester|WebStripper) 1;
        ~*(WebZIP|Wget|Widow|Zeus|Twengabot|htmlparser|libwww|Python|perl|urllib|scan|Curl|email) 1;
        ~*(PycURL|Pyth|PyQ|WebCollector|WebCopy|webcraw) 1;
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
