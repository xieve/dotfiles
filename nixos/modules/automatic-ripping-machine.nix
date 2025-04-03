{
  self,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    concatMapAttrs
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkOption
    ;
  inherit (pkgs) writeShellScript;
  settingsFormat = pkgs.formats.json { };
  arm = self.packages.${pkgs.stdenv.hostPlatform.system}.automatic-ripping-machine;
  cfg = config.services.automatic-ripping-machine;
  cfgFile = settingsFormat.generate "arm.yaml" cfg.settings;
  cfgPath = "/etc/arm";
  BindPaths = with cfg.settings; [
    RAW_PATH
    TRANSCODE_PATH
    COMPLETED_PATH
  ];
in
{
  options.services.automatic-ripping-machine = with lib.types; {
    enable = mkEnableOption "Automatic Ripping Machine";

    user = mkOption {
      type = str;
      default = "arm";
    };

    group = mkOption {
      type = str;
      default = "media";
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    # Needed for MakeMKV
    boot.kernelModules = [ "sg" ];

    services.automatic-ripping-machine.settings = {
      DBFILE = "/var/lib/arm/arm.db";
      LOGPATH = "/var/log/arm/";
      INSTALLPATH = "${arm}/opt/arm/";
    };

    users = {
      users.${cfg.user} = {
        inherit (cfg) group;
        extraGroups = [ "cdrom" ];
        home = mkDefault "/var/lib/arm";
        isSystemUser = mkDefault true;
      };
      groups.${cfg.group} = { };
    };

    services.udev.packages = [ arm ];

    systemd = {
      services.armui = {
        description = "Automatic Ripping Machine Web UI";
        path = [ ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        confinement = {
          enable = true;
          packages = with pkgs; [
            cacert
            cfgFile
          ];
        };
        environment = {
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        serviceConfig = {
          inherit BindPaths;
          Type = "exec";
          User = "arm";
          Restart = "always";
          RestartSec = "3";
          ExecStart = "${arm}/bin/armui";
          ProtectSystem = "strict"; # Enforce read-only access for the entire system except for:
          ProtectHome = true;
          ConfigurationDirectory = "arm"; # /etc/arm
          StateDirectory = "arm"; # /var/lib/arm
          LogsDirectory = [
            "arm"
            "arm/progress"
          ]; # /var/log/arm
          PrivateTmp = true;
        };
      };

      services."arm@" = {
        description = "Automatic Ripping Machine Worker";
        script = ''
          ${arm}/bin/arm --no-syslog --devpath "$1"
        '';
        # confinement.enable = true;
        scriptArgs = "%I";
        serviceConfig = {
          User = "arm";
          ProtectSystem = "strict";
          ProtectHome = true;
          ConfigurationDirectory = "arm";
          StateDirectory = "arm"; # /var/lib/arm
          LogsDirectory = "arm";
          ReadWritePaths = BindPaths ++ [ "/dev/%I" ];
          RuntimeDirectory = "arm";
          # DeviceAllow = [ "/dev/%I rw" ]; #"block-sr rw";
          # BindPaths = BindPaths ++ [ "/dev/%I" ];
          PrivateTmp = true;
        };
      };

      tmpfiles.settings = {
        "50-automatic-ripping-machine" =
          let
            owned = { inherit (cfg) user group; };
          in
          {
            "/var/log/arm/progress"."D" = owned;
            "/mnt/dev"."D" = { };
            "/opt/arm"."L+" = {
              argument = "${arm}/opt/arm";
            };
            "${cfgPath}/arm.yaml"."L+".argument = "${cfgFile}";
          }
          //
            concatMapAttrs
              (filename: type: {
                "${cfgPath}/${filename}".${type} = {
                  argument = "${arm}${cfgPath}/${filename}";
                };
              })
              {
                "apprise.yaml" = "L+";
                "abcde.conf" = "L+";
              };
      };
    };
  };
}
