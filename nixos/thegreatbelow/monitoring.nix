{ config, lib, ... }:
let
  grafana = config.services.grafana.settings.server;
  inherit (config.services.prometheus) exporters;
in
{
  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          domain = "grafana.xieve.net";
          http_port = 13298;
        };
        security.secret_key = "$__file{/run/credentials/grafana.service/grafana_secret_key}";
      };
    };
    prometheus =
      let
        listenAddress = "127.0.0.1";
      in
      lib.mkMerge (
        [
          {
            enable = true;
            port = 9001;
            inherit listenAddress;
          }
        ]
        ++
          lib.mapAttrsToList
            (name: config: {
              exporters.${name} = {
                enable = true;
                inherit listenAddress;
              }
              // config;
              scrapeConfigs = [
                {
                  job_name = name;
                  static_configs = [
                    {
                      targets = [ "${listenAddress}:${toString exporters.${name}.port}" ];
                    }
                  ];
                }
              ];
            })
            {
              node.enabledCollectors = [
                "systemd"
                "processes"
              ];
              nginx = { };
            }
      );
  };

  services.nginx.statusPage = true;

  xieve.nginx.virtualHosts = {
    ${grafana.domain} = {
      proxyPass = "http://${grafana.http_addr}:${toString grafana.http_port}";
      auth = true;
      proxyWebsockets = true;
    };
  };

  systemd.services.grafana.serviceConfig.SetCredentialEncrypted = ''
    grafana_secret_key: \
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAA6M1HPwnWnF31WjuYAAAAAKXPDQ \
      o5DqvmTWa7O/55LG40Rh2FXu1P6YQifd23VQwfv90R3gaPAatvGWlDg9Jjr+cy7lNuJFC \
      DYgfO+oGwEzUF935afnuIBFgeaudFZaoByM+hYHC+Qnw==
  '';
}
