{
  lib,
  pkgs,
  self,
  ...
}:
{
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Nix Apps/kitty.app"; }
    { app = "/Applications/Firefox Developer Edition.app"; }
    { app = "/Applications/Nix Apps/Thunderbird.app"; }
    { app = "/Applications/Nix Apps/Cinny.app"; }
    { app = "/Applications/Nix Apps/UTM.app"; }
    { app = "/Applications/WeChat.app"; }
  ];

  environment.systemPackages = with pkgs; [
    cinny-desktop
    git
    coreutils
    htop
    openssh
    kitty
    utm
    zotero
    thunderbird
    (writeShellApplication {
      name = "nixos";
      text = ''
        ssh -t rebmit@nixos systemd-run --user --pipe --pty --same-dir --wait -S
      '';
    })
  ];

  launchd.user.agents.ssh-agent = {
    command = "${pkgs.openssh}/bin/ssh-agent -D -a $HOME/.run/ssh-agent";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  environment.variables.SSH_AUTH_SOCK = "$HOME/.run/ssh-agent";

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

      programs.kitty = {
        package = pkgs.emptyDirectory;
        font.size = lib.mkForce 16.0;
        settings.background_opacity = lib.mkForce "1.00";
      };

      programs.helix.settings.theme = lib.mkForce "adwaita-light";

      services.ssh-agent.enable = lib.mkForce false;

      xdg.configFile."kitty/theme.conf".source =
        lib.mkForce "${self}/home-manager/profiles/theme/adwaita/_kitty/adwaita_light.conf";

      disabledModules = [ profiles.preservation ];

      systemd.user.tmpfiles.rules = lib.mkForce [ ];
    };

  users.users.rebmit = {
    uid = 501;
    home = "/Users/rebmit";
    shell = pkgs.fish;
  };

  users.knownUsers = [ "rebmit" ];

  system.primaryUser = "rebmit";

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
