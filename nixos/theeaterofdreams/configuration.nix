{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:

{
  imports = [ ../common.nix ];

  wsl = {
    enable = true;
    wslConf = {
      automount.root = "/mnt";
      network.hostname = "theeaterofdreams";
    };
    defaultUser = "xieve";
    startMenuLaunchers = true;
  };

  # run unpatched dynamic binaries on nixos
  # jetbrains remote dev needs this
  programs.nix-ld.enable = true;

  programs.ssh.startAgent = true;

  # doesn't work. eh
  #fileSystems."/home" = {
  #  device = "D:\\";
  #  fsType = "drvfs";
  #  options = [ "metadata" "uid=1000" "gid=100" "noatime" ];
  #};
}
