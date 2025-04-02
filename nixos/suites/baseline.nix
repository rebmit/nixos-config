{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    programs.tools.common
    security.polkit
    security.sudo
    services.btrfs-auto-scrub
    services.dbus
    services.journald
    services.logrotate
    services.nscd
    services.openssh
    services.zram-generator
    system.boot.etc-overlay
    system.boot.initrd.systemd
    system.boot.kernel.latest
    system.boot.systemd
    system.boot.userborn
    system.common
    system.nix.gc
    system.nix.registry
    system.nix.settings
    system.nix.version
    system.preservation
    users.root
    # keep-sorted end
  ];
}
