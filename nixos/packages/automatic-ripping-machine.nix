{
  lib,
  inputs,
  python3Packages,
  writeText,
  fd,
  perl,
  # local
  pydvdid,
  # runtime deps
  bash,
  curl,
  eject,
  lsdvd,
  makemkv,
  systemd,
  util-linux,
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
    [tool.setuptools.packages.find]
    include = ["arm*"]
    [tool.setuptools.package-data]
    arm = ["**/*"]
  '';
in
python3Packages.buildPythonApplication {
  inherit src version;
  pname = "automatic-ripping-machine";
  pyproject = true;
  build-system = with python3Packages; [ setuptools ];

  preBuild =
    let
      cfgPath = "/etc/arm";
    in
    ''
      # Prepend shebang
      # sed -i '1s;^;#!/usr/bin/env python3\n;' arm/runui.py

      # Only log ripper output to stdout
      # sed -i 's;\(logger.create_logger("ARM", logging.DEBUG\), True, True, True);\1);' arm/ripper/main.py

      # Fix: crash when git is not installed
      # sed -i -ze 's;\( *\)\(git_output =.*\)\n\( *git_regex =.*\)\n\( *git_match =[^\n]*\);\1\2\n\1if git_output:\n    \3\n    \4\n\1else: git_match = None;' arm/ripper/ARMInfo.py

      # Un-hardcode /mnt
      # sed -i 's;\(self.mountpoint = \)"/mnt" + devpath;\1os.environ["RUNTIME_DIRECTORY"] + devpath;' arm/models/job.py

      # Un-hardcode update_key.sh script
      # sed -i 's;\(update_cmd = \)"/bin/bash /opt/arm/scripts/update_key.sh";\1os.path.join(cfg.arm_config["INSTALLPATH"], "scripts/update_key.sh");' arm/ripper/makemkv.py
      # sed -i -z 's;# create .MakeMKV dir.*;makemkvcon reg "$makemkv_serial";' scripts/update_key.sh

      cp ${pyproject} pyproject.toml

      ${lib.concatMapAttrsStringSep ""
        (targetPath: srcPath: ''
          install --no-target-directory -D ${srcPath} $out/${targetPath}
        '')
        {
          "bin/armui" = "arm/runui.py";
          "bin/arm" = "arm/ripper/main.py";
          "${cfgPath}/arm.yaml" = "setup/arm.yaml";
          "opt/arm/setup/arm.yaml" = "setup/arm.yaml";
          "${cfgPath}/abcde.conf" = "setup/.abcde.conf";
          "${cfgPath}/apprise.yaml" = "setup/apprise.yaml";
          "opt/arm/arm/ui/comments.json" = "arm/ui/comments.json";
          "opt/arm/VERSION" = "VERSION";
        }
      }
      cp -r arm/migrations $out/opt/arm/arm

      mkdir -p $out/lib/udev/rules.d
      echo 'ACTION=="change", KERNEL=="s[rg][0-9]*",' \
        'RUN{program}+="${systemd}/bin/systemd-mount --no-block --automount=yes --collect $devnode /run/arm$devnode",' \
        'ENV{SYSTEMD_WANTS}+="arm@$kernel.service"' \
        > $out/lib/udev/rules.d/50-automatic-ripping-machine.rules
    '';

  # Provide runtime dependencies by injecting them into PATH via the python wrapper
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        # These will be provided dynamically by the module depending on the configuration
        # abcde
        # ffmpeg-headless # Only required for ripping posters
        # handbrake
        bash
        curl
        eject
        lsdvd
        makemkv
        util-linux # mount, umount, findmnt
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
