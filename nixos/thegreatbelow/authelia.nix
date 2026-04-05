{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs mapAttrsToList const;
  cfg = config.thegreatbelow.authelia;
  serviceCfg = config.services.authelia.instances.main;
  base_dn = config.services.lldap.settings.ldap_base_dn;
  /*
    load secret from file, escape and quote it. uses the go templating system. not pretty
      print: concatenate
      secret: load file, remove tailing newlines
      replace newlines with two newlines: yaml syntax >w< (this whole thing will
        end up in a single-quoted string thanks to nix, in which a blank line counts
        as one newline in yaml. idk)
  */
  secret =
    filename:
    ''{{ print (mustEnv "CREDENTIALS_DIRECTORY") "/${filename}" | secret | replace "\n" "\n\n" }}'';
in
{
  options.thegreatbelow.authelia =
    with lib.types;
    let
      inherit (lib) mkOption;
    in
    {
      socket = mkOption {
        type = str;
        default = "/run/authelia-main/authelia.sock";
      };

      secrets = mkOption {
        type = attrsOf str;
        default = [ ];
      };

      envSecrets = mkOption {
        type = attrsOf str;
        default = [ ];
      };
    };
  config = {
    # Provide this function to other modules so they can configure authelia
    _module.args.autheliaSecret = secret;

    services.authelia.instances.main = {
      enable = true;
      secrets.manual = true;

      settings = {
        storage.local.path = "/var/lib/authelia-main/db.sqlite3";
        authentication_backend.ldap = {
          inherit base_dn;
          address = "ldap://[::1]:${toString config.services.lldap.settings.ldap_port}";
          implementation = "lldap";
          user = "UID=authelia,OU=people,${base_dn}";
        };

        identity_providers.oidc = {
          jwks = map (filename: { key = secret filename; }) [
            "jwks.rsa.2048.key"
            "jwks.ecdsa.256.key"
          ];
        };

        session = {
          redis.host = config.services.redis.servers.authelia.unixSocket;
          cookies = [
            {
              domain = "xieve.net";
              authelia_url = "https://auth.xieve.net";
              inactivity = "3M";
              remember_me = "2y";
            }
          ];
        };

        notifier.filesystem.filename = "/var/log/authelia-main/notifications.txt";

        definitions.network.internal = [
          "192.168.0.0/24"
          "fd00::/32"
        ];

        access_control.rules = [
          {
            domain = "jellyfin.xieve.net";
            networks = [
              "internal"
            ];
            policy = "bypass";
          }
          {
            domain = "*.xieve.net";
            policy = "one_factor";
          }
        ];

        server = {
          address = "unix://${cfg.socket}?umask=0077";
          endpoints.authz.auth-request.implementation = "AuthRequest";
        };
      };
    };

    systemd.services.authelia-main.serviceConfig = {
      LogsDirectory = "authelia-main";
      RuntimeDirectory = "authelia-main";
    };
    xieve.acls.authelia-main.${cfg.socket} = "u:nginx:rw";

    # Redis
    services.redis.servers.authelia = {
      enable = true;
      user = serviceCfg.user;
      port = 0;
    };

    # Secrets
    systemd.services.authelia-main = {
      environment = {
        X_AUTHELIA_CONFIG_FILTERS = "template";
      }
      // (mapAttrs (name: const "%d/${name}") cfg.envSecrets);
      serviceConfig.SetCredentialEncrypted = mapAttrsToList (name: value: "${name}:${value}") (
        cfg.envSecrets // cfg.secrets
      );
    };

    thegreatbelow.authelia = {
      envSecrets = {
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADVLeehJGuG5S0oS8gAAAAAF11tW \
          EkvMagRC/dpv2Uh7qVUW+lcmTKoWoMlLNavuFWexk2fS6PDBX5v+nIem/AszXuIV5zveU \
          Xd5au5iaxpT37O4eknXg866UpvGSa0UBWeioGfrKqrvaq9z5OMREoLVzQO2pQAe3ALm7d \
          R+8MJgO89A+pBtt4ILudnIMkyh2/Cd+xmpUdyU9B1j7RTkGlxEBhNWJNI6HllH9DT80fy \
          ByTmNU2Wd4r2bfYBIQT2KFiJ+NISIa2IUKFRH/8MGNfG+PnjRQVPYUiW2UKsEX0kI/e/3 \
          mKyEpaTWSMt1CFszn7fTxmvN5RKlPM3/ACksTvrNdVW8VqOqfye7D8Vcg8DPFt1DRLNrj \
          MoCSEmWA+teZXzGs2vM1NUmI4sMiSBwgFRj7szdv+BFwiXtJPsjOzF7eo5TnjOH0CjTSN \
          0W13TrlZe+QSHs3zxcSn2s5KvUDFv2ISNJGzDcdI=
        '';
        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAFChX7SS8XQE/u/x4AAAAAURJGP \
          3A7nO5wF41iYbDFJdwIY4shY4unItD60trVf+05M5u+N+k2y3dm994qui1qoirV6HsrYX \
          CNHIo7GHYWxf1eDiqo7f+/Q9/FxKbKcAJKRZ2IGPrJTeKXtzyhVlgUKS5Osv6T8OE7hCj \
          MF+z/ya5k8cj274a8m1L5VROT2+uWjIw1S5NWMQnTobadck73lsYyYiSs/IOBWI2CkY99 \
          cyrC9kjtj3ofjOylimN/9bVT/zNavPANJ4YGELJIIFyScBMExZqfBmS9Pc8vJ60HMjkQ6 \
          8D2mopouB+4P+SsCKk03QpIKSKw0+kguPxh0EhshwuRh7aFjDAbho1VtwWm0gSnXPPFaL \
          ttSk0z6THgB2efGAJioMP/amzCWShOnfRKKbDbyIWP/7iClElD/Bkd46/HbPVjNk4gGlT \
          3uP5cTd4PvVV/tuNoZTbVMtGdBK8O1ZQGhRUBEFywI8MF5/Bv9w==
        '';
        AUTHELIA_SESSION_SECRET_FILE = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABuwja5/xpKmOpsrigAAAAAe++1Q \
          xaXUzEKV+/sn0qRzpUm2dZCCRTtJpxM9b5BTxgJi0kVjL46E3X+RQLPOAp0okahPe4zAC \
          tR8M2CEDNb0iJnJmlCpI3AWZ6qZaWy1QmQCImrNMp2ri2/haQiphaTxuXwUa+FI0c/dXE \
          qv4cXsUQG0xwRj2X8Tiu9D2KTsYLsGsJ6Xwj1fV3cshcqN/UEPljYWHpdalxRqZeM2GzE \
          +HD0f9oXCR8PsdGATx/BoKf2uuyzsP32TdKzXXwkw5GnI0VTyXF4MBDZjpli/aP1LZRfV \
          qFz+/0KOHHaHR7dE1e6Dqr6ls/dp6batKkstTYRBHnVTnsr+uUrdhnNpcmi+byAObYNY+ \
          fYeYwYf9OOq46UXCYddI7T6kYv5Yffx6IBP6fRuLwHVo5oa3v5EqSzZMLTv6q1fdX5bOy \
          qunSdzEk=
        '';
        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAbpgr3zGl8RWQfi2kAAAAAo+Kl0 \
          qmJmvUaBa2iu2XqnfkOEuJc3ERuL+CjWsDfZM4w2sNe1CnR3eAVB3CU+voN1cxHozTLYS \
          TWfRaW3ZZ8IJh7A5U6tS7i/cFGefuvA9k8VZXiiV8Aj83LedVe6OQkN2M/YQInon+5UGE \
          lJykIb7Dsv85/vX8xyL7y8zGK5OQEHY8/qqikC+rWVOoqCOR+tQKW9AS+8Hb6MLV4hErq \
          1WCaVkEWBDrLTjnOkAujW51zPDwHCnI39F9dPmk3b7b3ITNvskqESU/zHopVu9ULrFHTv \
          Dlx57y66+4fMTrrWHF+O1bLnx+H1a3SwfM5BhVp+Y+WkAv0+NoZfPQyHCAvu6KHIhaMA0 \
          nqpahp4pkEZdtNg62OmQv7/mkNsKlaf9iN7QuySrEXYHEISP8ItW1DvjCBauWLqtHn3m4 \
          toQwAAcFw5hEoPwKxwQ==
        '';
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAur9FW8G2QMSuvRw0AAAAAMfAkD \
          vV9jYJ8uSj9nJaccIxIbMrPrmo+zCNGWHM2o6XzHBKu24vb/gXJ6yxA3jiLsnKxqsZY0L \
          WmBLtLhInf2/hL5iKDjUDVYOhgKtiQxEC6csWpiL3waEeYtpQwgBHzcydcaAnGGUSA6V1 \
          eW+4kw1xxqguId4ediOOkZ9MY5BsWmIiWTcsyaXFeuqFM7SYEay+6EhlkYxw=
        '';
      };
      secrets = {
        "jwks.rsa.2048.key" = ''
          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
        '';
        "jwks.ecdsa.256.key" = ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABy7iM6fqu/9Ol0XOMAAAAACJYkz \
          b1e+Ks9AQLlp9VzrVi14uazTB+cNqEopYiBnUCGC1ca5PPbqNmUW0rI2ufnaT3eadlsBV \
          6GKa+se7QC8Du988RxW0Juj+i0g/WuwEtia1rD/A5f1kcW6HneYmMKSOvUdAJFk93y9zR \
          Uz91VN1zKh5EUTbLxqRlAkBlJP/zfnuWK7nndLk+Jvmrc1nnrolEwNGsN2FY+eWos5A9q \
          tZo45pcGe2k5FAfZHurwyxs2t1wsmPqL8I70ySgXQMO2E286rcGTc8P5XEL9kuFl25qMV \
          A28ux67DZYmeMtMdI0kwk2S1IWMEGI5lodBCouGlO5TDRRw09RJl9/xAiBfTIqpa0cT1J \
          pz2E25pbtVTbZFzqY3s3W5Sux5waAmMD9+nqKn0/9JjjnA
        '';
      };
    };
  };
}
