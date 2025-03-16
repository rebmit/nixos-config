{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "monospace";
      size = 12.0;
    };
    settings = {
      background_opacity = "0.95";
      hide_window_decorations = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "yes";
      confirm_os_window_close = "0";
      enable_audio_bell = "no";
      map = "kitty_mod+t no_op";
    };
    extraConfig = ''
      include theme.conf
    '';
  };

  programs.fuzzel.settings.main.terminal = lib.mkDefault "kitty";

  systemd.user.tmpfiles.rules = [
    "L %h/.config/kitty/theme.conf - - - - ${config.theme.light.kittyTheme}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-kitty-${mode}";
          runtimeInputs = with pkgs; [
            procps
          ];
          text = ''
            ln --force --symbolic --verbose "${
              config.theme.${mode}.kittyTheme
            }" "$HOME/.config/kitty/theme.conf"
            pkill -USR1 -u "$USER" kitty || true
          '';
        };
    in
    {
      lightModeScripts.kitty = "${lib.getExe (mkScript "light")}";
      darkModeScripts.kitty = "${lib.getExe (mkScript "dark")}";
    };
}
