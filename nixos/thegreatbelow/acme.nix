{ pkgs, ... }:
let
  NAMESILO_API_KEY_ENCRYPTED = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAUPEwv11kLm/E8SWMAAAAAIWhkd88EDZpKARcMIvAvk8IgAAXFJHRyHzYsu0XRmP9O+gsLd89bgsALZLHQHHA1fdtvbBGucsKPVNWy6tQRMQT2OfCWcBULD7EWrp8dGD8dSBup6g==
  '';
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@xieve.net";
    certs."xieve.net" = {
      domain = "*.xieve.net";
      dnsProvider = "namesilo";
      dnsResolver = "ns1.dnsowl.com:53";
      group = "nginx";
    };
  };

  systemd.services."acme-xieve.net" = {
    environment = {
      NAMESILO_API_KEY_FILE = "%d/NAMESILO_API_KEY_FILE";
      NAMESILO_PROPAGATION_TIMEOUT = "3600"; # Wait for up to 1h (TTL of the challenge)
    };
    serviceConfig = {
      SetCredentialEncrypted = [
        "NAMESILO_API_KEY_FILE:${NAMESILO_API_KEY_ENCRYPTED}"
      ];
    };
  };
}
