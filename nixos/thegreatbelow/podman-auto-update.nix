{ config, lib, ... }:

{
  systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];

  # Enable rollback
  systemd.services.podman-auto-update.serviceConfig = {
    ExecStart = [
      ""
      "${lib.getExe config.virtualisation.podman.package} auto-update --rollback"
    ];
  };
}
