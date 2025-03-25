# Portions of this file are sourced from
# https://github.com/NixOS/nixpkgs/blob/e9b255a8c4b9df882fdbcddb45ec59866a4a8e7c/nixos/modules/system/etc/etc.nix (MIT License)
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
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.attrsets)
    attrValues
    recursiveUpdate
    mapAttrsToList
    mapAttrs'
    nameValuePair
    ;
  inherit (lib.strings)
    concatStringsSep
    concatMapStringsSep
    escapeShellArgs
    optionalString
    ;
  inherit (lib.lists) remove filter;
  inherit (lib.meta) getExe;

  inherit (config.system) nssDatabases;
  etc = config.environment.etc;

  bindMountOptions =
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "the bind mount" // {
          default = true;
        };
        mountPoint = mkOption {
          type = types.str;
          description = ''
            The mount point in the auxiliary mount namespace.
          '';
        };
        sourcePath = mkOption {
          type = types.str;
          description = ''
            The source path in the default mount namespace.
          '';
        };
        isReadOnly = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether the mounted path should be accessed in read-only mode.
          '';
        };
      };

      config = {
        mountPoint = mkDefault name;
        sourcePath = mkDefault name;
      };
    };
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            runtimeDirectory = mkOption {
              type = types.str;
              default = "/run/netns-${name}";
              readOnly = true;
              description = ''
                Path to the runtime directory for services within the
                network namespace, relative to the host's root directory.
              '';
            };
            rootDirectory = mkOption {
              type = types.str;
              default = "${config.runtimeDirectory}/rootfs";
              readOnly = true;
              description = ''
                Root directory in the auxiliary mount namespace for the
                network namespace, relative to the host's root directory.
              '';
            };
            bindMounts = mkOption {
              type = types.attrsOf (types.submodule bindMountOptions);
              default = { };
              description = ''
                Per-network namespace bind mounts into the new root of the
                auxiliary mount namespace.
              '';
            };
            confext = mkOption {
              inherit (options.environment.etc) type;
              default = { };
              description = ''
                Per-network namespace configuration extensions that will be
                merged on {file}`/etc` in the auxiliary mount namespace.
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

              bindMounts = mkDefault {
                "/bin" = { };
                "/boot" = { };
                "/home" = { };
                "/nix" = { };
                "/persist" = { };
                "/root" = { };
                "/run" = { };
                "/srv" = { };
                "/tmp" = { };
                "/usr" = { };
                "/var" = { };
              };

              config =
                let
                  enabledBindMounts = filter (d: d.enable) (attrValues config.bindMounts);
                  rwBinds = filter (d: d.isReadOnly == false) enabledBindMounts;
                  roBinds = filter (d: d.isReadOnly == true) enabledBindMounts;
                in
                {
                  serviceConfig = {
                    RootDirectory = config.rootDirectory;
                    MountAPIVFS = "yes";
                    TemporaryFileSystem = [ config.runtimeDirectory ];
                    BindPaths = map (d: "${d.sourcePath}:${d.mountPoint}:rbind") rwBinds;
                    BindReadOnlyPaths = map (d: "${d.sourcePath}:${d.mountPoint}:rbind") roBinds;
                  };
                  after = [ "netns-${name}-confext.service" ];
                  wants = [ "netns-${name}-confext.service" ];
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
        mapAttrsToList (
          name: cfg:
          optionalString cfg.enable ''
            mkdir -p $out/netns/${name}
            ln -s ${cfg.build.etcMetadataImage} $out/netns/${name}/etc-metadata-image
            ln -s ${cfg.build.etcBasedir}       $out/netns/${name}/etc-basedir
          ''
        ) config.networking.netns
      )}
    '';

    systemd.services = mapAttrs' (
      name: cfg:
      let
        confextPath = "${cfg.runtimeDirectory}/confext";
        etcPath = "${cfg.rootDirectory}/etc";
      in
      nameValuePair "netns-${name}-confext" (
        mkIf cfg.enable {
          path = with pkgs; [
            coreutils
            util-linux
            move-mount-beneath
          ];
          script = ''
            etcMetadataImage=$(readlink -f /run/current-system/netns/${name}/etc-metadata-image)
            etcBasedir=$(readlink -f /run/current-system/netns/${name}/etc-basedir)

            mkdir -p ${etcPath}
            mkdir -p ${confextPath}
            tmpMetadataMount=$(TMPDIR="${confextPath}" mktemp --directory -t nixos-etc-metadata.XXXXXXXXXX)
            mount --type erofs -o ro "$etcMetadataImage" "$tmpMetadataMount"

            if ! mountpoint -q ${etcPath}; then
              mount --type overlay overlay \
                --options "lowerdir=$tmpMetadataMount::$etcBasedir,relatime,redirect_dir=on,metacopy=on" \
                ${etcPath}
            else
              tmpEtcMount=$(TMPDIR="${confextPath}" mktemp --directory -t nixos-etc.XXXXXXXXXX)
              mount --bind --make-private "$tmpEtcMount" "$tmpEtcMount"
              mount --type overlay overlay \
                --options "lowerdir=$tmpMetadataMount::$etcBasedir,relatime,redirect_dir=on,metacopy=on" \
                "$tmpEtcMount"
              move-mount --move --beneath "$tmpEtcMount" ${etcPath}
              umount --lazy --recursive ${etcPath}
              umount --lazy "$tmpEtcMount"
              rmdir "$tmpEtcMount"
            fi

            findmnt --type erofs --list --kernel --output TARGET | while read -r mountPoint; do
              if [[ "$mountPoint" =~ ^${confextPath}/nixos-etc-metadata\..{10}$ && "$mountPoint" != "$tmpMetadataMount" ]]; then
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
      )
    ) config.networking.netns;
  };
}
