{
  profiles,
  lib,
  data,
  ...
}:
{
  imports = [
    profiles.services.enthalpy.common
  ];

  services.enthalpy.exit = {
    enable = true;
    prefix = lib.singleton {
      type = "bird";
      destination = "::/0";
      source = data.enthalpy_network_prefix;
    };
  };
}
