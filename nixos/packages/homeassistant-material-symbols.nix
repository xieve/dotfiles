{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  inputs,
}:
let
  src = inputs.home-assistant-material-symbols;
  domain = "material_symbols";
in
buildHomeAssistantComponent {
  inherit domain src;
  version = (lib.importJSON "${src}/custom_components/${domain}/manifest.json").version;
  owner = "beecho01";
}
