{ profiles, ... }:
{
  imports = with profiles; [
    virtualization.orbstack-guest
  ];
}
