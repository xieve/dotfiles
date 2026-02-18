{
  lib,
  pkgs,
  config,
  autheliaSecret,
  ...
}:

let
  OAUTH_CLIENT_ID = "u0NKNTpQr0G6g1sIGsewPJYUkvqbMI21bILsMHAnQUH2~~nfwbeEK4uC-qabphQw";
  PORT = "29756";
in
{
  services.karakeep = {
    enable = true;
    extraEnvironment = {
      inherit OAUTH_CLIENT_ID PORT;
      DISABLE_SIGNUPS = "true";
      DISABLE_PASSWORD_AUTH = "true";
      DISABLE_NEW_RELEASE_CHECK = "true";
      NEXTAUTH_URL = "https://karakeep.xieve.net";
      DB_WAL_MODE = "true";
      OAUTH_WELLKNOWN_URL = "https://auth.xieve.net/.well-known/openid-configuration";
      OAUTH_PROVIDER_NAME = "Authelia";
      OAUTH_AUTO_REDIRECT = "true";
    };
  };

  systemd.services.karakeep-web.serviceConfig = {
    SetCredentialEncrypted = [
      ''
        OAUTH_CLIENT_SECRET: \
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACgPs1BHHeSP4t27Y4AAAAAKIsZu \
          nb12laldok2kTTEh/apGbMnx2LHMh87DVqRb79Awt9vlXg4mxQ49cZST/s+bkcLnTj6uR \
          /Bty3PJjqcNgmBhVyklymd2qtnBvS3ZcOc327MkWzXpxuGC0lwnp/iReAVKJxgjy5Yc31 \
          J3vZJaAP7IoK1+k+Ehr+y8JUD3sU=
      ''
    ];
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "karakeep-web-start.sh" ''
        export OAUTH_CLIENT_SECRET=$(cat "$CREDENTIALS_DIRECTORY/OAUTH_CLIENT_SECRET")
        ${config.services.karakeep.package}/lib/karakeep/start-web
      ''
    );
  };

  xieve.nginx.virtualHosts."karakeep.xieve.net" = {
    localOnly = true;
    proxyPass = "http://localhost:${PORT}";
  };

  services.authelia.instances.main.settings.identity_providers.oidc = {
    claims_policies.karakeep.id_token = [ "email" ];
    clients = [
      {
        client_id = OAUTH_CLIENT_ID;
        client_name = "Karakeep";
        client_secret = autheliaSecret "karakeepClientSecret";
        redirect_uris = [ "https://karakeep.xieve.net/api/auth/callback/custom" ];
        scopes = [
          "openid"
          "profile"
          "email"
        ];
        token_endpoint_auth_method = "client_secret_basic";
        claims_policy = "karakeep";
        authorization_policy = "one_factor";
      }
    ];
  };

  thegreatbelow.authelia.secrets.karakeepClientSecret = ''
    Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAD8BHjwD/Jlkyph2tQAAAAAHI+KW \
    pt4lu2dzHW/Btf5b/eGB63f3Bh2ajUMfWMBylRUIRUH+227uuGY1T5nx3NbWXo8nadNTB \
    bvq5+brEZBhaIdqntows/5C6cYCclrmok/RY601mFNtFhpJv8b/kFGRZsOs0bc2mKv57V \
    xd9lUakkfv7MxtJOuEinlOTATRP5IAeZdFlgOgSDb82G8U7vFYg8v2QupeJwrsnRYFAiI \
    VBiHgeITks/hGwnhOWHL5O+svgaAOZfvHP0bLw==
  '';
}
