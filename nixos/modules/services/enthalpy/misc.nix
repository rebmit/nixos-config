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
      exit = 400;
      warp = 401;
      localsid = 500;
    };

    routingPolicyPriorities = {
      localsid = 500;
    };
  };
}
