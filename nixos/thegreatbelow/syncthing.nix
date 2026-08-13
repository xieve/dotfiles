{ config, ... }:

let
  cfg = config.services.syncthing;
  guiAddress = "/run/syncthing/sock";
in
{
  services.syncthing = {
    inherit guiAddress;
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    openDefaultPorts = true;
    settings = {
      gui.insecureSkipHostcheck = true;
      defaults.folder.path = cfg.dataDir;
    };
  };

  xieve.nginx.virtualHosts."sync.xieve.net" = {
    auth = true;
    proxyPass = "http://unix:${guiAddress}";
  };

  xieve.acls.syncthing.${guiAddress} = "u:nginx:rw";

  services.authelia.instances.main.settings.access_control.rules = [
    {
      domain = "sync.xieve.net";
      policy = "one_factor";
      subject = "user:xieve";
    }
    {
      domain = "sync.xieve.net";
      policy = "deny";
    }
  ];
}
