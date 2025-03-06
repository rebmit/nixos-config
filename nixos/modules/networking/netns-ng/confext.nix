{
  options,
  config,
  lib,
  pkgs,
  modulesPath,
  self,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.attrsets)
    attrValues
    recursiveUpdate
    mapAttrsToList
    mapAttrs'
    nameValuePair
    ;
  inherit (lib.strings) concatStringsSep concatMapStringsSep escapeShellArgs;
  inherit (lib.lists) remove filter;
  inherit (lib.meta) getExe;

  inherit (config.system) nssDatabases;
  etc = config.environment.etc;
in
{
  options.networking.netns-ng = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            confext = mkOption {
              inherit (options.environment.etc) type;
              default = { };
              description = ''
                Per-network namespace configuration extensions that will be
                merged on {file}`/etc`.
              '';
            };
          };

          config = mkIf config.enable (
            let
              etc' = filter (f: f.enable) (attrValues (recursiveUpdate etc config.confext));
              etcHardlinks = filter (f: f.mode != "symlink" && f.mode != "direct-symlink") etc';
            in
            {
              build.etcMetadataImage =
                let
                  etcJson = pkgs.writeText "etc-json" (builtins.toJSON etc');
                  etcDump = pkgs.runCommand "etc-dump" { } ''
                    ${getExe pkgs.buildPackages.python3} ${modulesPath}/system/etc/build-composefs-dump.py ${etcJson} > $out
                  '';
                in
                pkgs.runCommand "etc-metadata.erofs"
                  {
                    nativeBuildInputs = with pkgs.buildPackages; [
                      composefs
                      erofs-utils
                    ];
                  }
                  ''
                    mkcomposefs --from-file ${etcDump} $out
                    fsck.erofs $out
                  '';

              build.etcBasedir = pkgs.runCommandLocal "etc-lowerdir" { } ''
                set -euo pipefail

                makeEtcEntry() {
                  src="$1"
                  target="$2"

                  mkdir -p "$out/$(dirname "$target")"
                  cp "$src" "$out/$target"
                }

                mkdir -p "$out"
                ${concatMapStringsSep "\n" (
                  etcEntry:
                  escapeShellArgs [
                    "makeEtcEntry"
                    # force local source paths to be added to the store
                    "${etcEntry.source}"
                    etcEntry.target
                  ]
                ) etcHardlinks}
              '';

              confext = {
                "resolv.conf" = mkDefault {
                  text = ''
                    nameserver 2606:4700:4700::1111
                    nameserver 2001:4860:4860::8888
                    nameserver 1.1.1.1
                    nameserver 8.8.8.8
                  '';
                };
                "nsswitch.conf" = mkDefault {
                  text = ''
                    passwd:    ${concatStringsSep " " nssDatabases.passwd}
                    group:     ${concatStringsSep " " nssDatabases.group}
                    shadow:    ${concatStringsSep " " nssDatabases.shadow}
                    sudoers:   ${concatStringsSep " " nssDatabases.sudoers}

                    hosts:     ${concatStringsSep " " (remove "resolve [!UNAVAIL=return]" nssDatabases.hosts)}
                    networks:  files

                    ethers:    files
                    services:  ${concatStringsSep " " nssDatabases.services}
                    protocols: files
                    rpc:       files
                  '';
                };
                "gai.conf" = mkDefault {
                  text = ''
                    label  ::1/128       0
                    label  ::/0          1
                    label  2002::/16     2
                    label ::/96          3
                    label ::ffff:0:0/96  4
                    precedence  ::1/128       50
                    precedence  ::/0          40
                    precedence  2002::/16     30
                    precedence ::/96          20
                    precedence ::ffff:0:0/96  10
                  '';
                };
              };

              config = {
                serviceConfig = {
                  BindReadOnlyPaths = [ "/run/netns-${name}/confext/etc:/etc:norbind" ];
                };
                after = [ "netns-${name}-confext.service" ];
                requires = [ "netns-${name}-confext.service" ];
              };
            }
          );
        }
      )
    );
  };

  config = {
    system.extraSystemBuilderCmds = ''
      ${concatStringsSep "\n" (
        mapAttrsToList (name: cfg: ''
          mkdir -p $out/netns/${name}
          ln -s ${cfg.build.etcMetadataImage} $out/netns/${name}/etc-metadata-image
          ln -s ${cfg.build.etcBasedir}       $out/netns/${name}/etc-basedir
        '') config.networking.netns-ng
      )}
    '';

    systemd.services = mapAttrs' (
      name: cfg:
      nameValuePair "netns-${name}-confext" {
        inherit (cfg) enable;
        path = with pkgs; [
          coreutils
          util-linux
          move-mount-beneath
        ];
        script = ''
          etcMetadataImage=$(readlink -f /run/current-system/netns/${name}/etc-metadata-image)
          etcBasedir=$(readlink -f /run/current-system/netns/${name}/etc-basedir)

          mkdir -p /run/netns-${name}/confext/etc
          tmpMetadataMount=$(TMPDIR="/run/netns-${name}/confext" mktemp --directory -t nixos-etc-metadata.XXXXXXXXXX)
          mount --type erofs -o ro "$etcMetadataImage" "$tmpMetadataMount"

          if ! mountpoint -q /run/netns-${name}/confext/etc; then
            mount --type overlay overlay \
              --options "lowerdir=$tmpMetadataMount::$etcBasedir,relatime,redirect_dir=on,metacopy=on" \
              /run/netns-${name}/confext/etc
          else
            tmpEtcMount=$(TMPDIR="/run/netns-${name}/confext" mktemp --directory -t nixos-etc.XXXXXXXXXX)
            mount --bind --make-private "$tmpEtcMount" "$tmpEtcMount"
            mount --type overlay overlay \
              --options "lowerdir=$tmpMetadataMount::$etcBasedir,relatime,redirect_dir=on,metacopy=on" \
              "$tmpEtcMount"
            move-mount --move --beneath "$tmpEtcMount" /run/netns-${name}/confext/etc
            umount --lazy --recursive /run/netns-${name}/confext/etc
            umount --lazy "$tmpEtcMount"
            rmdir "$tmpEtcMount"
          fi

          findmnt --type erofs --list --kernel --output TARGET | while read -r mountPoint; do
            if [[ "$mountPoint" =~ ^/run/netns-${name}/confext/nixos-etc-metadata\..{10}$ && "$mountPoint" != "$tmpMetadataMount" ]]; then
              umount --lazy "$mountPoint"
              rmdir "$mountPoint"
            fi
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        after = [ "netns-${name}.service" ];
        partOf = [ "netns-${name}.service" ];
        wantedBy = [
          "netns-${name}.service"
          "multi-user.target"
        ];
        restartTriggers = [ "${self}" ]; # hack
      }
    ) config.networking.netns-ng;
  };
}
