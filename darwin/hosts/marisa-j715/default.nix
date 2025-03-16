{
  lib,
  pkgs,
  self,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    coreutils
    htop
    openssh
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports =
        suites.workstation
        ++ (with profiles; [
          kitty
        ]);

      programs.git = {
        userName = "git";
        userEmail = "rebmit@rebmit.moe";
        signing.key = lib.mkForce "~/.ssh/id_ed25519_sk_rk.pub";
      };

      programs.tmux.shell = "${pkgs.fish}/bin/fish";

      programs.kitty.font.size = lib.mkForce 16.0;

      programs.helix.settings.theme = lib.mkForce "catppuccin_mocha";

      xdg.configFile."kitty/theme.conf".source =
        lib.mkForce "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Mocha.conf";

      disabledModules = [ profiles.preservation ];

      systemd.user.tmpfiles.rules = lib.mkForce [ ];
    };

  users.users.rebmit.home = "/Users/rebmit";

  nix.settings.experimental-features = "nix-command flakes";

  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      # swap Caps Lock key and Escape key.
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771113;
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771113;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };
}
