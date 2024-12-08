{ profiles, ... }:
{
  imports = [
    profiles.services.enthalpy.transit
  ];

  services.enthalpy = {
    srv6.enable = true;
    nat64.enable = true;
  };
}
