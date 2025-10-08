{
  lib,
  config,
  pkgs,
  selfPkgs,
  home-assistant-theme-material-you,
  home-assistant-scheduler-card,
  ...
}:
let
  inherit (lib) concatMapAttrs mapAttrs;
  cfg = config.services.home-assistant;
in
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "motionblinds_ble"
      "mqtt"
      "tasmota"
      "local_calendar"
      "wled"
    ];
    customComponents = with selfPkgs; [
      homeassistant-localtuya
      homeassistant-node-red
      homeassistant-scheduler-component
    ];
    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      bubble-card
      card-mod
      selfPkgs.homeassistant-scheduler-card
    ];
    config = {
      http = {
        server_host = "::1";
      };
      frontend = {
        themes = "!include_dir_merge_named themes";
        extra_module_url = [
          "/local/material-rounded-theme.js"
        ]
        ++ map (
          card: "/local/nixos-lovelace-modules/${card.entrypoint or (card.pname + ".js")}?${card.version}"
        ) cfg.customLovelaceModules;
      };
      # frontend.themes = "!include themes/bubble.yaml";
    };
  };

  # Themes
  # This would be nice as a reusable module
  systemd.tmpfiles.settings.home-assistant-themes =
    let
      user = "hass";
      group = user;
    in
    concatMapAttrs
      (path: value: {
        "/var/lib/hass/${path}" = mapAttrs (type: cfg: ({ inherit user group; } // cfg)) value;
      })
      {
        "themes".d = { };
        "themes/material-rounded-theme.yaml".L = {
          argument = "${home-assistant-theme-material-you}/themes/material_rounded.yaml";
        };
        "www/material-rounded-theme.js".L = {
          argument = "${home-assistant-theme-material-you}/dist/material-rounded-theme.js";
        };
        "www/fonts".d = { };
        "www/fonts/figtree.ttf".L = {
          argument = "${pkgs.google-fonts}/share/fonts/truetype/Figtree[wght].ttf";
        };
        "www/fonts/figtree-italic.ttf".L = {
          argument = "${pkgs.google-fonts}/share/fonts/truetype/Figtree-Italic[wght].ttf";
          # WARN: requires manual setup (add as lovelace resource)
        };
        "www/fonts.css".L = {
          argument =
            (pkgs.writeText "fonts.css" ''
              @font-face {
                font-family: 'Figtree';
                font-style: normal;
                font-weight: 300 900;
                font-display: swap;
                src: url('./fonts/figtree.ttf') format('truetype');
              }
              @font-face {
                font-family: 'Figtree';
                font-style: italic;
                font-weight: 300 900;
                font-display: swap;
                src: url('./fonts/figtree-italic.ttf') format('truetype');
              }
            '').outPath;
        };
      };
}
