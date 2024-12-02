# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy.gost = {
    enable = mkEnableOption "simple tunnel for accessing the underlay network";
  };

  config = mkIf (cfg.enable && cfg.gost.enable) {
    systemd.network.networks."50-enthalpy" = {
      address = singleton "fc00::";
      routes = singleton { Destination = cfg.address; };
    };

    systemd.services.enthalpy-gost = {
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${pkgs.gost}/bin/gost -L=socks5://[fc00::]:${toString config.networking.ports.enthalpy-gost}";
        ProtectSystem = "full";
        ProtectHome = "yes";
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        PrivateTmp = true;
        PrivateDevices = true;
        SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
        MemoryDenyWriteExecute = "yes";
      };
      wants = [ "network-online.target" ];
      after = [
        "enthalpy.service"
        "network-online.target"
      ];
      requires = [ "enthalpy.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    services.enthalpy.exit.enable = true;
    services.enthalpy.exit.prefix = singleton {
      type = "static";
      destination = "fc00::/128";
      source = "${cfg.address}/128";
    };

    networking.hosts."fc00::" = singleton "enthalpy-gost";
  };
}
