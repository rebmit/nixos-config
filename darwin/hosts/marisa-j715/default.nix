{ pkgs, self, ... }:
{
  environment.systemPackages = with pkgs; [
    helix
    git
    kitty
    coreutils
    htop
    yazi
    openssh
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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
