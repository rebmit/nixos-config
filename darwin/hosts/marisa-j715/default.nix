{
  inputs,
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
    utm
    zotero
  ];

  launchd.user.agents.ssh-agent = {
    command = "${pkgs.openssh}/bin/ssh-agent -D -a $HOME/.run/ssh-agent";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  environment.variables.SSH_AUTH_SOCK = "$HOME/.run/ssh-agent";

  nixpkgs.overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];

  home-manager.users.rebmit =
    {
      suites,
      profiles,
      ...
    }:
    {
      imports = [
        suites.workstation
        profiles.kitty
      ];

      programs.git = {
        userName = "Lu Wang";
        userEmail = "rebmit@rebmit.moe";
        signing.key = lib.mkForce "~/.ssh/id_ed25519_sk_rk.pub";
      };

      programs.kitty.font.size = lib.mkForce 16.0;

      programs.helix.settings.theme = lib.mkForce "catppuccin_mocha";

      services.ssh-agent.enable = lib.mkForce false;

      xdg.configFile."kitty/theme.conf".source =
        lib.mkForce "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Mocha.conf";

      disabledModules = [ profiles.preservation ];

      systemd.user.tmpfiles.rules = lib.mkForce [ ];

      home.packages = with pkgs; [
        cinny-desktop
        librewolf
      ];
    };

  users.users.rebmit = {
    uid = 501;
    home = "/Users/rebmit";
    shell = pkgs.fish;
  };

  users.knownUsers = [ "rebmit" ];

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [
      "root"
      "@admin"
    ];
  };

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
