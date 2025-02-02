{
  config,
  lib,
  pkgs,
  nzbr,
  ...
}:

let
  addr = {
    v4 = "192.168.0.2";
    v6 = "fd00::acab";
  };
in
{
  imports = [
    ./hardware.nix
    ../common.nix
    ./home-assistant.nix
    ./samba.nix
    ./searxng.nix
    ./automatic-ripping-machine.nix
    ./nginx.nix
  ];

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

  # zfs
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "df6e6c66"; # head -c 8 /etc/machine-id
  services.zfs.autoScrub.enable = true;

  # Network
  networking.hostName = "thegreatbelow";
  networking.useDHCP = false; # Disable dhcpcd because we'll use networkd

  systemd.network = {
    enable = true;

    networks."10-lan" = {
      # Interface
      matchConfig.Name = "eno*";

      address = [ "${addr.v4}/24" "${addr.v6}/64" ];
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
    8123 # home assistant (also temp)
  ];

  # DNS
  # This is queried by the Fritzbox to obtain local addresses for this machine at *.xieve.net.
  # All other non-local domains have rebind protection by the Fritzbox.
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "::1" "127.0.0.1" addr.v4 addr.v6 ];
        access-control = [ "::/0 allow" "0.0.0.0/0 allow" ];
        # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;

        local-zone = [
          ''"xieve.net." redirect''
          ''"cloud.xieve.net." transparent''
        ];
        local-data = [
          ''"xieve.net. A ${addr.v4}"''
          ''"xieve.net. AAAA ${addr.v6}"''
        ];
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "9.9.9.9#dns.quad9.net"
            "149.112.112.112#dns.quad9.net"
            "2620:fe::fe#dns.quad9.net"
            "2620:fe::9#dns.quad9.net"
          ];
          forward-tls-upstream = true;  # DNS over TLS
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
    openssh.enable = true;
    searx.enable = true;
    tailscale.enable = true;
  };

  # jellyfin
  services.jellyfin = {
    enable = true;
  };
  users.users.jellyfin.extraGroups = [ "media" ];
}
