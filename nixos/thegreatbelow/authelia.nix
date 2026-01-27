{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.thegreatbelow.authelia;
  serviceCfg = config.services.authelia.instances.main;
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
    };
  config = {
    services.authelia.instances.main = {
      enable = true;
      secrets.manual = true;

      settings =
        let
          base_dn = config.services.lldap.settings.ldap_base_dn;
        in
        {
          storage.local.path = "/var/lib/authelia-main/db.sqlite3";
          authentication_backend.ldap = {
            inherit base_dn;
            address = "ldap://[::1]:${toString config.services.lldap.settings.ldap_port}";
            implementation = "lldap";
            user = "UID=authelia,OU=people,${base_dn}";
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
    systemd.services.authelia-socket-perms = {
      wantedBy = [ "authelia-main.service" ];
      bindsTo = [ "authelia-main.service" ];
      # after = ["authelia-main"];
      script = ''
        set -x
        ${lib.getExe' pkgs.inotify-tools "inotifywait"} \
          -e create \
          --include '/${lib.escapeRegex (baseNameOf cfg.socket)}$' \
          '${dirOf cfg.socket}'

        ${lib.getExe' pkgs.acl "setfacl"} --modify 'u:60:rw' '${cfg.socket}' || true
      '';
    };

    # Redis
    services.redis.servers.authelia = {
      enable = true;
      user = serviceCfg.user;
      port = 0;
    };

    systemd.tmpfiles.settings.authelia = {
      "/run/authelia-main/" = {
        # d = { inherit (serviceCfg) user group; };
        # A.argument = "default:u:nginx:rwX";
      };
    };

    # Secrets
    systemd.services.authelia-main = {
      environment = {
        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "%d/jwtSecret";
        AUTHELIA_SESSION_SECRET_FILE = "%d/sessionSecret";
        AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/encryptionKey";
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldapPassword";
      };
      serviceConfig.SetCredentialEncrypted = [
        ''
          jwtSecret: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAACXj4WcfLPHXXRm0wsAAAAAmNNPP \
            z+fWoNZHZLnwfQfHUvcQ/8zwqHXftT6DVKegh14grBN2NYoFMNe82PT3/6r4Cx9KZYvM5 \
            X/cgSV5PviGwG8Qb3EmzoGyHHMV/Z7MTdR7AvlUAtSL5MWRH+9vhUJaL064+xxd5jk3R4 \
            fDD3atwrrYfKQMPRq3cmU3vqIjCg3RTlBdJHRWZF/jNyyYkKEm2EbsJHMHgPQTTERdbDC \
            gBuiv9m7fPjxSKOMs9wmn/R+he3sn480wOfaAxMtjKI1wF4oQ9mOaXnjToWuNcA0F6smF \
            a556aOiV0Z+Enxp1CcJ8zAddwK9rOcy0BmrW0zv0ORZkb2MMn7DCNHhcOeoAr4ehUklZc \
            vx6y9do5BqcHsO+hY7PpnVnQNX0wjMwPiRGMH8uvvGfDOsExy1GrDjRg==
        ''
        ''
          sessionSecret: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAByoQcQio2ygY//evgAAAAAWJ54i \
            uBeoj8pnN0tCx/gVNALqIx8GVTweDeGeduoG3OWiy8Fhe9eB3/ZULHFFLOQru7rUweQOQ \
            tCmgJsnB4FlP+0GEaWornsRBtbWtqie86opmy0AUmsZzRvYTicoDv8FA1pF77Puuqrbmj \
            D755d8tZ6EGJdop0+a7AdrMBG5NY46Iem2yfjnACs7pxrkPFo19POx0/LvLdB1G99ureN \
            NzQfgQh6VCK4VwwgYE/FLp2Vbu10LppGK3rPPyhKTR0HFqNdwYqvG81YqVXoLVWkXCJ9U \
            R3OAXO/bIR6HUs9RcrF8sV5ztui/mhhAEJA7rAObTOrS0Wk+gkvWXoXqKmfpuIKo1j6Mk \
            jao4ZU4aEZp4/6DrqfGpC7LnPqgDFYXYaQkR4gCxmFCIYejJCjFxRgMQkH9JCteIDR
        ''
        ''
          encryptionKey: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAD32uAGuvC++a1c9xgAAAAAphfs0 \
            1Ipae7+tpsm7TklLrpOiuUzOloAiRz/bVr/SuoGZNxdQXVPoPuY4Fiu/sB6bt9d4KRAFB \
            LrkqY89v4mYwk8KX0zUpdriWmdGvrH+hW7SBAM+AkqMwM2t9Zr/ethyyaV/+0+2FGSBsX \
            63ZkBItoQRfYgnBc3HMMR/ZLi/B7HvgnauAH9qXSlcV2uqQ+8BGcAAeRr1ehF67+Nu6rk \
            rcLxqpUrCJPB9iyIJM+nGF2gahRaSi3kn8CyAXJyG0a9u6+vXQpqXeLXEo49apzlG2xwH \
            Nu/OIm+VTPLAwh/scoNdn4cjptGScQfy6/cT++iksIe+Gfdhs/Is7DJetWRoKcUeniDL+ \
            fXZaSTttZ0Rww0UZCvDTSmUA25gRD1+unDVmjna0nk10Mghzev1KodiqRMx9cbdJ8N
        ''
        ''
          ldapPassword: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADbDe7b1G7NO5y2B+8AAAAAVRfnA \
            Qnp2CwiEo07AW1BkuVy/eFwkCySdEQgdHSZKox7M5w0z3+IvX580VopuGA8Vu242Xc6J7 \
            Rfk+NIhvwkaDw5VOxiVAiBbG5uO2vRFTFpfmCW0IWE0pOXY6vgmDDtJhEWed6cEPl5bhS \
            llrxBig==
        ''
      ];
    };
  };
}
