{
  config,
  lib,
  pkgs,
  nzbr,
  ...
}:
let
  satisfactoryPorts = [ 15777 15000 7777 ];
in {
  imports = [
    ./hardware.nix
    ../common.nix
  ];

  # Serial Console
  boot.kernelParams = [ "console=tty0" "console=ttyS0,115200n8" ];

  # When RAM fills up, compress it before swapping to disk
  zramSwap.enable = true;

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
      # (global scope IPv6 address will always end in tactical cabbage)
      networkConfig.IPv6AcceptRA = true;
      ipv6AcceptRAConfig = {
        Token = "::7ac7:1ca1:cab:ba9e";
        # if we don't set this, we'll get an extra IPv6 global address
        DHCPv6Client = false;
      };

      linkConfig.RequiredForOnline = "routable";
    };
  };
  # Any link is sufficient, we use only one of two interfaces
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    ""
    "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any --timeout=120"
  ];

  # Firewall
  networking.firewall.allowedUDPPorts = satisfactoryPorts;
  networking.firewall.allowedTCPPorts = satisfactoryPorts ++ [ 8080 /* SearXNG (temp) */ ];

  # misc services
  services = {
    openssh.enable = true;
    searx.enable = true;
    samba = {
      enable = true;
      openFirewall = true;
      shares = {
        public = {
          path = "/mnt/frail/srv/public";
          writeable = "yes";
          public = "yes";
          #"guest ok" = "yes";
        };
      };
      extraConfig = ''
        workgroup = WORKGROUP
        #server string = The Great Below
        #netbios name = ${lib.toUpper config.networking.hostName}

        log level = 4

        use sendfile = yes
        deadtime = 30

        # smbpasswd will set the unix password as well
        unix password sync = yes

        hosts allow = 192.168.0. 127.0.0.1 localhost
        hosts deny = ALL
        server min protocol = SMB3_11
        client ipc min protocol = SMB3_11
        client signing = mandatory
        server signing = mandatory
        client ipc signing = mandatory
        client NTLMv2 auth = yes
        smb encrypt = required
        restrict anonymous = 2
        null passwords = No
        raw NTLMv2 auth = no
        map to guest = never
        access based share enum = yes
        guest account = nobody

        browseable = yes
        force create mode = 0664
        force directory mode = 0775
        #force user = nobody
        force group = users
        create mask = 0664
        directory mask = 0775
      '';
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      extraOptions = [ "--verbose" ];
    };
  };
  # allow multicast for wsdd
  #system.activationScripts = { samba-wsdd.text = "${pkgs.ipset}/bin/ipset create samba-wsdd hash:ip,port timeout 3 -exist"; };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p udp -m pkttype --pkt-type multicast -m udp --dport 3702 -d 239.255.255.250/32 -j nixos-fw-accept
    ip6tables -A nixos-fw -p udp -m pkttype --pkt-type multicast -m udp --dport 3702 -d ff02::c/128 -j nixos-fw-accept
  '';

  # jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
}
