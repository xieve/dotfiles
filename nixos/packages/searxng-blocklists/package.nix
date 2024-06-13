{ lib, python3Packages }:

with python3Packages;
buildPythonPackage {
	pname = "searxng-blocklists";
	version = "0.0.1";
	pyproject = true;
	nativeBuildInputs = [ setuptools ];

	src = ./.;
}
