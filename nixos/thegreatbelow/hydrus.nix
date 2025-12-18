{
  config,
  hydrus,
  hydrui,
  lib,
  ...
}:

{
  imports = [
    hydrus.nixosModules.default
    hydrui.nixosModules.hydrui
  ];

  services.hydrus = {
    createUser = true;
    client = {
      enable = true;
      openFirewall = true;
      extraXpraArgs = [ "--socket-permissions=660" ];
    };
  };

  systemd.services.hydrus-client.serviceConfig = {
    ExecStartPre = lib.mkForce null;
    ReadWritePaths = [
      "/mnt/frail/hydrus"
      "/mnt/frail/srv/hidden"
    ];
    Environment = [
      "QT_AUTO_SCREEN_SCALE_FACTOR=0"
      "QT_SCALE_FACTOR=2"
    ];
  };

  services.hydrui = {
    enable = true;
    # serverMode = true;
    # hydrusUrl = "http://localhost:45869";
    # hydrusApiKeyFile = "/run/credentials/hydrui/hydrusApiKey";
    port = 43258;
    openFirewall = true;
  };

  systemd.services.hydrui-server.serviceConfig =
    let
      cfg = config.services.hydrui;
    in
    {
      SetCredentialEncrypted = ''
        hydrusApiKey: \
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAA00hoK1A1BEQNk/mYAAAAAEKBFq \
          X7gkTJOzZLWKFPd8RriqKsR+6/1PATGZrrwSQQBVa3JG1l+3c+bX5Os2eIdUthQwaaqDb \
          A9IFi1r+p9y3dWZragak+sXfQ/v0+xd1qJITapS0pymjdPIevHd6JWDDUUv454nmDtTPd \
          nSgG2zA==
      '';
      ExecStart = lib.mkForce ''
        ${lib.getExe cfg.package} -nogui=true -server-mode=true -acme=false -listen=:43258 -hydrus-url=https://hydrusapi.xieve.net -hydrus-api-key-file=$CREDENTIALS_DIRECTORY/hydrusApiKey -allow-bug-report=true
      '';
    };

  users.users.hydrus = {
    home = "/home/hydrus";
    shell = "/run/current-system/sw/bin/zsh";
  };
}
