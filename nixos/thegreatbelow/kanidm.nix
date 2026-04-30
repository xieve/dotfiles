{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib) genAttrs;
  domain = "auth.n50.lat";
  tlsPath = "/var/lib/acme/${domain}";
  origin = "https://${domain}";
  cfg = config.services.kanidm;
  http_client_address_info = {
    x-forward-for = [ "127.0.0.1" ];
  };
in
{
  services.kanidm = {
    package = pkgs.kanidm_1_9;
    server = {
      enable = true;
      settings = {
        inherit
          domain
          origin
          http_client_address_info
          ;
        # ldapbindaddress = "[::1]:636";
        tls_key = "${tlsPath}/key.pem";
        tls_chain = "${tlsPath}/fullchain.pem";
        online_backup = {
          path = "/mnt/frail/kanidm-backup/";
          # At 22h
          schedule = "00 22 * * *";
          # Keep 30 backups
          versions = 30;
        };
      };
    };
    client = {
      enable = true;
      settings.uri = origin;
    };
    # unixSettings.kanidm.pam_allowed_login_groups = [ "users" ];
  };

  # Set ACLs so Kanidm can read the TLS files
  systemd.tmpfiles.settings."50-kanidm-tls".${tlsPath}."A+".argument = "u:kanidm:r-X";

  xieve.nginx.virtualHosts.${domain} = {
    proxyPass = "https://${cfg.server.settings.bindaddress}";
    useWildcardSSL = false;
  };
}
