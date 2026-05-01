{ pkgs, lib, ... }:

let
  inherit (lib) getExe';
  home = "/run/broadwayd-ghb";
  socket = "${home}/sock";
in
{
  users.users.ghb = {
    isSystemUser = true;
    group = "media";
    inherit home;
  };
  systemd.services = {
    broadwayd-ghb = {
      enable = true;
      script = with pkgs; "${getExe' gtk4 "gtk4-broadwayd"} --unixsocket=${socket} :0";
      serviceConfig = {
        User = "ghb";
        RuntimeDirectory = "broadwayd-ghb";
      };
    };
    ghb =
      let
        wants = [ "broadwayd-ghb.service" ];
      in
      {
        enable = true;
        inherit wants;
        after = wants;
        wantedBy = [ "multi-user.target" ];
        environment = {
          GDK_BACKEND = "broadway";
          BROADWAY_DISPLAY = ":0";
        };
        script = with pkgs; (getExe' handbrake "ghb");
        path = [
        ];
        serviceConfig = {
          User = "ghb";
        };
      };
  };

  xieve.acls.broadwayd-ghb.${socket} = "u:nginx:rw";

  xieve.nginx.virtualHosts."handbrake.xieve.net" = {
    proxyPass = "http://unix:${socket}";
    proxyWebsockets = true;
    auth = true;
  };
}
