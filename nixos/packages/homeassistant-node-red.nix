{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  inputs,
}:
let
  src = inputs.home-assistant-node-red;
  domain = "nodered";
in
buildHomeAssistantComponent {
  inherit domain src;
  version = (lib.importJSON "${src}/custom_components/${domain}/manifest.json").version;
  owner = "zachowj";
}
