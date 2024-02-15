{ config, pkgs, ... }:

{
	imports = [
		./thegreatbelow-hardware.nix
		./common.nix
	];

	networking.hostName = "thegreatbelow";
	services.openssh.enable = true;

	# Disable dhcpcd because we'll use networkd
	networking.useDHCP = false;

	systemd.network = {
		enable = true;

		networks."10-enp1s0" = {
			# Interface
			matchConfig.Name = "enp1s0";

			address = [ "192.168.0.2/24" ];
			routes = [ { routeConfig.Gateway = "192.168.0.1"; } ];

			# Accept router advertisements, but set a static suffix
			# (global scope IPv6 address will always end in tactical cabbage)
			networkConfig.IPv6AcceptRA = true;
			ipv6AcceptRAConfig = {
				Token = "::7ac7:1ca1:cab:ba9e";
				# if we don't set this, we'll get another IPv6 address
				DHCPv6Client = false;
			};

			linkConfig.RequiredForOnline = "routable";
		};
	};

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.11"; # Did you read the comment?
}
