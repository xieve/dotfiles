{
  pkgs,
  config,
  lib,
  ...
}:

let
  secrets = lib.importTOML ./secrets.toml;
  baseFolder = "/mnt/frail/srv/rips";
  configFolder = "/etc/arm";
  uid = 950;
  gid = config.users.groups.media.gid;
  uidStr = toString uid;
  gidStr = toString gid;
  handbrakeArgs = preset: "--preset-import-file '${configFolder}/handbrake/${preset}.json'";
  HB_PRESET_DVD = "MKV 720p30 x265";
  HB_PRESET_BD = "MKV 1080p30 x265";
in
{
  services.automatic-ripping-machine = {
    enable = true;
    enableTranscoding = true;
    settings = {
      DISABLE_LOGIN = true;
      WEBSERVER_IP = "127.0.0.1";
      WEBSERVER_PORT = 27570;
      OMDB_API_KEY = secrets.omdb;
      DATE_FORMAT = "%Y-%m-%d %H:%M:%S";
      UNIDENTIFIED_EJECT = false;
      RAW_PATH = "${baseFolder}/raw/";
      TRANSCODE_PATH = "${baseFolder}/transcoded/";
      # Media will be put into movies/ and shows/ subdirectories
      COMPLETED_PATH = "${baseFolder}/completed/";
      # TODO: remove when config is final
      LOGLEVEL = "DEBUG";
      DELRAWFILES = false;

      # HandBrake
      inherit HB_PRESET_BD HB_PRESET_DVD;
      HB_ARGS_DVD = handbrakeArgs HB_PRESET_DVD;
      HB_ARGS_BD = handbrakeArgs HB_PRESET_BD;
    };
  };

  # ---

  users.users.arm = {
    group = "media";
    inherit uid;
  };

  systemd.tmpfiles.settings."50-arm-handbrake-presets" = {
    "${configFolder}/handbrake"."L+".argument = toString ./handbrake;
    "${baseFolder}/completed/movies"."L+".argument = "/mnt/frail/srv/movies/";
    "${baseFolder}/completed/shows"."L+".argument = "/mnt/frail/srv/shows/";
  };
}
