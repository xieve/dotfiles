{
  pkgs,
  config,
  lib,
  nixpkgs-stable,
  ...
}:

let
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
      DATE_FORMAT = "%Y-%m-%d %H:%M:%S";
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

  systemd.services = {
    "arm@" = {
      serviceConfig.ReadWritePaths = [
        "/mnt/frail/srv/movies"
        "/mnt/frail/srv/shows"
      ];
      environment = {
        ARM_MAKEMKV_PERMA_KEY_FILE = "%d/MAKEMKV_PERMA_KEY";
      };
      serviceConfig.SetCredentialEncrypted = [
        ''
          MAKEMKV_PERMA_KEY: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABqr976tphr25P3KoQAAAAAAz5dn \
            gy/4pALKqUVBIN9IgV9v0RS3h0GYHFglxHhVR7x9HHQ2Jsuuj2/rIRMctaSihhAVT6Iu/ \
            Y9UPotXZU6mK1wWJsfEN2IwvVEA7qZOPg1JRMUC+sDxcJ9DKm7kDiziRFfdwnZE+znBrD \
            2Q9gtDnFK80qRymWL7u5F6w==
        ''
      ];
    };

    armui = {
      environment = {
        ARM_OMDB_API_KEY_FILE = "%d/OMDB_API_KEY";
      };
      serviceConfig.SetCredentialEncrypted = [
        ''
          OMDB_API_KEY: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAXlninw82kE8nfIUIAAAAA1PDAy \
            cEFyzZZRe2yhxetzR0KTfDpcuYhHQnZdKqn3ejptIoHjRZVYIh8UgOeXBJ25XBdgpLa6N \
            Q=
        ''
      ];
    };
  };

  systemd.tmpfiles.settings."50-arm-handbrake-presets" = {
    "${configFolder}/handbrake"."L+".argument = toString ./handbrake;
    "${baseFolder}/completed/movies"."L+".argument = "/mnt/frail/srv/movies/";
    "${baseFolder}/completed/shows"."L+".argument = "/mnt/frail/srv/shows/";
  };
}
