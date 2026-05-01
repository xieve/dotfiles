{ config, lib, ... }:

let
  inherit (lib)
    attrNames
    concatMapAttrsStringSep
    concatMapStrings
    concatStringsSep
    escape
    genAttrs
    filterAttrs
    mapAttrs
    mkDefault
    mkIf
    optional
    optionalString
    ;
  inherit (builtins) head match toString;
  inherit (config.security) acme;
  inherit (config) thegreatbelow;
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
      exposedV4Address = mkOption {
        type = str;
      };
      autheliaURL = mkOption {
        type = str;
      };
      wildcardSSLDomain = mkOption {
        type = nullOr str;
        default = null;
      };
      commonHttpConfig = mkOption {
        type = lines;
        default = "";
      };
      commonServerConfig = mkOption {
        type = str;
        default = "";
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
            useWildcardSSL = mkOption {
              type = bool;
              default = true;
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
      acmeNames = attrNames (
        filterAttrs (name: { useWildcardSSL, ... }: !useWildcardSSL) cfg.virtualHosts
      );
    in
    {
      # This is here because this module depends on authelia
      xieve.nginx.virtualHosts = {
        "auth.xieve.net" = {
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

      security.acme.certs = genAttrs acmeNames (name: {
        group = config.services.nginx.group;
        webroot = "/var/lib/acme/acme-challenge/";
      });

      services.nginx = mkIf cfg.enable {
        inherit (cfg) enable;

        # Reload (SIGHUP) instead of restart. This should improve uptime dramatically.
        enableReload = true;

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

          log_format verbose '$remote_addr → $host@$server_addr [$time_local] '
            '$limit_bots $dest_local "$request" $status $body_bytes_sent '
            '"$http_referer" "$http_user_agent"';
          ${cfg.commonHttpConfig}
        '';
        # Partly reimplementing the nixpkgs nginx module here because it does not allow to prepend
        # config inside a server block before the locations, but we need that
        appendHttpConfig = concatMapAttrsStringSep "\n" (
          name:
          {
            proxyPass,
            proxyWebsockets,
            localOnly,
            serverAliases,
            extraConfig,
            auth,
            headers,
            useWildcardSSL,
          }:
          let
            headerStr = concatMapAttrsStringSep "\n" (
              header: value:
              "add_header '${escapeNginx header}' '${escapeNginx value}${
                optionalString (header == "Content-Security-Policy" && proxyWebsockets) "; connect-src \\'self\\'"
              }' always;"
            ) (cfg.defaultHeaders // headers);
            serverName = ''
              server_name ${name} ${concatStringsSep " " serverAliases};
            '';
            listen = (
              {
                ssl ? true,
              }:
              concatMapStrings (address: ''
                listen ${if lib.hasInfix ":" address then "[${address}]" else address}:${
                  if ssl then "443 ssl" else "80"
                };
              '') (cfg.localAddresses ++ (optional (!localOnly) cfg.exposedV4Address))
            );
            acmeName = if useWildcardSSL && cfg.wildcardSSLDomain != null then cfg.wildcardSSLDomain else name;
            acmeDir = acme.certs.${acmeName}.directory;
            # We use ^~ here, so that we don't check any regexes (which could
            # otherwise easily override this intended match accidentally).
            acmeLocation = optionalString (!useWildcardSSL) ''
              location ^~ /.well-known/acme-challenge/ {
                auth_basic off;
                auth_request off;
                root ${acme.certs.${acmeName}.webroot};
              }
            '';
          in
          # TODO: longer HSTS period, possibly submit domain to HSTS preload list
          ''
            server {
              ${listen { }}
              ${serverName}
              ${optionalString (!localOnly) ''
                # Putting the dot in brackets makes it a pattern, which makes it optional
                include /run/nginx_listen_ssl[.]conf;
              ''}

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
                  proxy_http_version 1.1;
                  include ${./nginx/proxy.conf};
                  ${optionalString auth ''
                    include ${./nginx/authelia-authrequest.conf};
                  ''}
                  ${optionalString proxyWebsockets ''
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection $connection_upgrade;
                  ''}
                  proxy_pass ${proxyPass};
                }
              ''}

              ${acmeLocation}

              ssl_certificate ${acmeDir}/fullchain.pem;
              ssl_certificate_key ${acmeDir}/key.pem;
              ssl_trusted_certificate ${acmeDir}/fullchain.pem;

              ${extraConfig}
              ${cfg.commonServerConfig}
            }

            server {
              ${listen { ssl = false; }}
              ${serverName}
              ${optionalString (!localOnly) ''
                include /run/nginx_listen_insecure[.]conf;
              ''}
              location / {
                return 301 https://$host$request_uri;
              }
              ${acmeLocation}
            }
          ''
        ) cfg.virtualHosts;
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.enable [
        80
        443
      ];
    };
}
