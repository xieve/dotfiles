{
  config,
  lib,
  pkgs,
  nzbr,
  ...
}:

let
  cfg = config.thegreatbelow;
in
{
  imports = [
    ./hardware.nix
    ../common.nix
    ./acme.nix
    ./mosquitto.nix
    ./home-assistant.nix
    ./samba.nix
    ./searxng.nix
    ./automatic-ripping-machine.nix
    ./nginx.nix
    ./lldap.nix
    ./ddclient.nix
    ./unbound.nix
    ./mollysocket.nix
    ./hydrus.nix
    ./authelia.nix
    ./karakeep.nix
    ./kopia.nix
    ./netdata.nix
    ./pocket-id.nix
  ];

  options.thegreatbelow =
    let
      inherit (lib) mkOption types;
      strOption =
        default:
        mkOption {
          inherit default;
          type = types.str;
        };
      srv = "/mnt/frail/srv";
    in
    {
      ipAddress = {
        v4 = strOption "192.168.0.2";
        v6 = strOption "fd00::acab";
        exposed = {
          v4 = strOption "192.168.0.4";
          v6Suffix = strOption "::c0:ffee";
        };
        tailscale = {
          v4 = strOption "100.67.195.13";
          v6 = strOption "fd7a:115c:a1e0::b601:c30d";
        };
      };
      exposedInterface = strOption "enp4s0f0";
      paths = {
        inherit srv;
        media = strOption "${srv}/media";
      };
    };

  config = {
    # Serial Console
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];

    xieve.hardware.swapDevice = "/dev/disk/by-partuuid/936d5326-778d-4427-bd23-031d26d302d5";

    # Graphics drivers for HW accelerated transcoding
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "mga" ];
    # hardware.nvidia = {
    #   # GPU is not new enough for the open source kernel modules
    #   open = false;
    #   # Keep GPU online while headless
    #   nvidiaPersistenced = true;
    # };

    # zfs
    boot.supportedFilesystems = [ "zfs" ];
    networking.hostId = "df6e6c66"; # head -c 8 /etc/machine-id
    services.zfs.autoScrub.enable = true;

    # Directory setup
    systemd.tmpfiles.settings."10-srv" = {
      "/srv".L.argument = srv;
    };

    # Network
    networking = {
      hostName = "thegreatbelow";
      useDHCP = false; # Disable dhcpcd because we'll use networkd
      nameservers = [
        "127.0.0.1"
        "192.168.0.1"
        "9.9.9.9"
      ];
    };

    systemd.network = {
      enable = true;

      networks =
        let
          routes = [ { Gateway = "192.168.0.1"; } ];

          dns = [
            "127.0.0.1"
            "192.168.0.1"
            "9.9.9.9"
          ];
        in
        {
          "10-lan" = {
            inherit routes dns;
            # Interface
            matchConfig.Name = "enp4s0f0";

            address = [
              "${cfg.ipAddress.exposed.v4}/24"
              "${cfg.ipAddress.v4}/24"
              "${cfg.ipAddress.v6}/64"
            ];
            # Accept router advertisements, but set a static suffix
            networkConfig.IPv6AcceptRA = true;
            ipv6AcceptRAConfig = {
              Token = "static:${cfg.ipAddress.exposed.v6Suffix}";
              # if we don't set this, we'll get an extra IPv6 global address
              DHCPv6Client = false;
            };
            linkConfig.RequiredFamilyForOnline = "both";
          };
        };
    };
    # Any link is sufficient, we use only one of two interfaces
    systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
      ""
      "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --ignore=tailscale0"
    ];

    # Firewall
    networking.firewall.allowedUDPPorts = [ 53 ];
    networking.firewall.allowedTCPPorts = [
      8080 # SearXNG (temp)
    ];

    users.groups.media = {
      gid = 2000;
      members = [ "xieve" ];
    };

    # podman setup
    virtualisation = {
      podman = {
        enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # misc services
    services = {
      openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
      searx.enable = true;
      tailscale = {
        enable = true;
        extraSetFlags = [
          "--advertise-exit-node"
          "--exit-node-allow-lan-access"
        ];
        useRoutingFeatures = "server";
      };
      node-red = {
        enable = true;
        withNpmAndGcc = true;
      };
      avahi = {
        enable = true;
        publish.enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      atuin = {
        enable = true;
        port = 37889;
      };
    };

    # jellyfin
    services.jellyfin = {
      enable = true;
    };
    users.users.jellyfin.group = lib.mkForce "media";
  };
}
