{ config, pkgs, ... }:

{
  services.netdata = {
    enable = true;
    package = pkgs.netdataCloud;
    config = {
      web = {
        "default port" = 19999;
      };
    };
    python.recommendedPythonPackages = true;
  };

  xieve.nginx.virtualHosts."netdata.xieve.net" = {
    auth = true;
    proxyPass = "http://127.0.0.1:${toString config.services.netdata.config.web."default port"}";
  };
}
