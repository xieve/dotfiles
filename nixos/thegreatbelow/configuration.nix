{ config, pkgs, nzbr, ... }:

{
	imports = [
		./hardware.nix
		../common.nix
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


	# Firewall
	networking.firewall.allowedTCPPorts = [
		8080  # SearXNG (temp)
	];


	# temp fix for perms as long as this is a VM
	users.users.unraidnobody = {
		uid = 99;
		group = "users";
	};


	# misc services
	services = {
		qemuGuest.enable = true;
		openssh.enable = true;
		searx.enable = true;
	};
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


	# jellyfin
	services.jellyfin = let 
		basePath = "/mnt/user/appdata/binhex-jellyfin";
	in {
		enable = true;
		openFirewall = true;
		cacheDir = "${basePath}/cache";
		configDir = "${basePath}/config";
		dataDir = "${basePath}/data";
		logDir = "${basePath}/logs";
	};
}
