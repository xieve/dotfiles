{ config, ... }:
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
      {
        enable = true;
        port = 9001;
        exporters = {
          node = {
            inherit listenAddress;
            enable = true;
            enabledCollectors = [
              "systemd"
              "processes"
            ];
            port = 46706;
          };
        };
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "${listenAddress}:${toString exporters.node.port}" ];
              }
            ];
          }
        ];
      };
  };

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
