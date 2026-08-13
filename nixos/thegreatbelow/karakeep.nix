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
  secrets = {
    OPENAI_BASE_URL = ''
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAnQlLJnUuuowigOa4AAAAAnFBCd \
      +WuDKmEv9YqQYoZVj4ev1y3/dhPI8Eog/imP25tPhWv1kI4mxRWGNNRb6cgIf4pKynLF1 \
      2Hma5m/5fxWDgvIvYsRhKfsom+IatXaazeHf3+7bjtQw==
    '';
    OPENAI_API_KEY = ''
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACUBeRg8infIG1GKfUAAAAAE7FZk \
      rbnpwssGivGSCyZBQ2rCYQQBxxYtBNRwE3v5KPhUhOAm2jItU/pvbBzHW+MWN7fRUiCFk \
      i9Vn5oELx52jFwJCvObqCmPA+VOUdRvnIowpJrtuf+72SeiA==
    '';
  };
  webSecrets = secrets // {
    OAUTH_CLIENT_SECRET = ''
      Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACgPs1BHHeSP4t27Y4AAAAAKIsZu \
      nb12laldok2kTTEh/apGbMnx2LHMh87DVqRb79Awt9vlXg4mxQ49cZST/s+bkcLnTj6uR \
      /Bty3PJjqcNgmBhVyklymd2qtnBvS3ZcOc327MkWzXpxuGC0lwnp/iReAVKJxgjy5Yc31 \
      J3vZJaAP7IoK1+k+Ehr+y8JUD3sU=
    '';
  };
  genCreds = lib.mapAttrsToList (name: value: "${name}:${value}");
  secretLoader = lib.concatMapAttrsStringSep "\n" (
    name: _: ''export ${name}="$(cat "$CREDENTIALS_DIRECTORY"/${name})"''
  );
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
      INFERENCE_TEXT_MODEL = "minimax-m3";
      INFERENCE_IMAGE_MODEL = "minimax-m3";
      INFERENCE_ENABLE_AUTO_TAGGING = "true";
      INFERENCE_LANG = "english";
      INFERENCE_CONTEXT_LENGTH = "32768";
      INFERENCE_MAX_OUTPUT_TOKENS = "16384";
      INFERENCE_USE_MAX_COMPLETION_TOKENS = "true";
      EMBEDDING_TEXT_MODEL = "bge-m3";
      EMBEDDING_DIMENSIONS = "1024";
      # max context is 8192 tokens, this is the amount of chars after which content will be truncated
      EMBEDDING_CONTEXT_LENGTH = "32000";
      EMBEDDING_ENABLE_AUTO_INDEXING = "true";
      SEMANTIC_SEARCH_ENABLED = "true";
      # OPENAI_BASE_URL = "http://192.168.0.29:8080/api";
    };
    package = pkgs.karakeep.overrideAttrs (
      final: prev: {
        patches = prev.patches ++ [
          (pkgs.writeText "karakeep-prompt.patch" ''
            --- a/packages/shared/prompts.ts
            +++ b/packages/shared/prompts.ts
            @@ -60,13 +60,10 @@
               return `
             You are an expert whose responsibility is to help with automatic tagging for a read-it-later/bookmarking app.
             Analyze the TEXT_CONTENT below and suggest relevant tags that describe its key themes, topics, and main ideas. The rules are:
            -- Aim for a variety of tags, including broad categories, specific keywords, and potential sub-genres.
             - The tags must be in ''${lang}.
            -- If the tag is not generic enough, don't include it.
             - Do NOT generate tags related to:
                 - An error page (404, 403, blocked, not found, dns errors)
                 - Boilerplate content (cookie consent, login walls, GDPR notices)
            -- Aim for 3-5 tags.
             - If there are no good tags, leave the array empty.
             ''${curatedInstruction}
             ''${potentialRelevantTagsInstruction}
          '')
        ];
      }
    );
  };

  systemd.services = {
    karakeep-web.serviceConfig = {
      SetCredentialEncrypted = genCreds webSecrets;
      ExecStart = lib.mkForce (
        pkgs.writeShellScript "karakeep-web-start.sh" ''
          ${secretLoader webSecrets}
          ${config.services.karakeep.package}/lib/karakeep/start-web
        ''
      );
    };
    karakeep-workers.serviceConfig = {
      SetCredentialEncrypted = genCreds secrets;
      ExecStart = lib.mkForce (
        pkgs.writeShellScript "karakeep-workers-start.sh" ''
          ${secretLoader secrets}
          ${config.services.karakeep.package}/lib/karakeep/start-workers
        ''
      );
    };
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
