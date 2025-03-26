# Portions of this file are sourced from
# https://github.com/nix-community/preservation/blob/2f16754f9f6b766c1429375ab7417dc81cc90a63/options.nix (MIT License)
{ config, lib, ... }:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
in
let
  mountOption = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          Specify the name of the mount option.
        '';
      };
      value = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Optionally specify a value for the mount option.
        '';
      };
    };
  };

  directoryPath =
    {
      defaultOwner,
      defaultGroup,
      defaultMode,
      ...
    }:
    {
      options = {
        directory = mkOption {
          type = types.str;
          description = ''
            Specify the path to the directory that should be preserved.
          '';
        };
        how = mkOption {
          type = types.enum [
            "bindmount"
            "symlink"
          ];
          default = "bindmount";
          description = ''
            Specify how this directory should be preserved.
          '';
        };
        user = mkOption {
          type = types.str;
          default = defaultOwner;
          description = ''
            Specify the user that owns the directory.
          '';
        };
        group = mkOption {
          type = types.str;
          default = defaultGroup;
          description = ''
            Specify the group that owns the directory.
          '';
        };
        mode = mkOption {
          type = types.str;
          default = defaultMode;
          description = ''
            Specify the access mode of the directory.
            See the section `Mode` in {manpage}`tmpfiles.d(5)` for more information.
          '';
        };
        mountOptions = mkOption {
          type = with types; listOf (coercedTo str (n: { name = n; }) mountOption);
          description = ''
            Specify a list of mount options that should be used for this directory.
            These options are only used when {option}`how` is set to `bindmount`.
            By default, `bind` and `X-fstrim.notrim` are added,
            use `mkForce` to override these if needed.
            See also {manpage}`fstrim(8)`.
          '';
        };
        createLinkTarget = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Only used when {option}`how` is set to `symlink`.

            Specify whether to create an empty directory with the specified ownership
            and permissions as target of the symlink.
          '';
        };
        inInitrd = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to prepare preservation of this directory in initrd.

            ::: {.note}
            For most directories there is no need to enable this option.
            :::

            ::: {.important}
            Note that both owner and group for this directory need to be
            available in the initrd for permissions to be set correctly.
            :::
          '';
        };
      };

      config = {
        mountOptions = [
          "bind"
          "X-fstrim.notrim" # see fstrim(8)
        ];
      };
    };

  filePath =
    {
      defaultOwner,
      defaultGroup,
      defaultMode,
      ...
    }:
    {
      options = {
        file = mkOption {
          type = types.str;
          description = ''
            Specify the path to the file that should be preserved.
          '';
        };
        how = mkOption {
          type = types.enum [
            "bindmount"
            "symlink"
          ];
          default = "bindmount";
          description = ''
            Specify how this file should be preserved:

            1. Either a file is placed both on the volatile and on the
            persistent volume, with a bind mount from the former to the
            latter.

            2. Or a symlink is created on the volatile volume, pointing
            to the corresponding location on the persistent volume.
          '';
        };
        user = mkOption {
          type = types.str;
          default = defaultOwner;
          description = ''
            Specify the user that owns the file.
          '';
        };
        group = mkOption {
          type = types.str;
          default = defaultGroup;
          description = ''
            Specify the group that owns the file.
          '';
        };
        mode = mkOption {
          type = types.str;
          default = defaultMode;
          description = ''
            Specify the access mode of the file.
            See the section `Mode` in {manpage}`tmpfiles.d(5)` for more information.
          '';
        };
        mountOptions = mkOption {
          type = with types; listOf (coercedTo str (o: { name = o; }) mountOption);
          description = ''
            Specify a list of mount options that should be used for this file.
            These options are only used when {option}`how` is set to `bindmount`.
            By default, `bind` is added,
            use `mkForce` to override this if needed.
          '';
        };
        createLinkTarget = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Only used when {option}`how` is set to `symlink`.

            Specify whether to create an empty file with the specified ownership
            and permissions as target of the symlink.
          '';
        };
        inInitrd = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to prepare preservation of this file in the initrd.

            ::: {.note}
            For most files there is no need to enable this option.

            {file}`/etc/machine-id` is an exception because it needs to
            be populated/read very early.
            :::

            ::: {.important}
            Note that both owner and group for this file need to be
            available in the initrd for permissions to be set correctly.
            :::
          '';
        };
      };

      config = {
        mountOptions = [
          "bind"
        ];
      };
    };

  userModule =
    attrs@{ name, ... }:
    {
      options = {
        username = mkOption {
          type = with types; passwdEntry str;
          default = name;
          description = ''
            Specify the user for which the {option}`directories` and {option}`files`
            should be persisted. Defaults to the name of the parent attribute set.
          '';
        };
        home = mkOption {
          type = with types; passwdEntry path;
          default = config.users.users.${name}.home;
          description = ''
            Specify the path to the user's home directory.
          '';
        };
        directories = mkOption {
          type =
            with types;
            listOf (
              coercedTo str (d: { directory = d; }) (submodule [
                {
                  _module.args = rec {
                    defaultOwner = attrs.config.username;
                    defaultGroup = config.users.users.${defaultOwner}.group;
                    defaultMode = "0755";
                  };
                  mountOptions = attrs.config.commonMountOptions;
                }
                directoryPath
              ])
            );
          default = [ ];
          apply = map (d: d // { directory = "${attrs.config.home}/${d.directory}"; });
          description = ''
            Specify a list of directories that should be preserved for this user.
            The paths are interpreted relative to {option}`home`.
          '';
        };
        files = mkOption {
          type =
            with types;
            listOf (
              coercedTo str (f: { file = f; }) (submodule [
                {
                  _module.args = rec {
                    defaultOwner = attrs.config.username;
                    defaultGroup = config.users.users.${defaultOwner}.group;
                    defaultMode = "0644";
                  };
                  mountOptions = attrs.config.commonMountOptions;
                }
                filePath
              ])
            );
          default = [ ];
          apply = map (f: f // { file = "${attrs.config.home}/${f.file}"; });
          description = ''
            Specify a list of files that should be preserved for this user.
            The paths are interpreted relative to {option}`home`.
          '';
        };
        commonMountOptions = mkOption {
          type = with types; listOf (coercedTo str (n: { name = n; }) mountOption);
          default = [ ];
          description = ''
            Specify a list of mount options that should be added to all files and directories
            of this user, for which {option}`how` is set to `bindmount`.

            See also the top level {option}`commonMountOptions` and the invdividual
            {option}`mountOptions` that is available per file / directory.
          '';
        };
      };
    };

  preserveAtSubmodule =
    attrs@{ name, ... }:
    {
      options = {
        persistentStoragePath = mkOption {
          type = types.path;
          default = name;
          description = ''
            Specify the location at which the {option}`directories`, {option}`files`,
            {option}`users.directories` and {option}`users.files` should be preserved.
            Defaults to the name of the parent attribute set.
          '';
        };
        directories = mkOption {
          type =
            with types;
            listOf (
              coercedTo str (d: { directory = d; }) (submodule [
                {
                  _module.args = {
                    defaultOwner = "-";
                    defaultGroup = "-";
                    defaultMode = "-";
                  };
                  mountOptions = attrs.config.commonMountOptions;
                }
                directoryPath
              ])
            );
          default = [ ];
          description = ''
            Specify a list of directories that should be preserved.
            The paths are interpreted as absolute paths.
          '';
        };
        files = mkOption {
          type =
            with types;
            listOf (
              coercedTo str (f: { file = f; }) (submodule [
                {
                  _module.args = {
                    defaultOwner = "-";
                    defaultGroup = "-";
                    defaultMode = "-";
                  };
                  mountOptions = attrs.config.commonMountOptions;
                }
                filePath
              ])
            );
          default = [ ];
          description = ''
            Specify a list of files that should be preserved.
            The paths are interpreted as absolute paths.
          '';
        };
        users = mkOption {
          type =
            with types;
            attrsWith {
              placeholder = "user";
              elemType = submodule [
                { commonMountOptions = attrs.config.commonMountOptions; }
                userModule
              ];
            };
          default = { };
          description = ''
            Specify a set of users with corresponding files and directories that
            should be preserved.
          '';
        };
        commonMountOptions = mkOption {
          type = with types; listOf (coercedTo str (n: { name = n; }) mountOption);
          default = [ ];
          description = ''
            Specify a list of mount options that should be added to all files and directories
            under this preservation prefix, for which {option}`how` is set to `bindmount`.

            See also {option}`commonMountOptions` under {option}`users` and the invdividual
            {option}`mountOptions` that is available per file / directory.
          '';
        };
      };
    };
in
{
  options.preservation = {
    enable = mkEnableOption "the preservation module";

    preserveAt = mkOption {
      type =
        with types;
        attrsWith {
          placeholder = "path";
          elemType = submodule preserveAtSubmodule;
        };
      default = { };
      description = ''
        Specify a set of locations and the corresponding state that
        should be preserved there.
      '';
    };
  };
}
