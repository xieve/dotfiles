{ lib, ... }:
let
  inherit (lib) basename;
  socket = "/run/kopia/kopia.sock";
in
{
  services.kopia = {
    enable = true;
    server = {
      enable = true;
      args = {
        address = "unix:${socket}";
        server-username = "xieve";
        htpasswd-file = "%d/kopia.htpasswd";
      };
    };
    #directories = [ "/home/xieve" ];
    settings = {
      storage = {
        type = "filesystem";
        config.path = "/mnt/frail/kopia";
      };
    };
    # TODO: make these reproducible
    settingsFile = "/etc/kopia/secrets.json";
  };

  xieve.nginx = {
    commonHttpConfig = ''
      upstream kopia_sock {
        server unix://${socket};
      }
    '';
    virtualHosts."kopia.xieve.net" = {
      extraConfig = ''
        # Allow unlimited upload size
        client_max_body_size 0;

        location / {
          grpc_pass grpcs://kopia_sock;
        }
      '';
    };
  };

  xieve.acls.kopia-server =
    let
      acl = "u:nginx:rwX";
    in
    {
      ${socket} = acl;
      ${dirOf socket} = acl;
    };

  systemd.services.kopia-server.serviceConfig.SetCredentialEncrypted = [
    ''
      kopia.htpasswd: \
        Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADRhOuGw1kbJpjiC0QAAAAAkWfRI \
        zfOeS1l4zJnLU4MseKOez/htGHqRDR8SioOMX315L68U1elbeV3DA/IKpk0q6Thv4ln5k \
        GHT1uJIYuGCqxHZvMiNql09exF8NFt+KrjsqnpP/FBMLAivCuCKK17xM7g8qQ=
    ''
  ];
}
