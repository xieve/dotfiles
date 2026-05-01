{ pkgs, lib, ... }:

let
  download-dir = "/srv/media/downloads";
  uidConfig = {
    users = {
      users.transmission = {
        uid = 70;
        group = "transmission";
      };
      groups.transmission = { };
    };
  };
in
{
  containers.transmission = {
    config = {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        # https://github.com/johman10/flood-for-transmission
        webHome = pkgs.flood-for-transmission;
        openRPCPort = true;
        settings = {
          inherit download-dir;
          umask = "113";
          rpc-host-whitelist = "transmission.xieve.net";
          incomplete-dir-enabled = false;
        };
      };

      # https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission.serviceConfig = {
        RootDirectoryStartOnly = lib.mkForce null;
        RootDirectory = lib.mkForce null;
      };

      networking = {
        useNetworkd = true;
        useDHCP = lib.mkForce true;
      };
      services.resolved.enable = false;
    }
    // uidConfig;

    autoStart = true;
    extraFlags = [
      "--bind=${download-dir}:${download-dir}:idmap"
      "--network-veth"
    ];
    privateUsers = "pick";
  };

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    # Use "ve-*" when using nftables instead of iptables
    internalInterfaces = [ "ve-+" ];
    externalInterface = "wg0";
  };

  networking.firewall.interfaces."ve-+".allowedUDPPorts = [ 67 ];

  systemd.tmpfiles.settings."40-transmission-download".${download-dir}."d" = {
    user = "transmission";
    group = "media";
  };

  xieve.nginx.virtualHosts."transmission.xieve.net" = {
    proxyPass = "http://transmission:9091";
    auth = true;
    proxyWebsockets = true;
    extraConfig = ''
      proxy_pass_header X-Transmission-Session-Id;
    '';
  };
}
// uidConfig
