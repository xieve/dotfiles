{
  lib,
  buildNpmPackage,
  stdenvNoCC,
  git,
  inputs,
}:
let
  src = inputs.home-assistant-lovelace-module-material-you;
  entrypoint = "material-you-utilities.min.js";
in
stdenvNoCC.mkDerivation {
  inherit src;
  pname = "material-you-utilities";
  version = (lib.importJSON "${src}/package.json").version;

  passthru = { inherit entrypoint; };

  installPhase = ''
    mkdir $out
    cp dist/${entrypoint} $out
  '';
}
