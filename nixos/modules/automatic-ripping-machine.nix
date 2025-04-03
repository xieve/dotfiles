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
  json = pkgs.formats.json { };
  ini = pkgs.formats.iniWithGlobalSection { };
  arm = self.packages.${pkgs.stdenv.hostPlatform.system}.automatic-ripping-machine;
  cfg = config.services.automatic-ripping-machine;
  cfgFile = json.generate "arm.yaml" cfg.settings;
  appriseFile = json.generate "apprise.yaml" cfg.appriseSettings;
  abcdeFile = ini.generate "abcde.conf" { globalSection = cfg.abcdeSettings; };
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
      inherit (json) type;
      default = { };
    };

    appriseSettings = mkOption {
      inherit (json) type;
      default = { };
    };

    abcdeSettings = mkOption {
      type = attrsOf ini.lib.types.atom;
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
            abcdeFile
            appriseFile
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
        # confinement.enable = true;
        serviceConfig = {
          User = "arm";
          ExecStart = ''
            ${arm}/bin/arm --no-syslog --devpath "%I"
          '';
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
        "50-automatic-ripping-machine" = {
          "${cfgPath}/arm.yaml"."L+".argument = "${cfgFile}";
          "${cfgPath}/apprise.yaml"."L+".argument = "${appriseFile}";
          "${cfgPath}/abcde.conf"."L+".argument = "${abcdeFile}";
        };
      };
    };
  };
}
