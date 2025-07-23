{
  pkgs,
  config,
  lib,
  ...
}:

let
  secrets = lib.importTOML ./secrets.toml;
  baseFolder = "/mnt/frail/srv/rips";
  configFolder = "/etc/arm/config";
  uid = 950;
  gid = config.users.groups.media.gid;
  uidStr = toString uid;
  gidStr = toString gid;
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
      COMPLETED_PATH = "${baseFolder}/completed/";
      LOGLEVEL = "DEBUG";
    };
  };

  # ---

  users.users.arm = {
    group = "media";
    inherit uid;
  };
}
