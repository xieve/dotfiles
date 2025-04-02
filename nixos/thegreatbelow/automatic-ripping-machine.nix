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
    settings = {
      DISABLE_LOGIN = true;
      OMDB_API_KEY = secrets.omdb;
      DATE_FORMAT = "%Y-%m-%d %H:%M:%S";
      UNIDENTIFIED_EJECT = false;
      SKIP_TRANSCODE = true;
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

  # virtualisation.oci-containers.containers.arm = {
  #   image = "automaticrippingmachine/automatic-ripping-machine";
  #   ports = [
  #     "127.0.0.1:23976:8080"
  #   ];
  #   volumes = [
  #     "${configFile}:${configFolder}/arm.readonly.yaml"
  #     "${baseFolder}:${baseFolder}"
  #     "${pkgs.writeScript "arm-nixos-module-setup.sh" ''
  #       #!/usr/bin/env bash
  #
  #       chown -R ${uidStr}:${gidStr} /home/arm/ /etc/arm/
  #
  #       # The python script starting the server expects arm.yaml to be writeable.
  #       cd ${configFolder}
  #       install --no-target-directory --owner=${uidStr} --group=${gidStr} --mode=ug=rw,o= arm.readonly.yaml arm.yaml
  #     ''}:/etc/my_init.d/20-nixos-module-setup.sh"
  #
  #     "${pkgs.writeScript "arm-start-udev.sh" ''
  #       #!/usr/bin/env bash
  #
  #       /etc/init.d/udev start
  #     ''}:/etc/my_init.d/start_udev.sh"
  #
  #     "${pkgs.writeText "arm-mknod-optical.rules" ''
  #       ACTION=="change", RUN+="/usr/bin/logger -p local0.notice -t udev change $kernel"
  #       ACTION=="change", KERNEL=="s[rg][0-9]*", RUN+="/usr/bin/bash -c 'logger -p local0.notice -t mknod $$(mknod /dev/$kernel --mode=666 b $major $minor && echo success || echo fail)'"
  #     ''}:/lib/udev/rules.d/10-mknod-optical.rules"
  #     #         ACTION=="change", SUBSYSTEM=="block", KERNEL=="s[rg][0-9]*", ENV{ID_FS_TYPE}!="", RUN+="/usr/bin/bash -c 'logger -p local0.notice -t mknod $$(mknod /dev/$kernel --mode=666 b $major $minor && echo success || echo fail)'"
  #   ];
  #   environment = {
  #     ARM_UID = uidStr;
  #     ARM_GID = gidStr;
  #     SYSLOGNG_OPTS="--no-caps";
  #   };
  #   # Allow dynamically attaching optical drives via mknod
  #   extraOptions = [
  #     "--device-cgroup-rule=b 11:0 rwm"
  #     "--device-cgroup-rule=b 11:1 rwm"
  #   ];
  #   capabilities = {
  #     MKNOD = true;
  #   };
  # };
  #
  # # Whenever a disk is inserted, attach the drive inside the container
  # services.udev.packages = [
  #     ];
}
