# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/home.nix (MIT License)
{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "tide";
        inherit (pkgs.fishPlugins.tide) src;
      }
    ];
    shellInit = ''
      set fish_greeting

      function fish_user_key_bindings
        fish_vi_key_bindings
        bind f accept-autosuggestion
      end

      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/icons.fish | source
      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/configs/lean.fish | source
      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/configs/lean_16color.fish | source
      set -g tide_prompt_add_newline_before false

      fish_config theme choose fish\ default
      set fish_color_autosuggestion white
    '';
  };

  preservation.preserveAt."/persist".directories = [ ".local/share/fish" ];
}
