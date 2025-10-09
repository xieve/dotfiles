{
  lib,
  buildNpmPackage,
  stdenvNoCC,
  git,
  inputs,
}:
let
  src = inputs.home-assistant-lovelace-google-components;
  entrypoint = "google-components.js";
in
stdenvNoCC.mkDerivation {
  inherit src;
  pname = "lovelace-google-components";
  version = (lib.importJSON "${src}/package.json").version;

  passthru = { inherit entrypoint; };

  installPhase = ''
    mkdir $out
    cp dist/${entrypoint} $out
  '';
}
