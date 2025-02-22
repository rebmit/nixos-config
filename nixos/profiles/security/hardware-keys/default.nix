{ pkgs, ... }:
{
  services.udev.packages = with pkgs; [ canokey-udev-rules ];

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ ccid ];
  };
}
