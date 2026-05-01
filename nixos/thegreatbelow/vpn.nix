{ ... }:

{
  # TODO: refactor into separate service so this can fail separately
  systemd.services.systemd-networkd = {
    preStart = ''
      ln -fs "$CREDENTIALS_DIRECTORY/99-wg0.netdev" /run/systemd/network/99-wg0.netdev
      ln -fs "$CREDENTIALS_DIRECTORY/99-wg0.network" /run/systemd/network/99-wg0.network
    '';
    serviceConfig = {
      RuntimeDirectory = "systemd/network";
      LoadCredentialEncrypted = [
        "99-wg0.netdev:${./networkd/99-wg0.netdev}"
        "99-wg0.network:${./networkd/99-wg0.network}"
      ];
    };
  };
}
