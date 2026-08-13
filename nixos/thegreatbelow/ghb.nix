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
        RuntimeDirectoryPreserve = true;
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
          Restart = "always";
        };
      };
  };

  systemd.tmpfiles.settings.ghb =
    let
      presetsFile =
        pkgs.runCommandLocal "presets.json"
          {
            src = ./handbrake;
          }
          # Merges two JSONs
          ''
            cd "$src"
            ${lib.getExe pkgs.jq} --slurp 'add + { PresetList: ( map(.PresetList) | add ) } | {
                VersionMajor,
                VersionMinor,
                VersionMicro,
                PresetList: [{
                  Folder: true,
                  PresetName: "Custom",
                  Type: 1,
                  FolderOpen: true,
                  ChildrenArray: .PresetList
                }]
              }' 'MKV 1080p30 x265.json' 'MKV 720p30 x265.json' > $out
          '';
      bookmarksFile = pkgs.writeText "ghb-bookmarks" ''
        file:///srv/media
      '';
    in
    {
      "${home}/.config/ghb/presets.json"."L+".argument = presetsFile.outPath;
      "${home}/.config/gtk-3.0/bookmarks"."L+".argument = bookmarksFile.outPath;
    };

  xieve.acls.broadwayd-ghb.${socket} = "u:nginx:rw";

  xieve.nginx.virtualHosts."handbrake.xieve.net" = {
    proxyPass = "http://unix:${socket}";
    proxyWebsockets = true;
    auth = true;
  };
}
