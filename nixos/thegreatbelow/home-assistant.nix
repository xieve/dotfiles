{
  self,
  lib,
  pkgs,
  home-assistant-theme-bubble,
  home-assistant-theme-material-you,
  home-assistant-card-big-slider,
  ...
}:
let
  inherit (lib) concatMapAttrs mapAttrs;
in {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "motionblinds_ble"
    ];
    customComponents = [
      # TODO: having to specify the arch like this is super ugly. probably should use an overlay
      self.packages.${pkgs.system}.homeassistant-localtuya
    ];
    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      bubble-card
      card-mod
    ];
    config = {
      http = {
        server_host = "::1";
      };
      frontend = {
        themes = "!include_dir_merge_named themes";
        extra_module_url = [
          "/local/nixos-lovelace-modules/card-mod.js"
          "/local/material-rounded-theme.js"
          "/local/big-slider-card.js"
        ];
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
        "themes/bubble.yaml".L = {
          argument = "${home-assistant-theme-bubble}/themes/bubble.yaml";
        };
        "themes/material-rounded-theme.yaml".L = {
          argument = "${home-assistant-theme-material-you}/themes/material_rounded.yaml";
        };
        "www/material-rounded-theme.js".L = {
          argument = "${home-assistant-theme-material-you}/dist/material-rounded-theme.js";
        };
        "www/big-slider-card.js".L = {
          argument = "${home-assistant-card-big-slider}/dist/big-slider-card.js";
        };
      };
}
