{
  lib,
  config,
  ...
}:
let
  inherit (lib) genAttrs head splitString;
  cfg = config.services.pocket-id;
  credNames = map (cred: head (splitString ":" cred)) creds;
  domain = "auth.n50.lat";
  creds = [
    ''
      ENCRYPTION_KEY_FILE: \
        Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACFFoZcnmS3cU6GR0gAAAAAol1OU \
        j6bTzv2pZgI78Mw4b9osGTt0HwIxHy+0FqSjbnqhMJV5ugpkjqrxZ4MKHfUvT4ZrnlbqB \
        A1A6ZhbMKBOXt0tflgP3I2VVedo64u/u0pxVfxuUE+v/SXQ27GXywuvaW5YlXQQ+O7qam \
        ZYR5/sSZjJ2c=
    ''
  ];
in
{
  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://${domain}";
      UNIX_SOCKET = "/run/pocket-id/sock";
      UNIX_SOCKET_MODE = "0600";
    }
    // genAttrs credNames (cred: "/run/credentials/pocket-id.service/${cred}");
  };

  xieve.acls.pocket-id.${cfg.settings.UNIX_SOCKET} = "u:nginx:rw";

  xieve.nginx.virtualHosts.${domain} = {
    proxyPass = "http://unix:${cfg.settings.UNIX_SOCKET}";
    # proxyWebsockets = true;
    useWildcardSSL = false;
  };

  systemd.services.pocket-id.serviceConfig = {
    SetCredentialEncrypted = creds;
    RuntimeDirectory = "pocket-id";
  };
}
