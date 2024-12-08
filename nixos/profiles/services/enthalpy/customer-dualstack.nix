{ profiles, ... }:
{
  imports = [
    profiles.services.enthalpy.customer
  ];

  services.enthalpy.clat.enable = true;
}
