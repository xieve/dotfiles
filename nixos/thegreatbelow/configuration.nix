{ config, lib, pkgs, nzbr, ... }:

{
  imports = [
    ./hardware.nix
    ../common.nix
  ];

  networking.hostName = "thegreatbelow";


  # Network
  networking.useDHCP = false;  # Disable dhcpcd because we'll use networkd

  systemd.network = {
    enable = true;

    networks."10-lan" = {
      # Interface
      matchConfig.Name = "enp*s*";

      address = [ "192.168.0.2/24" ];
      routes = [ { routeConfig.Gateway = "192.168.0.1"; } ];

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


  # Firewall
  networking.firewall.allowedTCPPorts = [
    8080  # SearXNG (temp)
  ];


  # temp fix for perms as long as this is a VM
  # user is called "nobody" on unraid
  users.users.unraidnobody = {
    uid = 99;
    group = "users";
  };


  # misc services
  services = {
    qemuGuest.enable = true;
    openssh.enable = true;
    searx.enable = true;
    samba = {
      enable = true;
      openFirewall = true;
      shares = {
        public = {
          path = "/mnt/user/public";
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
        force create mode = 0666
        force directory mode = 0777
        force user = unraidnobody
        force group = users
        create mask = 0666
        directory mask = 0777
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
  programs.mosh.enable = true;


  # urbackup
  boot.supportedFilesystems = [ "ntfs" ];  # for mounting backups
  nzbr.service.urbackup = {
    enable = true;
    backupfolder = "/mnt/user/urbackup/";
    config = {
      LOGFILE = "/mnt/user/appdata/binhex-urbackup/urbackup/log/urbackup.log";
      LOGLEVEL = "debug";
      #USER = "urbackup";
    };
    package = nzbr.packages.x86_64-linux.urbackup2-server;
    dataset.images = "";
    dataset.files = "";
  };
  systemd.services.urbackup-server = {
    #serviceConfig.User = lib.mkForce config.nzbr.service.urbackup.config.USER;
    serviceConfig.Restart = "on-failure";
  };
  fileSystems."/var/urbackup" = {
    device = "/mnt/user/appdata/binhex-urbackup/urbackup";
    fsType = "none";
    options = [ "bind" ];
  };
  programs.fuse.userAllowOther = true;

  users.groups.users.members = [ "root" "urbackup" ];

  users.groups.urbackup.members = [ "root" ];


  # jellyfin
  services.jellyfin = let 
    basePath = "/mnt/user/appdata/binhex-jellyfin";
  in {
    enable = true;
    openFirewall = true;
    cacheDir = "${basePath}/cache";
    configDir = "${basePath}/config";
    dataDir = "${basePath}/data";
    logDir = "${basePath}/logs";
  };
}
