{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
}:
let
  version = "0.25.0";
  owner = "syssi";
in

buildHomeAssistantComponent {
  inherit version owner;
  domain = "goecharger_mqtt";

  src = fetchFromGitHub {
    inherit owner;
    repo = "homeassistant-goecharger-mqtt";
    rev = version;
    hash = "sha256-IMTFzSon9NQn5PKDUivMEqk7Wj0VU1pg1LbE9wbBh6U=";
  };
}
