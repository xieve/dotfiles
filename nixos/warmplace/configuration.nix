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

  services = {
    openssh.enable = true;
    tailscale.enable = true;
    mosquitto = {
      enable = true;
      listeners = [
        {
          users = {
            growatt = {
              acl = [ "readwrite energy/solar/#" ];
              hashedPassword = secrets.mosquitto.growatt;
            };
            hass = {
              acl = [ "readwrite #" ];
              hashedPassword = secrets.mosquitto.hass;
            };
            goe = {
              acl = [
                "readwrite homeassistant/#"
                "readwrite go-eCharger/#"
              ];
              hashedPassword = secrets.mosquitto.goe;
            };
          };
        }
      ];
    };
    home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"
        "forecast_solar"
      ];
      customComponents = [ self-pkgs.homeassistant-goecharger-mqtt ];
      config =
        let
          growattSensors = {
            energy = [
              "ChargeEnergyTotal"
              "DischargeEnergyTotal"
              "TotalEnergyOfUserLoad"
              "TotalEnergyToGrid"
              "TotalEnergyToUser" # Energy drawn from grid
              "TotalGenerateEnergy"
            ];
            temperature = [
              "BDCTemperatureA"
              "InverterTemperature"
            ];
            battery = [ "BDCStateOfCharge" ];
            power = [
              "BDCChargePower"
              "BDCDischargePower"
              "OutputPower"
              "PVTotalPower"
              "ReactivePower"
              "TotalForwardPower"
              "TotalLoadPower"
              "TotalReversePower"
            ];
          };
          serial_number = "CZM0DCT004";
          model = "MOD 10KTL3-XH";
        in
        {
          # Includes dependencies for a basic setup
          # https://www.home-assistant.io/integrations/default_config/
          default_config = { };

          http = {
            trusted_proxies = [ "::1" ];
            use_x_forwarded_for = true;
          };

          mqtt = {
            sensor = lib.concatMap (
              { name, value }:
              map (
                jsonKey:
                let
                  device_class = name;
                in
                (
                  {
                    inherit device_class;
                    name = jsonKey;
                    state_topic = "energy/solar";
                    value_template = "{{ value_json.${jsonKey} }}";
                    availability_topic = "energy/solar";
                    availability_template = "{{ value_json.InverterStatus }}";
                    payload_available = "1";
                    expire_after = 300;
                    device = {
                      manufacturer = "Growatt";
                      inherit model serial_number;
                      name = "Wechselrichter";
                      configuration_url = "http://growatt.fritz.box";
                      via_device = "OpenInverterGateway on Growatt ShineWiFi-X";
                      identifiers = [
                        model
                        serial_number
                      ];
                    };
                    state_class = "measurement";
                    unique_id = "${serial_number}_${jsonKey}";
                  }
                  // lib.optionalAttrs (device_class == "power") { unit_of_measurement = "W"; }
                  // lib.optionalAttrs (device_class == "temperature") { unit_of_measurement = "°C"; }
                  // lib.optionalAttrs (device_class == "battery") { unit_of_measurement = "%"; }
                  // lib.optionalAttrs (device_class == "energy") {
                    unit_of_measurement = "kWh";
                    state_class = "total_increasing";
                  }
                )
              ) value
            ) (lib.attrsToList growattSensors);
          };

          sensor = map (powerSensor: {
            name = lib.replaceStrings [ "Power" ] [ "Energy" ] powerSensor;
            platform = "integration";
            source = "sensor.wechselrichter_${lib.toLower powerSensor}";
            unit_prefix = "k";
          }) growattSensors.power;

          automation = [
            {
              alias = "go-e Surplus Charging";
              description = "Feed PV data into go-e Charger for surplus charging";
              trigger = {
                platform = "time_pattern";
                seconds = "/5";
              };
              condition.not = {
                condition = "state";
                entity_id = "sensor.wechselrichter_pvtotalpower";
                state = "unavailable";
              };
              action = {
                service = "mqtt.publish";
                data = {
                  # go-e Charger topic is `go-eCharger/<Serial number>` by default
                  topic = "go-eCharger/235184/ids/set";
                  payload_template = ''
                    {"pGrid":{% if float(states("sensor.wechselrichter_totalforwardpower"))>=0 -%}
                      {{ states("sensor.wechselrichter_totalforwardpower") }}
                    {%- else -%}
                      -{{ states("sensor.wechselrichter_totalreversepower") }}
                    {%- endif %},
                    "pAkku":{% if float(states("sensor.wechselrichter_bdcdischargepower"))>=0 -%}
                      {{ states("sensor.wechselrichter_bdcdischargepower") }}
                    {%- else -%}
                      -{{ states("sensor.wechselrichter_bdcchargepower") }}
                    {%- endif %},
                    "pPv":{{ states("sensor.wechselrichter_pvtotalpower") }}}
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
      virtualHosts."warmplace" = {
        extraConfig = ''
          proxy_buffering off;
        '';
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    1883 # MQTT
    80
  ];
}
