{ pkgs, lib, ... }:
let

  cloudflareApiToken = "Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAC5wRywS/O3bElegD0AAAAAcPTCzaSGhJHrgYtHE1tTSbymw3hLLIbcrKNblJioYn/veW07OWiZ3xzLyLF5KhFS4z4bS/M9z13IpKrgXGr4V4hQdKuOeyHeFRFyTRMvoGH0ZTtzhCRRjbRiujV3aShGXrlWeIlmXaI=";
  getIPScript =
    let
      inherit (lib) getExe;
      inherit (pkgs) curl ripgrep;
    in
    pkgs.writeShellScript "fritzbox_get_ip.sh" ''
      ${getExe curl} -s -H 'Content-Type: text/xml; charset="utf-8"' \
        -H 'SOAPAction: urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress' \
        -d '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"> <s:Body> <u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" /></s:Body></s:Envelope>' \
        "http://192.168.0.1:49000/igdupnp/control/WANIPConn1" | \
        ${getExe ripgrep} -o '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
    '';
in
{
  services.ddclient = {
    enable = true;
    protocol = "cloudflare";
    zone = "xieve.net";
    domains = [ "xieve.net" ];
    passwordFile = "\${CREDENTIALS_DIRECTORY}/cloudflare_api_token.txt";
    usev4 = "cmdv4";
    usev6 = "ifv6";
    extraConfig = ''
      ifv6=eno1
      cmdv4=${getIPScript}
    '';
  };
  systemd.services.ddclient = {
    path = with pkgs; [ iproute2 ];
    serviceConfig.SetCredentialEncrypted = [
      "cloudflare_api_token.txt:${cloudflareApiToken}"
    ];
  };
}
