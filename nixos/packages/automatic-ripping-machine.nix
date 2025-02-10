{
  lib,
  inputs,
  python3Packages,
  writeText,
  fd,
  # local
  pydvdid,
  # runtime deps
  eject,
  lsdvd,
}:

let
  src = inputs.automatic-ripping-machine;
  version = builtins.replaceStrings [ "\n" ] [ "" ] (lib.readFile "${src}/VERSION");
  pyproject = writeText "pyproject.toml" ''
    [build-system]
    requires = [ "setuptools" ]
    build-backend = "setuptools.build_meta"
    [project]
    name = "automatic-ripping-machine"
    version = "${version}"
    [project.scripts]
    arm-ui = "arm:runui"
    [tool.setuptools.packages.find]
    # Only include directories with an __init__.py
    namespaces = false
  '';
in
python3Packages.buildPythonApplication {
  inherit src version;
  pname = "automatic-ripping-machine";
  pyproject = true;
  build-system = with python3Packages; [ setuptools ];

  preBuild = ''
    cp ${pyproject} pyproject.toml
  '';

  # Provide runtime dependencies by injecting them into PATH via the python wrapper
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        # These will be provided dynamically by the module depending on the configuration
        # abcde
        # ffmpeg-headless # Only required for ripping posters
        # handbrake
        # makemkv
        eject
        lsdvd
      ]
    }"
  ];

  dependencies = with python3Packages; [
    psutil
    # eyed3
    pyudev
    alembic
    apprise
    bcrypt
    # beautifulsoup4
    # certifi
    # cffi
    # click
    # charset-normalizer
    discid
    flask
    flask-cors
    flask-login
    flask-migrate
    flask-sqlalchemy
    flask-wtf
    greenlet
    idna
    itsdangerous
    jinja2
    mako
    markdown
    markupsafe
    musicbrainzngs
    netifaces
    # oauthlib
    prettytable
    psutil
    # pycparser
    # pycurl
    pydvdid
    pyyaml
    pyudev
    requests
    # requests-oauthlib
    # robobrowser
    # six
    # soupsieve
    sqlalchemy
    # tinydownload
    urllib3
    waitress
    # wcwidth
    werkzeug
    wtforms
    xmltodict
  ];
}
