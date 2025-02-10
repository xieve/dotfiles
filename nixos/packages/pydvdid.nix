{
  lib,
  inputs,
  python3Packages,
}:

python3Packages.buildPythonPackage {
  pname = "pydvdid";
  version = "1.1";
  src = inputs.pydvdid;
  pyproject = true;
  build-system = with python3Packages; [
    setuptools
  ];
}
