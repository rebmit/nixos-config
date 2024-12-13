{ ... }:
{
  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults lecture="never"
    '';
  };
}
