{
  config,
  lib,
  pkgs,
  nzbr,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../common.nix
    ./home-assistant.nix
    ./samba.nix
    ./searxng.nix
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

      address = [ "192.168.0.2/24" ];
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
  networking.firewall.allowedTCPPorts = [
    8080 # SearXNG (temp)
    8123 # home assistant (also temp)
  ];

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
}
