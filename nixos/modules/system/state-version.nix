# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/modules/system/state-version.nix
{
  config,
  options,
  lib,
  ...
}:
with lib;
let
  cfg = config.system;
in
{
  options = {
    system.targetStateVersion = mkOption {
      inherit (options.system.stateVersion) type;
      default = config.system.stateVersion;
      description = ''
        System is going to be upgraded to the targetStateVersion.
      '';
    };
    system.pendingStateVersionUpgrade = mkOption {
      type = types.bool;
      default = cfg.stateVersion != cfg.targetStateVersion;
      readOnly = true;
    };
  };

  config = {
    specialisation = mkIf cfg.pendingStateVersionUpgrade {
      target-state-version = {
        configuration = {
          system.stateVersion = mkForce targetStateVersion;
        };
      };
    };

    warnings = mkIf cfg.pendingStateVersionUpgrade [
      ''

        host: ${config.networking.hostName}
        pending stateVersion upgrade from ${cfg.stateVersion} to ${cfg.targetStateVersion}
        release notes: https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-${cfg.targetStateVersion}

      ''
    ];
  };
}
