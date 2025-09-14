{ ... }:
let
  mollyVapidKey = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACNv7WTW4a0cPygaGoAAAAADGz3/THGpgLKcbOUVLx+UDnEKCFsyLOrkgild0v+TlP74OEWt8Vn+GSH4PH/0BLaNHLDfCLo5V0F+R+7wEUMQskvxgUO2+x8/twxQIpB0S+QQKgUz14K5EqlhkoXiKtphex/
  '';
  mollyUUID = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABlna5G1UZSY3Q/RXEAAAAAt5/qCR/YGVGPm2Zhjm347qraMBnjUoY5oBBWo1MeCgwTxAO9o9DAXHkDKQ5bOKKYj/+Vl3i95NEeHUMvFBivtCIwTrorQ0rlp1COG0z5kFiQjjS4nopqqeVWZ08=
  '';
in
{
  services.mollysocket = {
    enable = true;
    settings = {
      port = 39523;
      allowed_endpoints = [ "https://ntfy.adminforge.de" ];
    };
  };

  systemd.services.mollysocket = {
    preStart = ''
      echo "MOLLY_ALLOWED_UUIDS=[\"$(cat "$CREDENTIALS_DIRECTORY/mollyUUID.txt")\"]" > uuid.env
    '';
    serviceConfig = {
      SetCredentialEncrypted = [
        "mollyVapidKey.txt:${mollyVapidKey}"
        "mollyUUID.txt:${mollyUUID}"
      ];
      EnvironmentFile = ["-%S/mollysocket/uuid.env"];
    };
    environment.MOLLY_VAPID_KEY_FILE = "%d/mollyVapidKey.txt";
  };
}
