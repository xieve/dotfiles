{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib) genAttrs;
  tlsPath = "/var/lib/acme/auth.hackmz.de";
  domain = "auth.hackmz.de";
  origin = "https://${domain}";
  cfg = config.services.kanidm;
in
{
  services.kanidm = {
    package = pkgs.kanidm_1_9;
    enableServer = true;
    enableClient = true;
    # enablePam = true;
    serverSettings = {
      inherit domain origin;
      ldapbindaddress = "[::1]:636";
      tls_key = "${tlsPath}/key.pem";
      tls_chain = "${tlsPath}/fullchain.pem";
      trust_x_forward_for = true;
    };
    clientSettings.uri = origin;
    # unixSettings.kanidm.pam_allowed_login_groups = [ "users" ];
  };

  # Set ACLs so Kanidm can read the TLS files
  systemd.tmpfiles.settings."50-kanidm-tls".${tlsPath}."A+".argument = "u:kanidm:r-X";

  xieve.nginx.virtualHosts.${domain} = {
    proxyPass = "https://${cfg.serverSettings.bindaddress}";
    localOnly = true;
    useWildcardSSL = false;
  };
}
