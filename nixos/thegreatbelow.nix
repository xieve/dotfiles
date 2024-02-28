{ config, pkgs, nzbr, ... }:

{
	imports = [
		./thegreatbelow-hardware.nix
		./common.nix
	];

	networking.hostName = "thegreatbelow";


	# Network
	networking.useDHCP = false;  # Disable dhcpcd because we'll use networkd

	systemd.network = {
		enable = true;

		networks."10-lan" = {
			# Interface
			matchConfig.Name = "enp*s*";

			address = [ "192.168.0.2/24" ];
			routes = [ { routeConfig.Gateway = "192.168.0.1"; } ];

			# Accept router advertisements, but set a static suffix
			# (global scope IPv6 address will always end in tactical cabbage)
			networkConfig.IPv6AcceptRA = true;
			ipv6AcceptRAConfig = {
				Token = "::7ac7:1ca1:cab:ba9e";
				# if we don't set this, we'll get an extra IPv6 global address
				DHCPv6Client = false;
			};

			linkConfig.RequiredForOnline = "routable";
		};
	};


	# temp fix for perms as long as this is a VM
	users.users.unraidnobody = {
		uid = 99;
		group = "users";
	};


	# misc services
	services.qemuGuest.enable = true;
	services.openssh.enable = true;
	programs.mosh.enable = true;


	# urbackup
	boot.supportedFilesystems = [ "ntfs" ];  # for mounting backups
	nzbr.service.urbackup = {
		enable = true;
		backupfolder = "/mnt/user/urbackup/";
		config = {
			LOGFILE = "/mnt/user/appdata/binhex-urbackup/urbackup/log/urbackup.log";
			LOGLEVEL = "debug";
			USER = "unraidnobody";
		};
		package = nzbr.packages.x86_64-linux.urbackup2-server;
		dataset.images = "";
		dataset.files = "";
	};
	fileSystems."/var/urbackup" = {
		device = "/mnt/user/appdata/binhex-urbackup/urbackup";
		fsType = "none";
		options = [ "bind" ];
	};


	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.11"; # Did you read the comment?
}
