{
  profiles,
  config,
  lib,
  ...
}:
let
  inherit (lib.lists) singleton;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "eth0" ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::2";
    };
  };

  systemd.services.nix-daemon = config.networking.netns.enthalpy.config;
  systemd.services."user@${toString config.users.users.rebmit.uid}" =
    config.networking.netns.enthalpy.config
    // {
      overrideStrategy = "asDropin";
      restartIfChanged = false;
    };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
