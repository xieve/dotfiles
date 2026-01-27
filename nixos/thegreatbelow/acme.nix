{ pkgs, ... }:
let
  cloudflareApiToken = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAKg0Ch1zFvimaWH4oAAAAAfunzjRPaA7wdfFV0QDw3V7r4Z5oMDcGiWgTjW1nThbcFcbECsZEtPJNhOmSXq6qLxJOsfmtUcn19laQqA3uD+O6lnd96pfs58TNVlh8Kp2bc3AHuRs21PFFnN0WsSfmU7goUNeTUnIc=
  '';
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@xieve.net";
    certs."xieve.net" = {
      domain = "*.xieve.net";
      dnsProvider = "cloudflare";
      dnsResolver = "arvind.ns.cloudflare.com";
      group = "nginx";
    };
  };

  systemd.services."acme-order-renew-xieve.net" = {
    environment = {
      CF_DNS_API_TOKEN_FILE = "%d/cloudflareApiToken.txt";
    };
    serviceConfig = {
      SetCredentialEncrypted = [
        "cloudflareApiToken.txt:${cloudflareApiToken}"
      ];
    };
  };
}
