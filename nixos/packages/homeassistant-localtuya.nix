{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  inputs,
}:
let
  src = inputs.localtuya;
  domain = "localtuya";
in
buildHomeAssistantComponent {
  inherit domain src;
  version = (lib.importJSON "${src}/custom_components/${domain}/manifest.json").version;
  owner = "rospogrigio";
}
