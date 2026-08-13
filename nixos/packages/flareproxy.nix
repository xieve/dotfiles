{ python3Packages, inputs }:

python3Packages.buildPythonApplication {
  src = inputs.flareproxy;
  patchPhase = ''
    sed -i \
      -e 's/^if __name__ == "__main__":$/def main():/' \
      -e 's/^    server_address = ("", 8080)$/    server_address = (os.getenv("FLAREPROXY_HOST", "127.0.0.1"), int(os.getenv("FLAREPROXY_PORT", 8080)))/' \
      -e 's/^    print("FlareProxy adapter running on port 8080")$/    print(f"FlareProxy adapter running at {server_address[0]}:{server_address[1]}")/' \
      flareproxy.py

    echo '[build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "flareproxy"
    version = "1.0.0"
    dynamic = ["dependencies"]

    [tool.setuptools.dynamic]
    dependencies = {file = "requirements.txt"}

    [project.scripts]
    flareproxy = "flareproxy:main"' > pyproject.toml
  '';
  pyproject = true;
  build-system = with python3Packages; [ setuptools ];
  pname = "flareproxy";
  version = "1.0.0";
  dependencies = with python3Packages; [ requests ];
  meta.mainProgram = "flareproxy";
}
