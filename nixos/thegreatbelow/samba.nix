{ lib, config, ... }:

{
  # allow multicast for wsdd
  #system.activationScripts = { samba-wsdd.text = "${pkgs.ipset}/bin/ipset create samba-wsdd hash:ip,port timeout 3 -exist"; };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p udp -m pkttype --pkt-type multicast -m udp --dport 3702 -d 239.255.255.250/32 -j nixos-fw-accept
    ip6tables -A nixos-fw -p udp -m pkttype --pkt-type multicast -m udp --dport 3702 -d ff02::c/128 -j nixos-fw-accept
  '';

  services = {
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          #server string = The Great Below
          "netbios name" = lib.toUpper config.networking.hostName;

          "log level" = 4;

          "use sendfile" = "yes";
          deadtime = 30;
          # if a client is gone for 40s, assume connection lost and prevent zombie locks
          # https://serverfault.com/questions/204812/how-to-prevent-samba-from-holding-a-file-lock-after-a-client-disconnects/907850#907850
          "socket options" = "TCP_NODELAY SO_KEEPALIVE TCP_KEEPIDLE=30 TCP_KEEPCNT=3 TCP_KEEPINTVL=3";

          # smbpasswd will set the unix password as well
          "unix password sync" = "yes";

          "hosts allow" = "192.168.0.";
          "hosts deny" = "ALL";
          "restrict anonymous" = 2;
          "map to guest" = "bad user"; # needed to make public work
          "access based share enum" = "yes";
          "guest account" = "nobody";

          browseable = "yes";
          writeable = "yes";
          "force create mode" = "0664";
          "force directory mode" = "0775";
          #force user = nobody
          "force group" = "users";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
        public = {
          path = "/mnt/frail/srv/public";
          public = "yes";
          #"guest ok" = "yes";
        };
        hidden = {
          path = "/mnt/frail/srv/hidden";
          "valid users" = [ "xieve" ];
        };
        kopia = {
          path = "/mnt/frail/kopia";
          "valid users" = [ "xieve" ];
        };
        movies.path = "/mnt/frail/srv/movies";
        shows.path = "/mnt/frail/srv/shows";
        rips.path = "/mnt/frail/srv/rips";
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      extraOptions = [ "--verbose" ];
    };
  };
}
