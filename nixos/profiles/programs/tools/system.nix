{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # keep-sorted start
    dmidecode
    hdparm
    lm_sensors
    pciutils
    smartmontools
    usbutils
    # keep-sorted end
  ];
}
