{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    baseNameOf
    dirOf
    getExe'
    mkOption
    escapeRegex
    escapeShellArg
    concatMapAttrs
    concatMapAttrsStringSep
    ;
  cfg = config.xieve.acls;
in
{
  options.xieve.acls =
    with lib.types;
    mkOption {
      type = attrsWith {
        placeholder = "serviceName";
        elemType = attrsWith {
          placeholder = "path";
          elemType = commas;
        };
      };
      description = "ACLs to set on <path> after <serviceName> is running.";
      default = { };
    };

  config.systemd.services = concatMapAttrs (serviceName: acls: {
    "${serviceName}-perms" =
      let
        unitName = "${serviceName}.service";
      in
      {
        wantedBy = [ unitName ];
        bindsTo = [ unitName ];
        after = [ unitName ];
        script = ''
          set -x
          i=1
          pids=()

          ${concatMapAttrsStringSep "\n" (path: acl: ''
            (
              if [ ! -e '${path}' ]; then
                ${getExe' pkgs.inotify-tools "inotifywait"} \
                  -e create \
                  --include '/${escapeRegex (baseNameOf path)}$' \
                  '${dirOf path}'
              fi

              ${getExe' pkgs.acl "setfacl"} --modify ${acl} '${path}' || true
            ) &
            pids[$i]=$!
            ((i++))
          '') acls}

          for pid in ''${pids[*]}; do
            wait $pid
          done
        '';
      };
  }

  ) cfg;
}
