# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
{
  config,
  lib,
  pkgs,
  mylib,
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
    systemd.services.enthalpy-gost = {
      serviceConfig = mylib.misc.serviceHardened // {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${pkgs.gost}/bin/gost -L=socks5://[::1]:${toString config.networking.ports.enthalpy-gost}";
      };
      after = [ "netns-${cfg.netns}.service" ];
      partOf = [ "netns-${cfg.netns}.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-${cfg.netns}.service"
      ];
    };

    networking.netns."${cfg.netns}".forwardPorts = singleton {
      protocol = "tcp";
      netns = "default";
      source = "[::1]:${toString config.networking.ports.enthalpy-gost}";
      target = "[::1]:${toString config.networking.ports.socks}";
    };
  };
}
