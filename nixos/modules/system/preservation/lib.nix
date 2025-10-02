# Portions of this file are sourced from
# https://github.com/nix-community/preservation/blob/2f16754f9f6b766c1429375ab7417dc81cc90a63/lib.nix (MIT License)
# https://github.com/linyinfeng/dotfiles/blob/e87f7de2a4c11379e874c8d372e985b1836c042a/nixos/modules/environment/global-persistence/default.nix (MIT License)
{ config, lib, ... }:
let
  inherit (lib.attrsets) mapAttrsToList optionalAttrs;
  inherit (lib.strings)
    concatStringsSep
    concatMapStringsSep
    hasSuffix
    hasPrefix
    removePrefix
    removeSuffix
    substring
    splitString
    optionalString
    ;
  inherit (lib.lists)
    foldl'
    length
    sublist
    concatLists
    filter
    optional
    optionals
    unique
    sort
    remove
    ;
  inherit (lib.trivial) lessThan;

  toOptionsString =
    mountOptions:
    concatStringsSep "," (
      map (
        option: if option.value == null then option.name else "${option.name}=${option.value}"
      ) mountOptions
    );

  concatTwoPaths =
    parent: child:
    if hasSuffix "/" parent then
      if hasPrefix "/" child then parent + (removePrefix "/" child) else parent + child
    else if hasPrefix "/" child then
      parent + child
    else
      parent + "/" + child;

  concatPaths = foldl' concatTwoPaths "";

  parentDirectory =
    path:
    assert "/" == (substring 0 1 path);
    let
      parts = splitString "/" (removeSuffix "/" path);
      len = length parts;
    in
    if len < 1 then "/" else concatPaths ([ "/" ] ++ (sublist 0 (len - 1) parts));

  parentNormalize = prefix: paths: sort lessThan (filter (hasPrefix prefix) (unique paths));
  parentDirectories = prefix: paths: parentNormalize prefix (map parentDirectory paths);

  parentClosure =
    prefix: paths:
    let
      iter = parentNormalize prefix (paths ++ parentDirectories prefix paths);
    in
    if iter == paths then iter else parentClosure prefix iter;

  getAllDirectories =
    stateConfig: stateConfig.directories ++ (concatLists (getUserDirectories stateConfig.users));
  getAllFiles = stateConfig: stateConfig.files ++ (concatLists (getUserFiles stateConfig.users));
  getUserDirectories = mapAttrsToList (_: userConfig: userConfig.directories);
  getUserFiles = mapAttrsToList (_: userConfig: userConfig.files);
  onlyBindMounts = forInitrd: filter (conf: conf.how == "bindmount" && conf.inInitrd == forInitrd);
  onlySymLinks = forInitrd: filter (conf: conf.how == "symlink" && conf.inInitrd == forInitrd);

  mkTmpfilesRules =
    forInitrd: _preserveAt: stateConfig:
    let
      allDirectories = getAllDirectories stateConfig;
      allFiles = getAllFiles stateConfig;
      mountedDirectories = onlyBindMounts forInitrd allDirectories;
      mountedFiles = onlyBindMounts forInitrd allFiles;
      symlinkedDirectories = onlySymLinks forInitrd allDirectories;
      symlinkedFiles = onlySymLinks forInitrd allFiles;

      prefix = if forInitrd then "/sysroot" else "/";

      mountedDirRules = map (
        dirConfig:
        let
          persistentDirPath = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            dirConfig.directory
          ];
        in
        {
          "${persistentDirPath}".d = {
            inherit (dirConfig) user group mode;
          };
        }
      ) mountedDirectories;

      mountedFileRules = map (
        fileConfig:
        let
          persistentFilePath = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            fileConfig.file
          ];
        in
        {
          "${persistentFilePath}".f = {
            inherit (fileConfig) user group mode;
          };
        }
      ) mountedFiles;

      symlinkedDirRules = map (
        dirConfig:
        let
          persistentDirPath = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            dirConfig.directory
          ];
          volatileDirPath = concatPaths [
            prefix
            dirConfig.directory
          ];
        in
        {
          "${volatileDirPath}".L = {
            inherit (dirConfig) user group mode;
            argument = concatPaths [
              stateConfig.persistentStoragePath
              dirConfig.directory
            ];
          };
        }
        // optionalAttrs dirConfig.createLinkTarget {
          "${persistentDirPath}".d = {
            inherit (dirConfig) user group mode;
          };
        }
      ) symlinkedDirectories;

      symlinkedFileRules = map (
        fileConfig:
        let
          persistentFilePath = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            fileConfig.file
          ];
          volatileFilePath = concatPaths [
            prefix
            fileConfig.file
          ];
        in
        {
          "${volatileFilePath}".L = {
            inherit (fileConfig) user group mode;
            argument = concatPaths [
              stateConfig.persistentStoragePath
              fileConfig.file
            ];
          };
        }
        // optionalAttrs fileConfig.createLinkTarget {
          "${persistentFilePath}".f = {
            inherit (fileConfig) user group mode;
          };
        }
      ) symlinkedFiles;

      rules = mountedDirRules ++ symlinkedDirRules ++ mountedFileRules ++ symlinkedFileRules;
    in
    rules;

  mkMountUnits =
    forInitrd: _preserveAt: stateConfig:
    let
      allDirectories = getAllDirectories stateConfig;
      allFiles = getAllFiles stateConfig;
      mountedDirectories = onlyBindMounts forInitrd allDirectories;
      mountedFiles = onlyBindMounts forInitrd allFiles;

      prefix = if forInitrd then "/sysroot" else "/";

      directoryMounts = map (directoryConfig: {
        options = toOptionsString (
          directoryConfig.mountOptions
          ++ (optional forInitrd {
            name = "x-initrd.mount";
            value = null;
          })
        );
        where = concatPaths [
          prefix
          directoryConfig.directory
        ];
        what = concatPaths [
          prefix
          stateConfig.persistentStoragePath
          directoryConfig.directory
        ];
        unitConfig.DefaultDependencies = "no";
        conflicts = [ "umount.target" ];
        wantedBy = if forInitrd then [ "initrd-preservation.target" ] else [ "preservation.target" ];
        before =
          if forInitrd then
            [
              "systemd-tmpfiles-setup-sysroot.service"
              "initrd-preservation.target"
            ]
          else
            [
              "systemd-tmpfiles-setup.service"
              "systemd-tmpfiles-resetup.service"
              "preservation.target"
              "sysinit-reactivation.target"
            ];
        after =
          if forInitrd then
            [ ]
          else
            [
              "systemd-tmpfiles-setup-preservation.service"
              "systemd-tmpfiles-resetup-preservation.service"
            ];
      }) mountedDirectories;

      fileMounts = map (fileConfig: {
        options = toOptionsString (
          fileConfig.mountOptions
          ++ (optional forInitrd {
            name = "x-initrd.mount";
            value = null;
          })
        );
        where = concatPaths [
          prefix
          fileConfig.file
        ];
        what = concatPaths [
          prefix
          stateConfig.persistentStoragePath
          fileConfig.file
        ];
        unitConfig = {
          DefaultDependencies = "no";
          ConditionPathExists = concatPaths [
            prefix
            stateConfig.persistentStoragePath
            fileConfig.file
          ];
        };
        conflicts = [ "umount.target" ];
        wantedBy = if forInitrd then [ "initrd-preservation.target" ] else [ "preservation.target" ];
        before =
          if forInitrd then
            [
              "systemd-tmpfiles-setup-sysroot.service"
              "initrd-preservation.target"
            ]
          else
            [
              "systemd-tmpfiles-setup.service"
              "systemd-tmpfiles-resetup.service"
              "preservation.target"
              "sysinit-reactivation.target"
            ];
        after =
          if forInitrd then
            [ ]
          else
            [
              "systemd-tmpfiles-setup-preservation.service"
              "systemd-tmpfiles-resetup-preservation.service"
            ];
      }) mountedFiles;

      mountUnits = directoryMounts ++ fileMounts;
    in
    mountUnits;

  mkRegularMountUnits = mkMountUnits false;
  mkInitrdMountUnits = mkMountUnits true;
  mkRegularTmpfilesRules = mkTmpfilesRules false;
  mkInitrdTmpfilesRules = mkTmpfilesRules true;

  toTmpfilesArguments =
    isExcluded: paths:
    concatMapStringsSep " " (
      path: "${if isExcluded then "--exclude-prefix" else "--prefix"}=${path}"
    ) paths;

  mkRegularServiceUnit = onBoot: paths: {
    wantedBy = optionals onBoot [ "preservation.target" ];
    requiredBy = optionals (!onBoot) [ "sysinit-reactivation.target" ];
    after = [
      "systemd-sysusers.service"
      "systemd-journald.service"
    ];
    before = [
      "shutdown.target"
    ]
    ++ optionals onBoot [
      "sysinit.target"
      "initrd-switch-root.target"
      "systemd-tmpfiles-setup.service"
    ]
    ++ optionals (!onBoot) [
      "sysinit-reactivation.target"
      "systemd-tmpfiles-resetup.service"
    ];
    conflicts = [
      "shutdown.target"
    ]
    ++ optionals onBoot [
      "initrd-switch-root.target"
    ];
    restartTriggers = optionals (!onBoot) [ config.environment.etc."tmpfiles.d".source ];
    unitConfig = {
      DefaultDependencies = false;
      RefuseManualStop = onBoot;
      RequiresMountsFor = paths;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "systemd-tmpfiles --create --remove ${optionalString onBoot "--boot"} --exclude-prefix=/dev ${toTmpfilesArguments false paths}";
      SuccessExitStatus = "DATAERR CANTCREAT";
      ImportCredential = [
        "tmpfiles.*"
        "loging.motd"
        "login.issue"
        "network.hosts"
        "ssh.authorized_keys.root"
      ];
    };
  };

  mkUserParentClosureTmpfilesRule =
    username: userConfig:
    let
      inherit (userConfig) home;
      directories = map (d: d.directory) userConfig.directories;
      files = map (f: f.file) userConfig.files;
      parents = remove home (parentClosure home (parentDirectories home (directories ++ files)));
      rules = map (d: {
        "${d}".d = {
          user = username;
          inherit (config.users.users.${username}) group;
          mode = "0700";
        };
      }) parents;
    in
    rules;
in
{
  passthru.preservation = {
    inherit
      mkRegularMountUnits
      mkInitrdMountUnits
      mkRegularTmpfilesRules
      mkInitrdTmpfilesRules
      mkRegularServiceUnit
      toTmpfilesArguments
      mkUserParentClosureTmpfilesRule
      ;
  };
}
