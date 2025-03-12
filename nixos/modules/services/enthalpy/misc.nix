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
      localsid = 500;
    };

    routingPolicyPriorities = {
      localsid = 500;
    };
  };
}
