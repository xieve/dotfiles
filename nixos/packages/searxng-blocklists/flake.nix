{
	description = "killmekillmekillme";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
		let
			pkgs = nixpkgs.legacyPackages.${system};
		in rec {
			packages.default = pkgs.callPackage ./package.nix {};

			devShell = pkgs.mkShell {
				packages = [ 
					(pkgs.python3.withPackages (pypkgs: [
						packages.default
					]))
				];
			};
		}
	);
}
