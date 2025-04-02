{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    programs.tools.network
    services.firewall
    services.networkd
    services.resolved
    services.vnstat
    system.boot.sysctl.tcp-bbr
    system.boot.sysctl.udp-buffer-size
    # keep-sorted end
  ];
}
