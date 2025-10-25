{
  profiles,
  flake,
  inputs,
  ...
}:
{
  imports = with profiles; [
    # keep-sorted start
    flake.flake.modules.nixos."users/root"
    inputs.rebmit.modules.nixos.immutable
    programs.common
    security.polkit
    security.sudo
    services.btrfs-auto-scrub
    services.dbus
    services.journald
    services.logrotate
    services.nscd
    services.openssh
    services.zram-generator
    system.boot.kernel.latest
    system.common
    system.nix.gc
    system.nix.registry
    system.nix.settings
    system.nix.version
    system.preservation
    # keep-sorted end
  ];
}
