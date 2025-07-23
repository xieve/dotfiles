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
  handbrakeArgs = preset: "--preset-import-gui '${configFolder}/handbrake/${preset}.json'";
in
{
  services.automatic-ripping-machine = {
    enable = true;
    enableTranscoding = true;
    settings = {
      DISABLE_LOGIN = true;
      OMDB_API_KEY = secrets.omdb;
      DATE_FORMAT = "%Y-%m-%d %H:%M:%S";
      UNIDENTIFIED_EJECT = false;
      RAW_PATH = "${baseFolder}/raw/";
      TRANSCODE_PATH = "${baseFolder}/transcoded/";
      # Media will be put into movies/ and shows/ subdirectories
      COMPLETED_PATH = "/mnt/frail/srv/";
      LOGLEVEL = "DEBUG";

      # HandBrake
      HB_ARGS_DVD = handbrakeArgs "MKV 720p30 x265 Slow CRF19";
      HB_ARGS_BD = handbrakeArgs "MKV 1080p30 x265 Slow CRF20";
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
