{ config, lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    optionalString
    mkIf
    concatMapAttrsStringSep
    escape
    ;
  inherit (builtins) head match toString;
  thegreatbelow = config.thegreatbelow;
  cfg = config.xieve.nginx;
in
{
  options.xieve.nginx =
    with lib.types;
    let
      inherit (lib) mkEnableOption mkOption;
    in
    {
      enable = mkEnableOption "nginx";
      localAddresses = mkOption {
        type = listOf str;
        default = [ ];
      };
      autheliaURL = mkOption {
        type = str;
      };
      wildcardSSLDomain = mkOption {
        type = nullOr str;
        default = null;
      };
      virtualHosts = mkOption {
        type = attrsOf (submodule {
          options = {
            proxyPass = mkOption {
              type = nullOr str;
              default = null;
            };
            proxyWebsockets = mkOption {
              type = bool;
              default = false;
            };
            localOnly = mkOption {
              type = bool;
              default = false;
            };
            serverAliases = mkOption {
              type = listOf str;
              default = [ ];
            };
            auth = mkOption {
              type = bool;
              default = false; # TODO: true
            };
            extraConfig = mkOption {
              type = str;
              default = "";
            };
            headers = mkOption {
              type = attrsOf str;
              default = { };
            };
          };
        });
      };
      defaultHeaders = mkOption {
        type = attrsOf str;
        default = {
          X-Robots-Tag = "noindex";
          Strict-Transport-Security = "max-age=31536000; includeSubDomains";
          X-Permitted-Cross-Domain-Policies = "none";
          X-Frame-Options = "deny";
          Content-Security-Policy = "default-src https: data: blob: 'unsafe-eval' 'unsafe-inline'; object-src 'none'";
          Referrer-Policy = "no-referrer";
          # Clients shall always ask the server whether they can used the cached version of a resource
          Cache-Control = "no-cache";
        };
      };
    };
  config =
    let
      escapeNginx = escape [
        "'"
        ''\''
      ];
    in
    {
      xieve.nginx.virtualHosts = {
        "auth.*" = {
          extraConfig = ''
            location / {
              include ${./nginx/proxy.conf};
              proxy_pass ${cfg.autheliaURL};
            }
            location = /api/verify {
              proxy_pass ${cfg.autheliaURL};
            }
            location /api/authz/ {
              proxy_pass ${cfg.autheliaURL};
            }
          '';
        };
      };

      services.nginx = mkIf cfg.enable {
        inherit (cfg) enable;
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

          map $server_addr $dest_local {
            default 0;
            ${lib.concatMapStrings (addr: ''
              ${addr} 1;
            '') cfg.localAddresses}
          }
        '';
        # Partly reimplementing the nixpkgs nginx module here because it does not allow to prepend
        # config inside a server block before the locations, but we need that
        virtualHosts = mapAttrs (
          name:
          {
            proxyPass,
            proxyWebsockets,
            localOnly,
            serverAliases,
            extraConfig,
            auth,
            headers,
          }:
          let
            headerStr = concatMapAttrsStringSep "\n" (
              header: value:
              "add_header '${escapeNginx header}' '${escapeNginx value}${
                optionalString (header == "Content-Security-Policy" && proxyWebsockets) "; connect-src \\'self\\'"
              }' always;"
            ) (cfg.defaultHeaders // headers);
          in
          {
            inherit serverAliases;
            useACMEHost = mkIf (cfg.wildcardSSLDomain != null) cfg.wildcardSSLDomain;
            forceSSL = true;
            # listenAddresses = mkIf localOnly (
            #   map (x: if lib.hasInfix ":" x then "[${x}]" else x) cfg.localAddresses
            # );
            # TODO: longer HSTS period, possibly submit domain to HSTS preload list
            extraConfig = ''
              if ($dest_local = 1) {
                set $limit_bots 0;
              }
              if ($limit_bots) {
                return 403;
              }

              ${optionalString localOnly ''
                allow 192.168../24;
                allow 100.../8;
                allow ::/0;
                deny all;
                if ($dest_local = 0) {
                  return 403;
                }
              ''}

              ${optionalString auth ''
                set $upstream_authelia ${cfg.autheliaURL}/api/authz/auth-request;
                include ${./nginx/authelia-location.conf};
              ''}

              ${headerStr}

              ${optionalString (proxyPass != null) ''
                location / {
                  ${optionalString auth ''
                    include ${./nginx/proxy.conf};
                    include ${./nginx/authelia-authrequest.conf};
                  ''}
                  ${optionalString proxyWebsockets ''
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection $connection_upgrade;
                  ''}
                  proxy_http_version 1.1;
                  proxy_pass ${proxyPass};
                }
              ''}

              ${extraConfig}
            '';
          }
        ) cfg.virtualHosts;
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.enable [
        80
        443
      ];
    };
}
