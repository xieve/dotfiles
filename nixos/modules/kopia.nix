# From https://github.com/NixOS/nixpkgs/issues/163024#issuecomment-1822772284

{
  config,
  lib,
  options,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.kopia;

  json = pkgs.formats.json { };
  cfgFile = json.generate "kopia.json" (
    cfg.settings
    // {
      # "Token" parser (which is a config file encoded in base64 PLUS a password) wants this field
      version = "1";
    }
  );
in
{
  options = {
    services.kopia = mkOption {
      description = "Kopia backup service";
      type =
        with types;
        submodule {
          options = {

            enable = mkEnableOption "Kopia backups";

            user = mkOption {
              type = str;
              default = "kopia";
              description = ''
                User account under which backups are performed.

                It is recommended to leave this value unmodified. In that case, this user will be
                automatically created and dynamically granted read-only access to all specified
                directories via [ACLs](https://wiki.archlinux.org/title/Access_Control_Lists).
                Note that this requires ACLs to be enabled on those filesystems that you want to
                back up. Ext2/3/4 and Btrfs do this by default, while *ZFS does not*.
              '';
            };

            settings = mkOption {
              type = json.type;
              description = ''
                Config for Kopia. See
                [Kopia Documentation](https://kopia.io/docs/reference/command-line/#configuration-file).

                You will most likely want to set up Kopia manually first, then read the config file it
                generated and create a configuration inspired by that. This module will only connect to
                *existing* repositories.

                We also pass these settings as a "token", that's why we can specify a password here as well.
                **Note however**: If you store your secrets here, they will be copied to the Nix store and
                **readable for all users**!

                If you are using local storage for your repository, remember to grant the correct permissions!
                This is not done automatically by this module as not to cause potentially unwanted effects.
                You should most likely restrict read and write access to the `kopia` user only.
              '';
              example = {
                storage = {
                  type = "filesystem";
                  config.path = "/mnt/tank/kopia/";
                };
                password = "SUPER_SECRET_REPOSITORY_PASSWORD";
              };
            };

            settingsFile = mkOption {
              type = str;
              description = ''
                Path to JSON config file for Kopia.
                This file is merged *at runtime* with `services.kopia.settings`, which means it will not get
                copied to the nix store by this module.

                We also pass these settings as a "token", that's why we can specify a password here as well.

                Example file content:
                ```
                {"storage": {"password": "STORAGE_PASSWORD"}, "password": "REPOSITORY_PASSWORD"}
                ```
              '';
              example = "/etc/kopia/secrets.json";
              default = "";
            };


            schedule = mkOption {
              type = str;
              default = "daily";
              description = "Systemd OnCalendar schedule to run Kopia backups at.";
            };

            directories = mkOption {
              type = listOf str;
              default = [ ];
              description = ''
                List of directories to be backed up.

                If `services.kopia.user` is left at default, appropriate ACLs will be set automatically
                such that the `kopia` user has read-only access to these directories.
              '';
              example = [
                "/var/lib"
                "/home"
              ];
            };

            timerConfig = mkOption {
              type = attrsOf anything;
              default = { };
              description = "Extra options for the systemd timer.";
              example = {
                RandomizedDelaySec = "1d";
                FixedRandomDelay = true;
              };
            };
          };
        };
    };
  };
  config = mkIf cfg.enable {
    users = mkIf (cfg.user == "kopia") {
      users = {
        kopia = {
          group = "kopia";
          isSystemUser = true;
        };
      };
      groups.kopia = { };
    };

    systemd = lib.mkMerge (
      map (
        directory:
        let
          serviceName = "kopia${replaceStrings [ "/" ] [ "-" ] directory}";
        in
        {
          services.${serviceName} = {
            description = "Kopia Snapshot ${directory}";
            path = with pkgs; [ kopia jq zsh ];
            serviceConfig = {
              Type = "oneshot";
              User = cfg.user;
              ProtectSystem = "strict"; # Enforce read-only access for the entire system except for:
              CacheDirectory = "kopia"; # /var/cache/kopia/
              LogsDirectory = "kopia"; # /var/log/kopia/
              RuntimeDirectory = "kopia"; # /run/kopia/
              CacheDirectoryMode = "0700";
              RuntimeDirectoryMode = "0700";
              ExecStart = pkgs.writeShellScript "kopia.sh" ''
                cd "$RUNTIME_DIRECTORY" || exit

                # Env vars taken from official Dockerfile
                export \
                  KOPIA_CONFIG_PATH="$(pwd)/merged.json" \
                  KOPIA_CACHE_DIRECTORY="$CACHE_DIRECTORY" \
                  KOPIA_LOG_DIR="$LOGS_DIRECTORY" \
                  KOPIA_CHECK_FOR_UPDATES=false \
                  HOME="$(pwd)" # Kopia wants to write to $HOME really, really badly.

                  # KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=false

                jq --slurp add '${cfgFile}' '${cfg.settingsFile}' > merged.json ||
                  cp '${cfgFile}' merged.json # If settingsFile is not specified, fall back

                # Kopia will not read *repository* passwords from plain-text config files, so we
                # have to encode our config in base64 first and pass it as a "token" (unpadded base64)...
                # The credentials will be persisted on disk for as long as the snapshot is running,
                # that's why we have set strict permissions above.
                base64 < merged.json | tr -d "=" > merged.json.base64
                kopia repository connect from-config --token-file=merged.json.base64
                kopia snapshot create '${directory}'
                kopia repository disconnect
              '';
            };
          };
          timers.${serviceName} = lib.mkMerge [
            {
              enable = true;
              wantedBy = [ "timers.target" ];
              partOf = [ "${serviceName}.service" ];
              timerConfig = {
                Unit = "${serviceName}.service";
                OnCalendar = [ "${cfg.schedule}" ];
              };
            }
            cfg.timerConfig
          ];
          tmpfiles.rules =
            # `A+`: Append to existing ACLs, recursively
            # `u:kopia:rX`: Grant user kopia read and if directory, list permissions
            lib.mkIf (cfg.user == "kopia") [
              ''A+ "${directory}" - - - - u:kopia:r-X''
            ];
        }
      ) cfg.directories
    );
  };
}
