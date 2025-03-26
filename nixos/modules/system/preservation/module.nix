# Portions of this file are sourced from
# https://github.com/nix-community/preservation/blob/2f16754f9f6b766c1429375ab7417dc81cc90a63/module.nix (MIT License)
{ config, lib, ... }:
let
  inherit (lib.attrsets) mapAttrsToList attrNames;
  inherit (lib.modules) mkIf mkMerge mkForce;
  inherit (lib.lists) flatten;

  inherit (config.passthru.preservation)
    mkRegularMountUnits
    mkInitrdMountUnits
    mkRegularTmpfilesRules
    mkInitrdTmpfilesRules
    mkRegularServiceUnit
    toTmpfilesArguments
    mkUserParentClosureTmpfilesRule
    ;

  cfg = config.preservation;
in
{
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = ''
          This module cannot be used with scripted initrd.
        '';
      }
    ];

    boot.initrd.systemd = {
      targets.initrd-preservation = {
        description = "Initrd Preservation Mounts";
        before = [ "initrd.target" ];
        wantedBy = [ "initrd.target" ];
      };
      tmpfiles.settings.preservation = mkMerge (
        flatten (mapAttrsToList mkInitrdTmpfilesRules cfg.preserveAt)
      );
      mounts = flatten (mapAttrsToList mkInitrdMountUnits cfg.preserveAt);
    };

    systemd = {
      targets.preservation = {
        description = "Preservation Mounts";
        before = [ "sysinit.target" ];
        wantedBy = [ "sysinit.target" ];
      };
      tmpfiles.settings.preservation = mkMerge (
        flatten (
          mapAttrsToList mkRegularTmpfilesRules cfg.preserveAt
          ++ mapAttrsToList (
            _: stateConfig: mapAttrsToList mkUserParentClosureTmpfilesRule stateConfig.users
          ) cfg.preserveAt
        )
      );
      mounts = flatten (mapAttrsToList mkRegularMountUnits cfg.preserveAt);
      services = {
        systemd-tmpfiles-setup.serviceConfig.ExecStart = mkForce [
          ""
          "systemd-tmpfiles --create --remove --boot --exclude-prefix=/dev ${toTmpfilesArguments true (attrNames cfg.preserveAt)}"
        ];
        systemd-tmpfiles-resetup.serviceConfig.ExecStart = mkForce [
          ""
          "systemd-tmpfiles --create --remove --exclude-prefix=/dev ${toTmpfilesArguments true (attrNames cfg.preserveAt)}"
        ];
        systemd-tmpfiles-setup-preservation = mkRegularServiceUnit true (attrNames cfg.preserveAt);
        systemd-tmpfiles-resetup-preservation = mkRegularServiceUnit false (attrNames cfg.preserveAt);
      };
    };
  };
}
