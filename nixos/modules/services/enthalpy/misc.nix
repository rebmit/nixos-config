{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;

  cfg = config.services.enthalpy;
in
mkIf cfg.enable {
  networking.netns.enthalpy = {
    ports = {
      # local ports
      proxy-init-netns = 3000;
    };

    routingTables = {
      plat = 400;
      warp = 401;
      localsid = 500;
      vrf-local = 600;
      vrf-other = 601;
    };

    routingPolicyPriorities = {
      localsid = 500;
      l3mdev = 1000;
      l3mdev-unreachable = 2000;
    };
  };
}
