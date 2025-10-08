{
  lib,
  stdenvNoCC,
  inputs,
}:

stdenvNoCC.mkDerivation {
  pname = "scheduler-card";
  version = "4.0.6";

  src = inputs.home-assistant-card-scheduler;

  installPhase = ''
    cp -rv dist $out
  '';
}
