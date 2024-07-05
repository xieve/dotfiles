{ lib, pkgs, config, modulesPath, ... }:

{
	imports = [
		../common.nix
		./hardware.nix
	];

	networking.hostName = "warmplace";

	hardware = {
		raspberry-pi."4".apply-overlays-dtmerge.enable = true;
		deviceTree.enable = true;
	};

	boot = {
		kernelParams = [ "console=ttyS0,115200n8" ];
		loader = {
			efi.canTouchEfiVariables = false;
			# This is set in the the nixos-hardware RPi4 module, we don't need it
			generic-extlinux-compatible.enable = false;
			# Override common.nix
			systemd-boot.enable = false;
			grub = {
				enable = true;
				efiSupport = true;
				efiInstallAsRemovable = true;
				device = "nodev";
				extraConfig = "
					serial --speed=115200 --unit=0
					terminal_input console serial
					terminal_output gfxterm serial
				";
			};
		};
	};
}
