{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  allNetns = config.networking.netns;
  nonDefaultNetns = filterAttrs (name: _cfg: name != "init") allNetns;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            mntnsPath = mkOption {
              type = types.str;
              default = if name == "init" then "/proc/1/ns/mnt" else "/run/${name}/mntns/${name}";
              readOnly = true;
              description = ''
                Path to the auxiliary mount namespace.
              '';
            };
            bindMounts = mkOption {
              type = types.attrsOf (
                types.submodule (
                  { name, ... }:
                  {
                    options = {
                      mountPoint = mkOption {
                        type = types.str;
                        default = name;
                        description = ''
                          Mount point on the auxiliary mount namespace.
                        '';
                      };
                      hostPath = mkOption {
                        type = types.str;
                        description = ''
                          Location of the path to be mounted in the init mount namespace.
                        '';
                      };
                      isReadOnly = mkOption {
                        type = types.bool;
                        default = true;
                        description = ''
                          Determine whether the mounted path will be accessed in read-only mode.
                        '';
                      };
                    };
                  }
                )
              );
              default = { };
              description = ''
                A extra list of bind mounts that is bound to the network namespace.
              '';
            };
            serviceConfig = mkOption {
              type = types.attrs;
              default =
                if name == "init" then
                  { }
                else
                  let
                    rwBinds = filter (d: d.isReadOnly == false) (attrValues config.bindMounts);
                    roBinds = filter (d: d.isReadOnly == true) (attrValues config.bindMounts);
                  in
                  {
                    NetworkNamespacePath = config.netnsPath;
                    BindPaths = map (d: "${d.hostPath}:${d.mountPoint}:norbind") rwBinds;
                    BindReadOnlyPaths = map (d: "${d.hostPath}:${d.mountPoint}:norbind") roBinds;
                  };
              readOnly = true;
              description = ''
                Systemd service configuration for entering the network namespace.
              '';
            };
          };
        }
      )
    );
  };

  config = {
    systemd.services = mapAttrs' (
      name: cfg:
      let
        inherit (cfg) mntnsPath bindMounts;
      in
      nameValuePair "netns-${name}-mntns" {
        enable = false;
        path = with pkgs; [
          coreutils
          util-linux
          bash
        ];
        script = ''
          [ ! -e "${mntnsPath}" ] && touch ${mntnsPath}
          unshare --mount=${mntnsPath} --propagation slave true
          nsenter --mount=${mntnsPath} bash ${pkgs.writeShellScript "netns-${name}-mntns-bind-mount" ''
            declare -A bind_mounts=(
              ${concatMapStringsSep "\n" (d: ''
                ["${d.mountPoint}"]="${d.hostPath}:${if d.isReadOnly then "ro" else "rw"}"
              '') (attrValues bindMounts)}
            )

            for mount_point in "''${!bind_mounts[@]}"; do
              IFS=':' read -r host_path mount_option <<< "''${bind_mounts[$mount_point]}"

              if [ -f "$host_path" ]; then
                [ ! -e "$mount_point" ] && touch "$mount_point"
              elif [ -d "$host_path" ]; then
                [ ! -e "$mount_point" ] && mkdir -p "$mount_point"
              else
                echo "Error: $host_path is neither a file nor a directory"
                continue
              fi

              if [ "$mount_option" = "ro" ]; then
                mount --bind --read-only "$host_path" "$mount_point"
              else
                mount --bind "$host_path" "$mount_point"
              fi
            done
          ''}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "${name}/mntns";
        };
        after = [
          "netns-${name}.service"
          "network.target"
        ];
        partOf = [ "netns-${name}.service" ];
        wantedBy = [
          "multi-user.target"
          "netns-${name}.service"
        ];
      }
    ) nonDefaultNetns;
  };
}
