{
  lib,
  authentik-nix,
  config,
  ...
}:
let
  inherit (lib) genAttrs head splitString;
  systemdCfg = config.systemd.services.authentik;
  credNames = map (cred: head (splitString ":" cred)) systemdCfg.serviceConfig.SetCredentialEncrypted;
  domain = "auth.n50.lat";
in
{
  imports = [ authentik-nix.nixosModules.default ];
  services.authentik = {
    enable = true;
    settings = {
      host = "https://${domain}";
      host_browser = "https://${domain}";
      disable_startup_analytics = true;
    };
  };

  xieve.nginx.virtualHosts.${domain} = {
    proxyPass = "http://localhost:9000";
    proxyWebsockets = true;
    useWildcardSSL = false;
  };

  systemd.services =
    genAttrs
      [
        "authentik"
        "authentik-worker"
        "authentik-migrate"
      ]
      (service: {
        environment = genAttrs credNames (cred: "file:///run/credentials/${service}.service/${cred}");
        serviceConfig.SetCredentialEncrypted = [
          ''
            AUTHENTIK_SECRET_KEY: \
              Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABMg/+JXOenIQhz9mYAAAAALrxKm \
              KMyjd9eOwCELtJy7/4u0uixjccNrmXDLjWdpMASEvQvf3fhF+y9LxU1eRNclYKA6Encw+ \
              SkpiLM04uUNOskX546Do0AOwHpBDRhRGbrES6ISD4RMGCdPzboKUhu0na3T3gGnFeodRF \
              dyNOwK4RJoEM=
          ''
        ];
      });
}
