{
  lib,
  pkgs,
  config,
  modulesPath,
  self-pkgs,
  ...
}:
let
  secrets = lib.importTOML ./secrets.toml;
in
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "warmplace";

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree.enable = true;
  };

  boot = {
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
      ''root="LABEL=nixos"''
    ];
    # Override common.nix
    loader.systemd-boot.enable = false;
  };

  environment.variables = {
    ZSH_TMUX_AUTOSTART = "true";
  };

  # allow access to acme folder for both nginx and mosquitto so they can share a tls cert
  security.acme.certs.${config.networking.hostName}.group = "acme";
  users.users.mosquitto.extraGroups = [ "acme" ];
  users.users.nginx.extraGroups = [ "acme" ];

  services = {
    openssh.enable = true;
    tailscale.enable = true;
    avahi.enable = true; # mdns, needed by esphome

    mosquitto = {
      enable = true;
      listeners = [
        {
          settings =
            let
              # re-use nginx's keys
              acmeDir = config.security.acme.certs.${config.networking.hostName}.directory;
            in
            {
              # go-e Charger currently doesn't seem to work with MQTTS
              #certfile = "${acmeDir}/cert.pem";
              #keyfile = "${acmeDir}/key.pem";
            };
          users = {
            hass = {
              # HA connects via localhost which means it doesn't need to authenticate
              # Keeping this as a debug credential
              acl = [ "readwrite #" ];
              hashedPassword = secrets.mosquitto.hass;
            };
            goe = {
              acl = [
                "readwrite homeassistant/#"
                "readwrite energy/go-eCharger/#"
              ];
              hashedPassword = secrets.mosquitto.goe;
            };
          };
        }
        {
          # localhost access without auth
          address = "::1";
          port = 11883;
          acl = [ "pattern readwrite #" ];
          omitPasswordAuth = true;
          settings.allow_anonymous = true;
        }
      ];
    };

    evcc = {
      enable = true;
      settings = {
        network = {
          schema = "https";
          host = config.networking.hostName;
          port = 7070;
        };
        mqtt = {
          broker = "localhost:11883";
          topic = "energy/evcc";
        };
        meters =
          let
            goeMqtt = jsonKey: {
              type = "custom";
              power = {
                source = "mqtt";
                # reusing the data we're giving the charger since it's almost in the correct format
                # (i.e. one number that can go pos/neg)
                topic = "energy/go-eCharger/ids/set";
                jq = ".${jsonKey}";
              };
            };
          in
          [
            ({ name = "grid"; } // goeMqtt "pGrid")
            ({ name = "pv"; } // goeMqtt "pPv")
            ({
              name = "battery";
              # state of charge is published by HA via statestream integration,
              # HA is connected to growatt (esphome device) via HA api
              soc = {
                source = "mqtt";
                topic = "homeassistant/sensor/growatt_battery_charge/state";
              };
            } // goeMqtt "pAkku")
          ];
        chargers = [
          {
            # this opens a websocket on port 8887, which we reverse proxy with nginx for TLS
            name = "ocpp";
            type = "template";
            template = "ocpp";
          }
        ];
        vehicles = [
          {
            # Connected via uconnect cloud service for vehicle state-of-charge data
            name = "fiat500e";
            title = "Fiat 500e";
            type = "template";
            template = "fiat";
            user = secrets.fiat.user;
            password = secrets.fiat.password;
            capacity = 39;
          }
        ];
        tariffs.co2 = {
          type = "grünstromindex";
          zip = secrets.zip;
        };
        site = {
          title = "Zuhause";
          meters = {
            grid = "grid";
            pv = [ "pv" ];
            battery = [ "battery" ];
          };
        };
        loadpoints = [
          {
            title = "Werkstatt";
            charger = "ocpp";
            # let's see if i need to define this in addition to OCPP TODO
            #meter = "charge";
          }
        ];
      };
    };

    home-assistant = {
      enable = true;
      extraComponents = [
        "esphome"
        "met"
        "mqtt"
        "radio_browser"
        "forecast_solar"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };

        http = {
          trusted_proxies = [ "::1" ];
          use_x_forwarded_for = true;
        };

        # growatt is auto-discovered (HA api), we do our own energy calculations
        # based on polled power data (integral)
        sensor =
          map
            (str: {
              name = lib.replaceStrings [ "Power" ] [ "Energy" ] str;
              platform = "integration";
              source = "sensor.growatt_${lib.toLower (lib.replaceStrings [ " " ] [ "_" ] str)}";
              unit_prefix = "k"; # kWh
            })
            [
              "Power to Grid"
              "Power from Grid"
              "Power to Battery"
              "Power from Battery"
              "PV Total Power"
            ];

        # Automatically publish all state changes we receive from growatt (connected via native HA api)
        # evcc reads state-of-charge from here
        mqtt_statestream = {
          base_topic = "homeassistant";
          include = {
            entity_globs = [
              "sensor.growatt_*"
            ];
          };
        };

        automation = [
          {
            alias = "go-e Surplus Charging";
            description = "Feed PV data into go-e Charger for surplus charging";
            trigger = {
              platform = "time_pattern";
              seconds = "/5";
            };
            condition = {
              condition = "state";
              entity_id = "sensor.growatt_status";
              state = "Normal";
            };
            action = {
              service = "mqtt.publish";
              data = {
                # go-e Charger topic is `go-eCharger/<Serial number>` by default
                # but can be changed in the app
                topic = "energy/go-eCharger/ids/set";
                payload_template = ''
                  {"pGrid":{{
                    float(states("sensor.growatt_power_from_grid"))
                      - float(states("sensor.growatt_power_to_grid"))
                  }},
                  "pAkku":{{
                    float(states("sensor.growatt_power_from_battery"))
                      - float(states("sensor.growatt_power_to_battery"))
                  }},
                  "pPv":{{ states("sensor.growatt_pv_total_power") }}}
                '';
              };
            };
          }
        ];
      };
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts.${config.networking.hostName} = {
        # We're abusing the fallback self-signed cert here
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          proxy_buffering off;
        '';
        locations = {
          "/" = {
            proxyWebsockets = true;
            extraConfig = ''
              # https://serverfault.com/questions/586586/nginx-redirect-via-proxy-rewrite-and-preserve-url
              # evcc doesn't support running behind a reverse proxy but we're obviously gonna do it anyway
              # by using the Referer header we can infer the "proxied" URL from the wrong one
              add_header Vary Referer;

              # This dumb workaround is in place because NixOS forces me to
              # pass a piece of shit "validation" with this config.
              # https://github.com/NixOS/nixpkgs/issues/128506
              # fuck you
              set $fuck_you_gixy http_referer;
              if ($fuck_you_gixy ~ ^https://[^/]*/(evcc|esphome)) {
                return 302 /$1/$request_uri;
              }
              proxy_pass http://[::1]:8123;
            '';
          };
          "/evcc/" = {
            proxyWebsockets = true;
            proxyPass = "http://[::1]:7070/";
          };
          # Open Charging Point Protocol, handled by evcc
          "/ocpp/" = {
            proxyWebsockets = true;
            proxyPass = "http://[::1]:8887/";
          };
        };
      };
    };
  };
  security.acme = {
    # By using an invalid value here, the renew service will not connect to Let's Encrypt at all
    defaults = {
      email = "";
      # The generated self-signed certs are valid for 2 years
      renewInterval = "yearly";
    };
    # Mandatory even though we're not actually connecting
    acceptTerms = true;
  };
  # Ignore error produced due to config above
  systemd.services."acme-${config.networking.hostName}".serviceConfig.SuccessExitStatus = [ 10 ];

  networking.firewall.allowedTCPPorts = [
    1883 # MQTT
    80
    443
  ];
}
