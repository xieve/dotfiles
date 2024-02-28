{
	description = "xieve's nixos flake";

	inputs = {
		nixpkgs = {
			url = "github:NixOS/nixpkgs/nixos-unstable";
		};
		nzbr = {
			url = "github:nzbr/nixos";
		};
	};

	outputs = { self, nixpkgs, nzbr }@attrs: {
		nixosConfigurations = {
			despacito3 = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./despacito3.nix
				];
			};
			thegreatbelow = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = attrs; # Pass inputs to modules
				modules = [
					nzbr.nixosModules."service/urbackup.nix"
					./thegreatbelow.nix
				];
			};
		};
	};
}

