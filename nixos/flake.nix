{
	description = "xieve's nixos flake";

	inputs = {
		nixpkgs = {
			url = "github:NixOS/nixpkgs/nixos-unstable";
		};
		nzbr = {
			url = "github:nzbr/nixos";
		};
		nixos-wsl = {
			url = "github:nix-community/NixOS-WSL";
		};
	};

	outputs = { self, nixos-wsl, nixpkgs, nzbr }@attrs: {
		nixosConfigurations = {
			despacito3 = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./despacito3/configuration.nix
				];
			};
			thegreatbelow = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = attrs; # Pass inputs to modules
				modules = [
					nzbr.nixosModules."service/urbackup.nix"
					./thegreatbelow/configuration.nix
				];
			};
			theeaterofdreams = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					nixos-wsl.nixosModules.wsl
					./theeaterofdreams/configuration.nix
				];
			};
		};
	};
}

