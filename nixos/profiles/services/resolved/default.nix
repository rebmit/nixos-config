{ ... }:
{
  services.resolved = {
    enable = true;
    llmnr = "false";
    extraConfig = ''
      MulticastDNS=off
    '';
  };
}
