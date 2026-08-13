{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption;
  cfg = config.services.mitmproxy;
in
{
  options.services.mitmproxy = with lib.types; {
    port = mkOption {
      type = port;
      default = 7617;
    };
    host = mkOption {
      type = str;
      default = "127.0.0.1";
    };
  };

  config = {
    virtualisation.oci-containers.containers.flaresolverr = {
      # image = "ghcr.io/thephaseless/byparr";
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      environment = {
        DISABLE_MEDIA = "true";
        BROWSER_WAIT_TIMEOUT = "0";
      };
      ports = [
        "39318:8191"
      ];
      extraOptions = [
        "--userns=auto"
      ];
    };

    users.users.mitmproxy = {
      isSystemUser = true;
      group = "mitmproxy";
    };
    users.groups.mitmproxy = { };

    systemd.services.mitmproxy = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        FLARESOLVERR_PORT = "39318";
      };
      script = ''
        ${lib.getExe' pkgs.mitmproxy "mitmdump"} \
          --scripts ${./mitmproxy-flaresolverr.py} \
          --set confdir=/var/lib/mitmproxy \
          --set listen_host='${cfg.host}' \
          --set listen_port='${toString cfg.port}'
      '';
      serviceConfig = {
        User = "mitmproxy";
        Group = "mitmproxy";
        StateDirectory = "mitmproxy";

        CapabilityBoundingSet = null;
        DevicePolicy = "closed";
        LockPersonality = true;
        # Required :(
        MemoryDenyWriteExecute = false;
        NoNewPrivileges = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        PrivateIPC = true;
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@privileged @resources"
        ];
      };
    };
  };
}
