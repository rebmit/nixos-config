{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkConfig =
    mode:
    let
      inherit (config.theme.${mode}.base24Theme)
        base00
        base02
        base05
        base09
        base0D
        ;
    in
    pkgs.writeText "mako-config-${mode}" ''
      font=sans-serif 11
      background-color=#${base00}
      text-color=#${base05}
      border-color=#${base0D}
      progress-color=over #${base02}
      border-size=3
      border-radius=3

      [urgency=high]
      border-color=#${base09}
    '';
  inherit (pkgs) mako;
in
{
  home.packages = lib.singleton mako;

  systemd.user.tmpfiles.rules = [
    "L %h/.config/mako/config - - - - ${mkConfig "light"}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-mako-${mode}";
          text = ''
            ln --force --symbolic --verbose "${mkConfig mode}" "$HOME/.config/mako/config"
            ${mako}/bin/makoctl reload || true
          '';
        };
    in
    {
      lightModeScripts.mako = "${lib.getExe (mkScript "light")}";
      darkModeScripts.mako = "${lib.getExe (mkScript "dark")}";
    };
}
