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
    ./kanidm.nix
  ];

  options.thegreatbelow =
    with lib.types;
    let
      inherit (lib) mkOption;
    in
    {
      ipAddress = {
        v4 = mkOption {
          type = str;
          default = "192.168.0.2";
        };
        v6 = mkOption {
          type = str;
          default = "fd00::acab";
        };
      };
    };

  config = {
    # Serial Console
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];

    # Encrypt swap on boot with new randomly generated key
    swapDevices = [
      {
        device = "/dev/disk/by-partuuid/936d5326-778d-4427-bd23-031d26d302d5";
        randomEncryption.enable = true;
      }
    ];

    # Graphics drivers for HW accelerated transcoding
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      # GPU is not new enough for the open source kernel modules
      open = false;
      # Keep GPU online while headless
      nvidiaPersistenced = true;
    };

    # zfs
    boot.supportedFilesystems = [ "zfs" ];
    networking.hostId = "df6e6c66"; # head -c 8 /etc/machine-id
    services.zfs.autoScrub.enable = true;

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
    services.resolved.domains = [ "~xieve.net" ];

    systemd.network = {
      enable = true;

      networks."10-lan" = {
        # Interface
        matchConfig.Name = "eno*";

        address = [
          "${cfg.ipAddress.v4}/24"
          "${cfg.ipAddress.v6}/64"
        ];
        routes = [ { Gateway = "192.168.0.1"; } ];

        # Accept router advertisements, but set a static suffix
        networkConfig.IPv6AcceptRA = true;
        ipv6AcceptRAConfig = {
          Token = "::acab";
          # if we don't set this, we'll get an extra IPv6 global address
          DHCPv6Client = false;
        };

        linkConfig.RequiredForOnline = "routable";

        dns = [
          "127.0.0.1"
          "192.168.0.1"
          "9.9.9.9"
        ];
      };
    };
    # Any link is sufficient, we use only one of two interfaces
    systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
      ""
      "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any --timeout=120"
    ];

    # Firewall
    networking.firewall.allowedUDPPorts = [ 53 ];
    networking.firewall.allowedTCPPorts = [
      8080 # SearXNG (temp)
    ];

    # DNS
    # This is queried by the Fritzbox to obtain local addresses for this machine at *.xieve.net.
    # All other non-local domains have rebind protection by the Fritzbox.
    services.unbound = {
      enable = true;
      settings = {
        server =
          let
            interface = [
              "lo"
              "eno1"
              "tailscale0"
            ];
          in
          {
            inherit interface;
            interface-action = map (i: "${i} allow") interface;
            # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
            harden-glue = true;
            harden-dnssec-stripped = true;
            use-caps-for-id = false;
            prefetch = true;
            edns-buffer-size = 1232;

            interface-view = [
              "lo local"
              "eno1 local"
              "tailscale0 tailscale"
            ];
          };
        view =
          let
            local-zone = [
              ''"xieve.net." redirect''
              ''"cloud.xieve.net." transparent''
            ];
          in
          [
            {
              inherit local-zone;
              name = "local";
              local-data = [
                ''"xieve.net. 60 IN A ${cfg.ipAddress.v4}"''
                ''"xieve.net. 60 IN AAAA ${cfg.ipAddress.v6}"''
              ];
            }
            {
              inherit local-zone;
              name = "tailscale";
              local-data = [
                ''"xieve.net. 60 IN A 100.67.195.13"''
                ''"xieve.net. 60 IN AAAA fd7a:115c:a1e0::b601:c30d"''
              ];
            }
          ];
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "9.9.9.9#dns.quad9.net"
              "149.112.112.112#dns.quad9.net"
              "2620:fe::fe#dns.quad9.net"
              "2620:fe::9#dns.quad9.net"
            ];
            forward-tls-upstream = true; # DNS over TLS
          }
        ];
      };
    };

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
    };

    # jellyfin
    services.jellyfin = {
      enable = true;
    };
    users.users.jellyfin.group = lib.mkForce "media";
  };
}
