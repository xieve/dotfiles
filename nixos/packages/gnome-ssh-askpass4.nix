{
  lib,
  stdenv,
  openssh,
  pkg-config,
  gcr_4,
  glib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openssh-askpass";
  inherit (openssh) src version;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    gcr_4
    glib
  ];

  sourceRoot = "${openssh.pname}-${finalAttrs.version}/contrib";
  makeFlags = "gnome-ssh-askpass4";
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec
    cp -a gnome-ssh-askpass4 $out/libexec/
    runHook postInstall
  '';

  meta = {
    description = "A passphrase dialog for OpenSSH and GTK";
    homepage = "https://www.openssh.org";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ n3tshift ];
  };
})
