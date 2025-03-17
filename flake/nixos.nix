# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix
{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.rebmit.lib.path) buildModuleList rakeLeaves;
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  nixosModules = buildModuleList ../nixos/modules;
  nixosProfiles = rakeLeaves ../nixos/profiles;
  nixosSuites = buildSuites nixosProfiles (
    profiles: suites: {
      minimal = with profiles; [
        # keep-sorted start
        programs.tools.common
        security.polkit
        security.sudo
        services.dbus
        services.journald
        services.logrotate
        services.nscd
        services.openssh
        system.common
        system.nix.gc
        system.nix.registry
        system.nix.settings
        system.nix.version
        system.perlless
        users.root
        # keep-sorted end
      ];

      baseline =
        suites.minimal
        ++ (with profiles; [
          # keep-sorted start
          services.btrfs-auto-scrub
          services.zram-generator
          system.boot.kernel.latest
          system.boot.systemd-initrd
          system.preservation
          # keep-sorted end
        ]);

      network = with profiles; [
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

      desktop = with profiles; [
        # keep-sorted start
        programs.dconf
        programs.tools.system
        security.rtkit
        services.gnome-keyring
        services.greetd
        services.pipewire
        # keep-sorted end
      ];

      backup = with profiles; [
        services.restic
      ];

      monitoring = with profiles; [
        services.prometheus.node-exporter
      ];

      workstation =
        suites.baseline
        ++ suites.network
        ++ suites.desktop
        ++ suites.backup
        ++ (with profiles; [
          security.hardware-keys
        ]);

      server = suites.baseline ++ suites.network ++ suites.backup ++ suites.monitoring;
    }
  );
in
{
  passthru = {
    inherit nixosModules nixosProfiles nixosSuites;
  };
}
