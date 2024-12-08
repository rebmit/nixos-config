{ config, ... }:
{
  services.enthalpy.gost.enable = true;

  systemd.services.nix-daemon = {
    inherit (config.networking.netns.enthalpy) serviceConfig;
    after = [ "netns-enthalpy.service" ];
    requires = [ "netns-enthalpy.service" ];
  };

  systemd.services."user@${toString config.users.users.rebmit.uid}" = {
    inherit (config.networking.netns.enthalpy) serviceConfig;
    overrideStrategy = "asDropin";
    after = [ "netns-enthalpy.service" ];
    requires = [ "netns-enthalpy.service" ];
  };
}
