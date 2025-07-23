{
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) genAttrs;
  tlsPath = "/var/lib/acme/xieve.net";
  origin = "https://auth.xieve.net";
in
{
  services.kanidm = {
    package = pkgs.kanidm_1_6;
    enableServer = true;
    enableClient = true;
    enablePam = true;
    serverSettings = {
      inherit origin;
      domain = "auth.xieve.net";
      ldapbindaddress = "[::1]:636";
      tls_key = "${tlsPath}/key.pem";
      tls_chain = "${tlsPath}/fullchain.pem";
      trust_x_forward_for = true;
    };
    clientSettings.uri = origin;
    unixSettings.pam_allowed_login_groups = [ "users" ];
  };

  # Set ACLs so Kanidm can read the TLS files
  systemd.tmpfiles.settings."50-kanidm-tls".${tlsPath}."A+".argument = "u:kanidm:r-X";
}
